import { NextResponse } from 'next/server';
import { COUNTRY_SEEDS, byIso2 } from '@/lib/seed';
import { headers } from 'next/headers';
import type { CountrySeed } from '@/lib/types';
import { loadFacts } from '@/lib/facts';
import type { CountryFacts } from '@/lib/facts';
import { nameToIso2 } from '@/lib/countryMatch';

import { gdpPerCapitaUSDMap } from '@/lib/providers/worldbank';
import { fxLocalPerUSDMapByIso2 } from '@/lib/providers/fx';
import { fmGroupByCountry, fmByIso2 } from '@/lib/providers/frequentmiler';
import { buildVisaIndex } from '@/lib/providers/visa';

// Local type to avoid any
type FactsExtraServer = Partial<CountryFacts> & {
  advisoryLevel?: 1 | 2 | 3 | 4;
  travelSafeOverall?: number;
  soloFemaleIndex?: number;
  redditComposite?: number;
  seasonality?: number;
  visaEase?: number;
  visaType?: 'visa_free' | 'voa' | 'evisa' | 'visa_required' | 'ban';
  visaAllowedDays?: number;
  visaFeeUsd?: number;
  visaNotes?: string;
  visaSource?: string;
  directFlight?: number;
  infrastructure?: number;
  // affordability inputs
  costOfLivingIndex?: number;
  foodCostIndex?: number;
  gdpPerCapitaUsd?: number;
  fxLocalPerUSD?: number;
  localPerUSD?: number;
  usdToLocalRate?: number;
  affordability?: number;
  // server-computed total
  scoreTotal?: number;
  // FM (Frequent Miler) seasonality enrichments
  fmSeasonalityBestMonths?: number[];            // 1..12
  fmSeasonalityAreas?: { area?: string; months: number[] }[];
  fmSeasonalityHasDualPeak?: boolean;
  fmSeasonalityTodayScore?: number;              // 0..100
  fmSeasonalityTodayLabel?: 'best' | 'good' | 'shoulder' | 'poor';
  fmSeasonalitySource?: string;
};

// --- unified scoring helpers (server-side source of truth) ---
const W_WEIGHTS = {
  travelGov: 0.30,
  travelSafe: 0.15,
  sfti: 0.10,
  reddit: 0.20,
  seasonality: 0.05,
  visa: 0.05,
  affordability: 0.05,
  directFlight: 0.05,
  infrastructure: 0.05,
} as const;

// --- Frequent Miler helpers -------------------------------------------------
function clusterConsecutiveMonths(months: number[]): number[][] {
  if (!months.length) return [];
  const sorted = [...new Set(months.filter(m => m>=1 && m<=12))].sort((a,b)=>a-b);
  const groups: number[][] = [];
  let group: number[] = [sorted[0]];
  for (let i=1;i<sorted.length;i++) {
    if (sorted[i] === sorted[i-1] + 1) group.push(sorted[i]);
    else { groups.push(group); group = [sorted[i]]; }
  }
  groups.push(group);
  // merge wrap (Dec->Jan)
  const first = groups[0], last = groups[groups.length-1];
  if (first && last && first[0] === 1 && last[last.length-1] === 12) {
    groups[0] = [...last, ...first];
    groups.pop();
  }
  return groups;
}
function fmTodayLabel(score?: number): 'best'|'good'|'shoulder'|'poor' {
  if (score == null) return 'shoulder';
  if (score >= 80) return 'best';
  if (score >= 70) return 'good';
  if (score >= 40) return 'shoulder';
  return 'poor';
}

