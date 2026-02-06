import { NextResponse } from 'next/server';
import dns from 'node:dns';
dns.setDefaultResultOrder('ipv4first');

import { XMLParser } from 'fast-xml-parser';
import { COUNTRY_SEEDS } from '@/lib/seed';

// Force Node runtime (so we can use regular Node features if needed)
export const runtime = 'nodejs';
// Ensure this is never prerendered as static
export const dynamic = 'force-dynamic';

export type Advisory = {
  iso2: string;          // ISO-3166-1 alpha-2 country code (uppercased)
  level: 1 | 2 | 3 | 4;  // US State Dept.-style levels
  summary?: string;
  url?: string;
  updated?: string;      // ISO date string if available
};

// Known State Dept RSS endpoints (try in order)
const FEEDS = [
  'https://travel.state.gov/_res/rss/TAs.xml',
  'https://travel.state.gov/_res/rss/TAsTWs.xml',
  'https://travel.state.gov/_res/rss/TWs.xml',
  'https://travel.state.gov/content/travel/en/traveladvisories/traveladvisories.xml',
] as const;

// Build iso3 -> iso2 lookup from seeds
const ISO3_TO_ISO2 = new Map(
  COUNTRY_SEEDS
    .filter(s => s.iso3 && s.iso2)
    .map(s => [String(s.iso3).toUpperCase(), String(s.iso2).toUpperCase()])
);

// Explicit allowlist for territories without destination.<iso3>.html pages
// Keys are URL slugs, values are canonical ISO2 codes
const TERRITORY_SLUG_ALLOWLIST: Record<string, string> = {
  'turks-and-caicos': 'TC',
  'turks-and-caicos-islands': 'TC',
  'turks-and-caicos-islands-travel-advisory': 'TC',
  'turks-caicos': 'TC',
  'cayman-islands': 'KY',
  'bermuda': 'BM',
  'british-virgin-islands': 'VG',
  'u-s-virgin-islands': 'VI',
  'saint-martin': 'MF',
  'sint-maarten': 'SX',
  'curacao': 'CW',
  'aruba': 'AW',
  'anguilla': 'AI',
  'turkey': 'TR',
  'turkiye': 'TR',
  'turkmenistan': 'TM',
};

function normalizeSlugKey(s: string) {
  return s
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '') // strip accents (Türkiye)
    .replace(/[^a-z0-9]+/g, '')                      // collapse punctuation/spaces/dashes
    .trim();
}

// Build exact slug/name/alias -> ISO2 index (NO fuzzy substring matching)
const SLUG_TO_ISO2 = new Map<string, string>();
for (const seed of COUNTRY_SEEDS) {
  const iso2 = String(seed.iso2).toUpperCase();
  const add = (label?: string) => {
    if (!label) return;
    const k = normalizeSlugKey(label);
    if (k && !SLUG_TO_ISO2.has(k)) SLUG_TO_ISO2.set(k, iso2);
  };
  add(seed.name);
  if (Array.isArray(seed.aliases)) {
    for (const a of seed.aliases) add(a);
  }
}

// Weird territory slugs that don't match seed names exactly (keep this SMALL)
const SLUG_OVERRIDES: Record<string, string> = {
  // Turks & Caicos slug variants
  'turksandcaicos': 'TC',
  'turksandcaicosislands': 'TC',

  // Common “The …” country slugs / formal names
  'thegambia': 'GM',
  'gambia': 'GM',
  'thebahamas': 'BS',
  'bahamas': 'BS',

  // Saint Vincent & the Grenadines
  'saintvincentandthegrenadines': 'VC',
  'stvincentandthegrenadines': 'VC',

  // Belize
  'belize': 'BZ',

  // Kyrgyzstan
  'kyrgyzstan': 'KG',
  'kyrgyzrepublic': 'KG',

  // Palestine / Palestinian territories (best-effort ISO2: PS)
  'palestine': 'PS',
  'palestinianterritories': 'PS',

  // US territories (often not present in travel.state.gov advisories)
  'puertorico': 'PR',
  'guam': 'GU',
  'americansamoa': 'AS',
  'northernmarianaislands': 'MP',
  'usvirginislands': 'VI',
};

function iso2FromLink(link: string): string | null {
  if (!link) return null;

  // Case 1: destination.<iso3>.html (canonical)
  const m = link.match(/\/destination\.([a-z]{3})\.html/i);
  if (m?.[1]) {
    const iso3 = m[1].toUpperCase();
    return ISO3_TO_ISO2.get(iso3) ?? null;
  }

  // Case 2: <slug>-travel-advisory.html (country slug pages)
  const s = link.match(/\/([a-z0-9-]+)-travel-advisory\.html/i);
  if (s?.[1]) {
    const rawSlug = s[1];
    const key = normalizeSlugKey(rawSlug);

    // 2a) explicit weird territory overrides
    const o = SLUG_OVERRIDES[key] ?? TERRITORY_SLUG_ALLOWLIST[rawSlug.toLowerCase()];
    if (o && /^[A-Z]{2}$/.test(o)) return o;

    // 2b) exact match against seed names/aliases (e.g., japan, singapore, thailand, turkiye)
    const iso2 = SLUG_TO_ISO2.get(key);
    if (iso2 && /^[A-Z]{2}$/.test(iso2)) return iso2;
  }

  return null;
}

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore JSON import without explicit types
import snapshot from '../../../data/advisories.snapshot.json';

function loadSnapshot(): Advisory[] {
  try {
    if (Array.isArray(snapshot)) {
      // If the snapshot already matches Advisory[]
      return (snapshot as Advisory[]).map(a => ({
        ...a,
        iso2: String(a.iso2 || '').slice(0, 2).toUpperCase(),
      })).filter(a => /^[A-Z]{2}$/.test(a.iso2));
    }
    return [];
  } catch {
    return [];
  }
}

