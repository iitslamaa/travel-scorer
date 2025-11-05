import { NextResponse } from 'next/server';
import { COUNTRY_SEEDS, byIso2 } from '@/lib/seed';
import { headers } from 'next/headers';
import type { CountrySeed } from '@/lib/types';
import { loadFacts } from '@/lib/facts';
import type { CountryFacts } from '@/lib/facts';
import { nameToIso2 } from '@/lib/countryMatch';

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

    for (const row of merged) {
      const keyUpper = row.iso2.toUpperCase();
      row.facts = factsByIso2[keyUpper] ?? factsByIso2[row.iso2] ?? undefined;
    }
  } catch (e) {
    console.warn('[countries] failed to attach facts:', e);
  }

  // Sort alphabetically by name
  merged.sort((x, y) => x.name.localeCompare(y.name));

  return NextResponse.json(merged);
}