function clamp01(x: number) { return Math.max(0, Math.min(1, x)); }
function toNum(x: unknown): number | undefined { const n = Number(x); return Number.isFinite(n) ? n : undefined; }
function scale100(value: number, min: number, max: number, invert = false) {
  if (min === max) return 50;
  const t = clamp01((value - min) / (max - min));
  const y = invert ? 1 - t : t;
  return Math.round(y * 100);
}
function advisoryToScore(level?: 1|2|3|4) {
  if (!level) return 50; // neutral when missing
  return ((5 - level) / 4) * 100;
}
function affordabilityFromFacts(f: Partial<CountryFacts>): number | undefined {
  const fx = f as FactsExtraServer;
  const col = toNum(fx.costOfLivingIndex);
  const food = toNum(fx.foodCostIndex);
  const gdp  = toNum(fx.gdpPerCapitaUsd);
  const fxr  = toNum(fx.fxLocalPerUSD ?? fx.localPerUSD ?? fx.usdToLocalRate);
  const parts: number[] = [];
  if (col != null) parts.push(scale100(col, 30, 120, true));
  if (food != null) parts.push(scale100(food, 20, 200, true));
  if (gdp != null) parts.push(scale100(gdp, 2000, 80000, true));
  if (fxr != null)  parts.push(scale100(fxr, 0.2, 400, false));
  if (!parts.length) return 50; // neutral baseline
  return Math.round(parts.reduce((a,b)=>a+b,0) / parts.length);
}
function totalScoreFromFacts(f: Partial<CountryFacts>): number {
  const fx = f as FactsExtraServer;
  const signals: { key: keyof typeof W_WEIGHTS; value?: number }[] = [
    { key: 'travelGov',     value: advisoryToScore(fx.advisoryLevel) },
    { key: 'travelSafe',    value: fx.travelSafeOverall },
    { key: 'sfti',          value: fx.soloFemaleIndex },
    { key: 'reddit',        value: fx.redditComposite },
    { key: 'seasonality',   value: fx.seasonality },
    { key: 'visa',          value: fx.visaEase },
    { key: 'affordability', value: fx.affordability ?? affordabilityFromFacts(fx) },
    { key: 'directFlight',  value: fx.directFlight },
    { key: 'infrastructure',value: fx.infrastructure },
  ];
  const presentSum = signals
    .filter(s => Number.isFinite(s.value as number))
    .reduce((a,s)=>a+(W_WEIGHTS[s.key]||0), 0);
  const total = signals.reduce((acc, s) => {
    const raw = Number.isFinite(s.value as number) ? (s.value as number) : undefined;
    if (raw == null) return acc;
    const baseW = W_WEIGHTS[s.key] || 0;
    const eff = presentSum > 0 ? baseW / presentSum : 0;
    return acc + raw * eff;
  }, 0);
  return Math.round(total);
}

// Best-effort optional JSON imports (files may not exist in all demos)
async function safeJsonImport<T = Record<string, unknown>>(path: string): Promise<T | null> {
  try {
    const mod = await import(path);
    return (mod?.default ?? mod) as T;
  } catch {
    return null;
  }
}

type Advisory = {
  iso2?: string;
  country: string;
  level: 1 | 2 | 3 | 4;
  updatedAt: string;
  url: string;
  summary: string; // required for easier typing downstream
};

type CountryOut = CountrySeed & {
  advisory: null | { level: 1|2|3|4; updatedAt: string; url: string; summary: string };
  facts?: CountryFacts;
};

export const revalidate = 60 * 60 * 6;

