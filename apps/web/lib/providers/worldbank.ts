// apps/web/lib/providers/worldbank.ts
// Live GDP per capita (current US$) via World Bank API
// Indicator: NY.GDP.PCAP.CD
// Docs: https://datahelpdesk.worldbank.org/knowledgebase/articles/889392-api-documentation


// Type the global cache to silence TS on globalThis property access
declare global {
  // eslint-disable-next-line no-var
  var __wbGdpCache__: Map<string, { value?: number; ts: number }> | undefined;
}

const TTL_MS = 12 * 60 * 60 * 1000; // 12h cache

// Simple in-memory cache (per server instance)
type CacheEntry = { value?: number; ts: number };
type CacheMap = Map<string, CacheEntry>;
const g = globalThis as unknown as { __wbGdpCache__?: CacheMap };
const gdpCache: CacheMap = g.__wbGdpCache__ ?? new Map();
g.__wbGdpCache__ = gdpCache;

function normIso2(iso2: string) {
  return (iso2 || '').trim().toUpperCase();
}

async function fetchJson<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: 'no-store' });
  if (!res.ok) throw new Error(`WB fetch failed ${res.status} for ${url}`);
  return (await res.json()) as T;
}

type WbMeta = { page: number; pages: number; per_page: string; total: number };
// The data array contains points ordered by year desc in most cases
type WbPoint = { country: { id: string; value: string }; date: string; value: number | null };

/**
 * Get latest non-null GDP per capita (current US$) for a single ISO2 country.
 * Returns `undefined` when not available.
 */
export async function gdpPerCapitaUSD(iso2: string): Promise<number | undefined> {
  const key = normIso2(iso2);
  if (!key) return undefined;

  const now = Date.now();
  const cached = gdpCache.get(key);
  if (cached && now - cached.ts < TTL_MS) return cached.value;

  try {
    // pull enough years to find a recent non-null value
    const url = `https://api.worldbank.org/v2/country/${key}/indicator/NY.GDP.PCAP.CD?format=json&per_page=70`;
    const json = await fetchJson<[WbMeta, WbPoint[]]>(url);
    const points = Array.isArray(json?.[1]) ? (json[1] as WbPoint[]) : [];
    // Find the most recent non-null value
    let latest: number | undefined = undefined;
    for (const p of points) {
      if (p.value != null) { latest = Number(p.value); break; }
    }
    gdpCache.set(key, { value: latest, ts: now });
    return latest;
  } catch (e) {
    // cache the miss briefly to avoid hammering
    gdpCache.set(key, { value: undefined, ts: now });
    return undefined;
  }
}

/**
 * Batch helper: returns a map of ISO2 -> latest GDP per capita when available.
 */
export async function gdpPerCapitaMap(iso2s: string[]): Promise<Record<string, number>> {
  const out: Record<string, number> = {};
  const unique = Array.from(new Set(iso2s.map(normIso2))).filter(Boolean);
  const results = await Promise.all(unique.map(async (c) => [c, await gdpPerCapitaUSD(c)] as const));
  for (const [c, v] of results) if (typeof v === 'number' && Number.isFinite(v)) out[c] = v;
  return out;
}

// Back-compat / clearer name used by the route
export async function gdpPerCapitaUSDMap(
  iso2s: string[]
): Promise<Record<string, number>> {
  return gdpPerCapitaMap(iso2s);
}
