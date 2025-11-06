

// apps/web/lib/providers/fx.ts
// Live FX via exchangerate.host (free, no key). Base USD -> local currency.
// Docs: https://exchangerate.host/#/#docs

const TTL_MS = 12 * 60 * 60 * 1000; // 12h cache

type Rates = Record<string, number>;

declare global {
  // eslint-disable-next-line no-var
  var __fxRatesCache__: { ts: number; rates: Rates } | undefined;
}

function now() { return Date.now(); }

function normCurrency(code?: string) {
  return (code || '').trim().toUpperCase();
}

async function fetchRatesUSD(): Promise<Rates> {
  // in-memory cache across hot reloads
  const g = globalThis as unknown as { __fxRatesCache__?: { ts: number; rates: Rates } };
  const cached = g.__fxRatesCache__;
  if (cached && (now() - cached.ts) < TTL_MS) return cached.rates;

  const url = 'https://api.exchangerate.host/latest?base=USD';
  const res = await fetch(url, { cache: 'no-store' });
  if (!res.ok) throw new Error(`fx fetch failed ${res.status}`);
  const json = await res.json() as { rates?: Rates };
  const rates = json?.rates ?? {};
  g.__fxRatesCache__ = { ts: now(), rates };
  return rates;
}

/**
 * Get how many local currency units equal 1 USD for a given currency code, e.g. "AUD".
 * Returns undefined if the currency is missing from the rates table.
 */
export async function fxLocalPerUSDByCurrency(currencyCode?: string): Promise<number | undefined> {
  const cc = normCurrency(currencyCode);
  if (!cc) return undefined;
  const rates = await fetchRatesUSD();
  const v = rates[cc];
  return typeof v === 'number' && Number.isFinite(v) ? v : undefined;
}

/**
 * Batch helper by currency code.
 */
export async function fxLocalPerUSDByCurrencyMap(codes: string[]): Promise<Record<string, number>> {
  const out: Record<string, number> = {};
  const unique = Array.from(new Set(codes.map(normCurrency))).filter(Boolean);
  const rates = await fetchRatesUSD();
  for (const c of unique) {
    const v = rates[c];
    if (typeof v === 'number' && Number.isFinite(v)) out[c] = v;
  }
  return out;
}

/**
 * Convenience helpers when you have ISO2 -> currency mapping.
 */
export async function fxLocalPerUSDByIso2(iso2: string, currencyByIso2?: Record<string, string>): Promise<number | undefined> {
  const cc = normCurrency(currencyByIso2?.[iso2.toUpperCase()]);
  if (!cc) return undefined;
  return fxLocalPerUSDByCurrency(cc);
}

export async function fxLocalPerUSDMapByIso2(iso2s: string[], currencyByIso2?: Record<string, string>): Promise<Record<string, number>> {
  const out: Record<string, number> = {};
  const map = currencyByIso2 ?? {};
  const codes = iso2s
    .map((c) => map[c.toUpperCase()])
    .map(normCurrency)
    .filter(Boolean);
  const batch = await fxLocalPerUSDByCurrencyMap(codes);
  // reverse join back to iso2 keys
  for (const iso of iso2s) {
    const cc = normCurrency(map[iso.toUpperCase()]);
    if (cc && batch[cc] != null) out[iso.toUpperCase()] = batch[cc];
  }
  return out;
}