export async function GET() {
  // Build absolute base to call our other route reliably in dev/prod
  const h = await headers();
  const proto = h.get('x-forwarded-proto') ?? 'http';
  const host = h.get('host') ?? 'localhost:3000';
  const base = `${proto}://${host}`;

  let advisories: Advisory[] = [];
  try {
    const advRes = await fetch(`${base}/api/advisories`, { cache: 'no-store' });
    const rawUnknown = advRes.ok ? ((await advRes.json()) as unknown) : null;
    const raw = Array.isArray(rawUnknown)
      ? (rawUnknown as Array<Record<string, unknown>>)
      : [];

    advisories = raw.map((r) => {
      const levelNum = Number(r.level ?? 0);
      const level = (levelNum === 1 || levelNum === 2 || levelNum === 3 || levelNum === 4)
        ? levelNum
        : 2; // sensible default

      return {
        iso2: typeof r.iso2 === 'string' ? r.iso2 : undefined,
        country: typeof r.country === 'string' ? r.country : '',
        level: level as 1 | 2 | 3 | 4,
        updatedAt: typeof r.updatedAt === 'string' ? r.updatedAt : '',
        url: typeof r.url === 'string' ? r.url : '',
        summary: typeof r.summary === 'string' ? r.summary : '',
      } satisfies Advisory;
    });
  } catch {
    advisories = [];
  }

  console.log('[countries] fetched advisories:', advisories.length);

  function resolveIso2(a: Advisory): string | null {
    if (a.iso2 && a.iso2.length === 2) return a.iso2.toUpperCase();
    const byName = nameToIso2(a.country);
    return byName ? byName.toUpperCase() : null;
  }

  // Map iso2 -> advisory (resolve iso2 from name when missing)
  const overlay = new Map<string, Advisory>();
  for (const a of advisories) {
    const key = resolveIso2(a);
    if (key) overlay.set(key, a);
  }
  console.log('[countries] overlay size:', overlay.size);

  // Merge overlay onto seeds, keep every seed (full coverage)
  const merged: CountryOut[] = COUNTRY_SEEDS.map((seed) => {
    const adv = overlay.get(seed.iso2.toUpperCase());
    return {
      ...seed,
      advisory: adv
        ? {
            level: adv.level,
            updatedAt: adv.updatedAt,
            url: adv.url,
            summary: adv.summary ?? '',
          }
        : null,
    };
  });

  // Include advisory-only places not in seed (rare if seed is full UN list)
  for (const a of advisories) {
    const key = resolveIso2(a);
    if (key && !byIso2.has(key)) {
      const extra: CountryOut = {
        iso2: key,
        iso3: key, // placeholder until we have full mapping
        m49: 0,
        name: a.country,
        aliases: [],
        region: undefined,
        subregion: undefined,
        territory: true,
        advisory: {
          level: a.level,
          updatedAt: a.updatedAt,
          url: a.url,
          summary: a.summary ?? '',
        },
      } as CountryOut;
      merged.push(extra);
    }
  }

  // Load and attach facts (TravelSafe, SFTI, Reddit, visa, seasonality, flights, infrastructure, affordability)
  try {
    const iso2s = merged.map((r) => r.iso2.toUpperCase());

    const factsByIso2 = await loadFacts(iso2s, advisories);
    const visaIndex = await buildVisaIndex();

    // --- Fetch live macroeconomic indicators ---
    const [liveGdpMap, liveFxMap] = await Promise.all([
      gdpPerCapitaUSDMap(iso2s),
      fxLocalPerUSDMapByIso2(iso2s),
    ]);

    // Optionally enrich facts with macro signals for affordability + themes
    // These files are optional; if missing we proceed without them.
    type IsoMap = Record<string, number | string | string[] | undefined>;

    const [gdpJson, fxJson, colJson, themesJson] = await Promise.all([
      safeJsonImport<Record<string, number>>("@/data/sources/gdp_per_capita.json"),
      safeJsonImport<Record<string, number>>("@/data/sources/fx_local_per_usd.json"),
      safeJsonImport<Record<string, number>>("@/data/sources/cost_of_living.json"),
      safeJsonImport<Record<string, string[]>>("@/data/sources/reddit_themes.json"),
    ]);

    // Normalize keys to ISO2 uppercase where possible
    function toIso2Key(k: string): string { return k?.toUpperCase?.() ?? k; }
    const gdpMap: Record<string, number> = Object.fromEntries(
      Object.entries(gdpJson ?? {}).map(([k,v]) => [toIso2Key(k), Number(v)])
    );
    const fxMap: Record<string, number> = Object.fromEntries(
      Object.entries(fxJson ?? {}).map(([k,v]) => [toIso2Key(k), Number(v)])
    );
    const colMap: Record<string, number> = Object.fromEntries(
      Object.entries(colJson ?? {}).map(([k,v]) => [toIso2Key(k), Number(v)])
    );
    const themesMap: Record<string, string[]> = Object.fromEntries(
      Object.entries(themesJson ?? {}).map(([k,v]) => [toIso2Key(k), Array.isArray(v) ? v : []])
    );

    // Prefetch Frequent Miler table grouped by country to avoid per-row fetch
    const fmGrouped = await fmGroupByCountry();
    const fmIsoMap = fmByIso2(fmGrouped);
    const todayMonth = new Date().getMonth() + 1; // 1..12

    for (const row of merged) {
      const keyUpper = row.iso2.toUpperCase();
      const facts = factsByIso2[keyUpper] ?? factsByIso2[row.iso2] ?? undefined;

      // Merge optional macro signals for affordability and narrative if we have them
      const extra: Partial<CountryFacts & {
        costOfLivingIndex?: number;
        foodCostIndex?: number; // reserved; currently same as COL if specific food index missing
        gdpPerCapitaUsd?: number;
        fxLocalPerUSD?: number;
        redditThemes?: string[];
        affordability?: number; // allow precomputed affordability if you add it later
      }> = {};

      // Prefer live data; fall back to static if missing
      if (liveGdpMap[keyUpper] != null) {
        extra.gdpPerCapitaUsd = liveGdpMap[keyUpper];
      } else if (gdpMap[keyUpper] != null) {
        extra.gdpPerCapitaUsd = Number(gdpMap[keyUpper]);
      }

      if (liveFxMap[keyUpper] != null) {
        extra.fxLocalPerUSD = liveFxMap[keyUpper];
      } else if (fxMap[keyUpper] != null) {
        extra.fxLocalPerUSD = Number(fxMap[keyUpper]);
      }

      if (colMap[keyUpper] != null) {
        extra.costOfLivingIndex = Number(colMap[keyUpper]);
        // If you don’t have a separate food index, mirror COL for a mild influence
        extra.foodCostIndex = Number(colMap[keyUpper]);
      }
      if (themesMap[keyUpper]?.length) extra.redditThemes = themesMap[keyUpper];

      row.facts = facts ? { ...facts, ...extra } as CountryFacts : (extra as CountryFacts);

      // --- Attach Visa (US passport) ease & details
      try {
        const visa = visaIndex.get(keyUpper);
        if (visa) {
          const fxs = row.facts as unknown as FactsExtraServer;
          fxs.visaEase = visa.visaEase;
          fxs.visaType = visa.visaType;
          fxs.visaAllowedDays = visa.allowedDays;
          fxs.visaFeeUsd = visa.feeUsd;
          fxs.visaNotes = visa.notes;
          fxs.visaSource = visa.sourceUrl;
        }
      } catch {}

      // --- Attach Frequent Miler seasonality (best months & today verdict)
      try {
        const fmAreas = fmIsoMap.get(keyUpper) || [];
        if (fmAreas.length) {
          const allMonths = Array.from(new Set(fmAreas.flatMap(a => a.months))).sort((a,b)=>a-b);
          const groups = clusterConsecutiveMonths(allMonths);
          const dualPeak = groups.length >= 2;
          const todayIsBest = allMonths.includes(todayMonth);
          // simple score: best=100, adjacent=70, else 40
          const adjacent = allMonths.includes(((todayMonth+10)%12)+1) || allMonths.includes((todayMonth%12)+1);
          const todayScore = todayIsBest ? 100 : (adjacent ? 70 : 40);

          const fxFacts = row.facts as unknown as FactsExtraServer;
          fxFacts.fmSeasonalityBestMonths = allMonths;
          fxFacts.fmSeasonalityAreas = fmAreas;
          fxFacts.fmSeasonalityHasDualPeak = dualPeak;
          fxFacts.fmSeasonalityTodayScore = todayScore;
          fxFacts.fmSeasonalityTodayLabel = fmTodayLabel(todayScore);
          fxFacts.fmSeasonalitySource = 'https://frequentmiler.com/the-best-time-of-year-to-go-to-every-country-in-the-world-in-one-table/';
        }
      } catch {}

      // compute and store canonical total on the server so all clients agree
      try {
        const total = totalScoreFromFacts(row.facts as Partial<CountryFacts>);
        (row.facts as unknown as FactsExtraServer).scoreTotal = total;
      } catch {}
    }
    console.log('[countries] attached live GDP+FX data');
  } catch (e) {
    console.warn('[countries] failed to attach facts:', e);
  }

  // Sort alphabetically by name
  merged.sort((x, y) => x.name.localeCompare(y.name));

  return NextResponse.json(merged);
}