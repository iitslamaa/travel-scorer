import { NextResponse } from 'next/server';
import { XMLParser } from 'fast-xml-parser';
import { nameToIso2 } from '@/lib/countryMatch';

// Known State Dept RSS endpoints (try in order)
const FEED_CANDIDATES = [
  'https://travel.state.gov/_res/rss/TAs.xml',
  'https://travel.state.gov/_res/rss/TAsTWs.xml',
  'https://travel.state.gov/_res/rss/TWs.xml',
  'https://travel.state.gov/content/travel/en/traveladvisories/traveladvisories.xml',
];

async function fetchAllWorking(urls: string[]) {
  const results: { url: string; ok: boolean; text: string }[] = [];
  await Promise.all(
    urls.map(async (u) => {
      try {
        const res = await fetch(u, {
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
            Accept: 'application/rss+xml, application/xml;q=0.9, */*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Cache-Control': 'no-cache',
            Pragma: 'no-cache',
            Referer: 'https://travel.state.gov/',
          },
          next: { revalidate },
        });
        const text = await res.text();
        results.push({ url: u, ok: res.ok, text });
      } catch {
        results.push({ url: u, ok: false, text: '' });
      }
    })
  );
  return results;
}

export type Advisory = {
  country: string;
  iso2?: string;
  level: 1 | 2 | 3 | 4;
  updatedAt: string;
  summary: string;
  url: string;
};

function extractCountry(rawTitle: string) {
  // Handles: "Lebanon - Level 4: Do Not Travel", "Afghanistan Travel Advisory", etc.
  let t = (rawTitle || '').trim();
  // Drop trailing "Travel Advisory"
  t = t.replace(/\s*Travel Advisory\s*$/i, '');
  // If there is a dash-based suffix (e.g., ` - Level 3: ...`), keep the left side
  const dashIdx = t.indexOf(' - ');
  if (dashIdx > -1) t = t.slice(0, dashIdx);
  // Drop any trailing colon
  t = t.replace(/:$/, '');
  return t.trim();
}

function parseLevel(title: string, description?: string): 1 | 2 | 3 | 4 {
  // Sometimes the level appears only in the description; search both
  const src = `${title ?? ''} ${description ?? ''}`;
  const m = src.match(/Level\s*(1|2|3|4)/i);
  const n = m ? Number(m[1]) : 1;
  return (n >= 1 && n <= 4 ? (n as 1 | 2 | 3 | 4) : 1);
}

export const revalidate = 21600; // 6 hours

export async function GET() {
  try {
    const fetched = await fetchAllWorking(FEED_CANDIDATES);
    const parser = new XMLParser({ ignoreAttributes: false });

    type RssItem = { title?: string; description?: string; link?: string; pubDate?: string };
    const allItems: RssItem[] = [];

    for (const f of fetched) {
      if (!f.ok) continue;
      const preview = f.text.slice(0, 200);
      if (!/\<rss[\s>]/i.test(f.text) && !/\<channel[\s>]/i.test(f.text)) {
        console.warn('[advisories] non-RSS from', f.url, 'preview:', preview);
        continue;
      }
      try {
        const json = parser.parse(f.text);
        const node = json?.rss?.channel?.item;
        if (!node) continue;
        if (Array.isArray(node)) allItems.push(...(node as RssItem[]));
        else allItems.push(node as RssItem);
      } catch (e) {
        console.warn('[advisories] parse failed for', f.url);
      }
    }

    console.log('[advisories] aggregated items before mapping:', allItems.length);

    const mapped: Advisory[] = allItems.map((it: RssItem) => {
      const title = it.title || '';
      const description = (it.description || '').replace(/<[^>]+>/g, '').trim();
      const link = it.link || '';
      const pubDate = it.pubDate || new Date().toISOString();

      const country = extractCountry(title) || 'Unknown';
      const level = parseLevel(title, description);
      const iso2 = nameToIso2(country) ?? undefined;

      return {
        country,
        level,
        summary: description || title,
        url: link,
        updatedAt: new Date(pubDate).toISOString(),
        ...(iso2 ? { iso2 } : {}),
      } as Advisory;
    });

    // Keep only the latest entry per country
    const latest = new Map<string, Advisory>();
    for (const a of mapped) {
      const prev = latest.get(a.country);
      if (!prev || new Date(a.updatedAt) > new Date(prev.updatedAt)) latest.set(a.country, a);
    }

    const result = [...latest.values()].sort((a, b) => a.country.localeCompare(b.country));
    console.log('[advisories]', result.length, 'items');
    return NextResponse.json(result);
  } catch (e) {
    // Graceful fallback – return an empty list instead of 500
    return NextResponse.json([]);
  }
}