const parser = new XMLParser({ ignoreAttributes: false });

type RssItem = { title?: string; description?: string; link?: string; pubDate?: string };

// Robust fetch with small retry
async function fetchTextWithRetry(url: string, tries = 2): Promise<string | null> {
  let lastErr: unknown = null;
  for (let i = 0; i < tries; i++) {
    const ac = new AbortController();
    const t = setTimeout(() => ac.abort(), 10000);
    try {
      const res = await fetch(url, {
        cache: 'no-store',
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
          Accept: 'application/rss+xml, application/xml;q=0.9, */*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          Pragma: 'no-cache',
          Referer: 'https://travel.state.gov/',
        },
        signal: ac.signal,
      });
      clearTimeout(t);
      if (!res.ok) {
        lastErr = new Error(`HTTP ${res.status} ${res.statusText}`);
        continue;
      }
      const text = await res.text();
      return text;
    } catch (e) {
      lastErr = e;
    }
    await new Promise(r => setTimeout(r, 300));
  }
  console.warn('[advisories] feed fetch failed:', String(lastErr));
  return null;
}

function extractCountry(rawTitle: string) {
  // Examples: "Lebanon - Level 4: Do Not Travel", "Afghanistan Travel Advisory"
  let t = (rawTitle || '').trim();
  t = t.replace(/\s*Travel Advisory\s*$/i, '');
  const dashIdx = t.indexOf(' - ');
  if (dashIdx > -1) t = t.slice(0, dashIdx);
  t = t.replace(/:$/, '');
  return t.trim();
}

function parseLevel(title: string, description?: string): 1 | 2 | 3 | 4 {
  const src = `${title ?? ''} ${description ?? ''}`;
  const m = src.match(/Level\s*(1|2|3|4)/i);
  const n = m ? Number(m[1]) : 1;
  return (n >= 1 && n <= 4 ? (n as 1 | 2 | 3 | 4) : 1);
}

function coerceAdvisories(items: RssItem[]): Advisory[] {
  const mapped = items.map((it) => {
    const title = it.title || '';
    const description = (it.description || '').replace(/<[^>]+>/g, '').trim();
    const link = it.link || '';
    const pubDate = it.pubDate || new Date().toISOString();

    const iso2 = iso2FromLink(link);

    // STRICT: only accept advisories with canonical ISO2 from URL or allowlist
    if (!iso2 || !/^[A-Z]{2}$/.test(iso2)) return null;

    // Guard: only allow advisories for countries we actually have
    if (!COUNTRY_SEEDS.some(s => s.iso2 === iso2)) return null;

    return {
      iso2,
      level: parseLevel(title, description),
      summary: description || title,
      url: link || undefined,
      updated: new Date(pubDate).toISOString(),
    } as Advisory;
  }).filter(Boolean) as Advisory[];

  // Keep only the latest per ISO2
  const latest = new Map<string, Advisory>();
  for (const a of mapped) {
    const prev = latest.get(a.iso2);
    if (!prev || new Date(a.updated || 0) > new Date(prev.updated || 0)) {
      latest.set(a.iso2, a);
    }
  }
  return [...latest.values()].sort((a, b) => a.iso2.localeCompare(b.iso2));
}

export async function GET(req: Request) {
  const url = new URL(req.url);
  const debug = url.searchParams.has('debug');

  try {
    const texts: string[] = [];
    for (const u of FEEDS) {
      const text = await fetchTextWithRetry(u, 2);
      if (text) texts.push(text);
    }

    const items: RssItem[] = [];
    for (const text of texts) {
      // Basic RSS sanity
      if (!/\<rss[\s>]/i.test(text) && !/\<channel[\s>]/i.test(text)) continue;
      try {
        const json = parser.parse(text);
        const node = json?.rss?.channel?.item;
        if (Array.isArray(node)) items.push(...node as RssItem[]);
        else if (node) items.push(node as RssItem);
      } catch {
        // skip bad feed
      }
    }

    const rssOut = coerceAdvisories(items);

    // Always load snapshot and fill missing ISO2s so common countries never go missing
    const snapshotOut = loadSnapshot();
    const byIso = new Map<string, Advisory>();

    for (const a of snapshotOut) byIso.set(a.iso2, a); // snapshot baseline
    for (const a of rssOut) byIso.set(a.iso2, a);      // RSS overrides snapshot

    const out = [...byIso.values()].sort((a, b) => a.iso2.localeCompare(b.iso2));

    if (debug) {
      return NextResponse.json(
        {
          ok: true,
          source: 'rss+snapshot',
          feedsTried: FEEDS.length,
          itemsParsed: items.length,
          rssCount: rssOut.length,
          snapshotCount: snapshotOut.length,
          count: out.length,
          sample: out.slice(0, 8),
        },
        { status: 200, headers: { 'cache-control': 'no-store', 'x-advisories-source': 'rss+snapshot' } }
      );
    }

    return NextResponse.json(out, { status: 200, headers: { 'cache-control': 'no-store', 'x-advisories-source': 'rss+snapshot' } });
  } catch (e) {
    const fb = loadSnapshot();
    if (debug) {
      return NextResponse.json(
        { ok: true, source: 'snapshot-fallback', error: String(e), count: fb.length, sample: fb.slice(0, 5) },
        { status: 200, headers: { 'cache-control': 'no-store', 'x-advisories-source': 'snapshot-fallback' } }
      );
    }
    return NextResponse.json(fb, { status: 200, headers: { 'cache-control': 'no-store', 'x-advisories-source': 'snapshot-fallback' } });
  }
}