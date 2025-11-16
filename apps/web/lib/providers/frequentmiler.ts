
// apps/web/lib/providers/frequentmiler.ts
import { COUNTRY_SEEDS } from '@/lib/seed';
import { nameToIso2 } from '@/lib/countryMatch';
import { FM_NAME_OVERRIDES } from './fmOverrides';
// Scrape + normalize Frequent Miler's country-by-month table
// URL: https://frequentmiler.com/the-best-time-of-year-to-go-to-every-country-in-the-world-in-one-table/
// Output: rows with country, area/region (if present), and months (1..12) with a check mark.

export type FMRow = {
  country: string;
  area?: string; // city/region label from the table, if present
  months: number[]; // 1..12 (Jan=1)
  source: 'frequentmiler';
  sourceUrl: string;
};

const SOURCE_URL =
  'https://frequentmiler.com/the-best-time-of-year-to-go-to-every-country-in-the-world-in-one-table/';

// 24h in-memory cache per server instance
const TTL_MS = 24 * 60 * 60 * 1000;

type CacheEntry = { ts: number; rows: FMRow[] };
const g = globalThis as unknown as { __fmCache__?: CacheEntry };

function decodeEntities(s: string) {
  return s
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&ndash;|&#8211;/g, '-')
    .replace(/&mdash;|&#8212;/g, '-')
    .replace(/&middot;|&#183;/g, '·')
    .replace(/<br\s*\/?>/gi, ' ');
}

function stripTags(html: string) {
  return decodeEntities(html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim());
}

const MONTHS = [
  'jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'
];

function monthNameToIndex(name: string): number | undefined {
  const s = name.toLowerCase().slice(0,3);
  const i = MONTHS.indexOf(s);
  return i >= 0 ? i + 1 : undefined; // 1..12
}

function extractTables(html: string): string[] {
  const matches = html.match(/<table[\s\S]*?<\/table>/gi) || [];
  return matches;
}

function extractRows(tableHtml: string): string[] {
  return tableHtml.match(/<tr[\s\S]*?<\/tr>/gi) || [];
}

function extractCells(rowHtml: string): string[] {
  return rowHtml.match(/<t[dh][^>]*>[\s\S]*?<\/t[dh]>/gi) || [];
}

function headerMonthIndices(headerRowHtml: string): number[] {
  const cells = extractCells(headerRowHtml).map(stripTags);
  const idx: number[] = [];
  for (let i = 0; i < cells.length; i++) {
    const m = monthNameToIndex(cells[i]);
    if (m) idx.push(i);
  }
  // Fallback: assume last 12 cells are months if explicit names absent
  if (idx.length === 0 && cells.length >= 13) {
    const start = cells.length - 12;
    return Array.from({ length: 12 }, (_, k) => start + k);
  }
  return idx;
}

function parseFMTable(tableHtml: string): FMRow[] {
  const rows = extractRows(tableHtml);
  if (!rows.length) return [];

  // Find header row that contains months
  let headerIdx = 0;
  let monthCellIdx: number[] = [];
  for (let i = 0; i < rows.length; i++) {
    const idx = headerMonthIndices(rows[i]);
    if (idx.length >= 6) { // reasonably sure it's a month header
      headerIdx = i;
      monthCellIdx = idx;
      break;
    }
  }
  if (monthCellIdx.length === 0) return [];

  const bodyRows = rows.slice(headerIdx + 1);
  const out: FMRow[] = [];

  for (const r of bodyRows) {
    const cells = extractCells(r);
    if (cells.length < monthCellIdx[monthCellIdx.length - 1] + 1) continue;

    const locCell = stripTags(cells[0]);
    if (!locCell) continue;

    // Expect patterns like "Canada - Maritimes" or "Iceland - Reykjavik"
    let country = locCell;
    let area: string | undefined;
    const dash = /\s[-–—]\s/; // space-dash-space variants
    if (dash.test(locCell)) {
      const parts = locCell.split(dash);
      country = parts[0].trim();
      area = parts.slice(1).join(' - ').trim() || undefined;
    }

    const bestMonths: number[] = [];
    for (let k = 0; k < monthCellIdx.length; k++) {
      const td = cells[monthCellIdx[k]];
      const text = stripTags(td);
      // treat ✓, ✔, and "x" (rare) as positive; ignore empty/other marks
      if (/✔|✓/u.test(text) || /\bx\b/i.test(text)) {
        bestMonths.push(k + 1); // align with month order in header
      }
    }

    // If header months aren't Jan..Dec order, remap using header content
    const headerCells = extractCells(rows[headerIdx]).map(stripTags);
    const monthMap: (number | undefined)[] = monthCellIdx.map((ci) => monthNameToIndex(headerCells[ci]));
    const normalized: number[] = [];
    bestMonths.forEach((pos) => {
      const m = monthMap[pos - 1];
      if (m) normalized.push(m);
    });

    // de-dup and sort 1..12
    const months = Array.from(new Set(normalized)).sort((a,b)=>a-b);
    out.push({ country, area, months, source: 'frequentmiler', sourceUrl: SOURCE_URL });
  }

  return out;
}

async function fetchFMHtml(): Promise<string> {
  const res = await fetch(SOURCE_URL, { cache: 'no-store' });
  if (!res.ok) throw new Error(`frequentmiler fetch failed: ${res.status}`);
  return await res.text();
}

/**
 * Fetch + parse Frequent Miler monthly best-months table. Memoized for 24h.
 */
export async function fetchFrequentMilerTable(): Promise<FMRow[]> {
  const cached = g.__fmCache__;
  const now = Date.now();
  if (cached && now - cached.ts < TTL_MS) return cached.rows;

  const html = await fetchFMHtml();
  const tables = extractTables(html);

  // Choose the most likely table: contains 10+ month-name headers
  let winner = '';
  let bestScore = 0;
  for (const t of tables) {
    const head = extractRows(t)[0] || '';
    const score = (extractCells(head).map(stripTags).filter(c => !!monthNameToIndex(c)).length);
    if (score > bestScore) { bestScore = score; winner = t; }
  }
  if (!winner) return [];

  const rows = parseFMTable(winner);
  g.__fmCache__ = { ts: now, rows };
  return rows;
}

/** Group rows by country name (case-insensitive key). */
export async function fmGroupByCountry(): Promise<Record<string, { area?: string; months: number[] }[]>> {
  const rows = await fetchFrequentMilerTable();
  const out: Record<string, { area?: string; months: number[] }[]> = {};
  for (const r of rows) {
    const key = r.country.trim().toUpperCase();
    if (!out[key]) out[key] = [];
    out[key].push({ area: r.area, months: r.months });
  }
  return out;
}

/** Convenience: get all FM entries for a given country name. */
export async function fmForCountryName(name: string): Promise<{ area?: string; months: number[] }[]> {
  const map = await fmGroupByCountry();
  const key = name.trim().toUpperCase();
  return map[key] ?? [];
}
// --- Robust ISO2 mapping for Frequent Miler rows -------------------------
export type FmArea = { country: string; area?: string; months: number[] };

/** Normalize a country name for matching: lowercase, strip punctuation/extra spaces. */
function normName(s: string): string {
  return (s || '')
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '') // accents
    .replace(/[^a-z0-9+'\-& ]+/g, ' ') // keep basic word chars and a few symbols
    .replace(/\s+/g, ' ')
    .trim();
}

/** Build name->ISO2 lookup from COUNTRY_SEEDS and their aliases. */
function buildNameLut(): Map<string, string> {
  const lut = new Map<string, string>();
  for (const seed of COUNTRY_SEEDS) {
    const iso2 = seed.iso2.toUpperCase();
    lut.set(normName(seed.name), iso2);
    for (const a of seed.aliases ?? []) lut.set(normName(a), iso2);
  }
  return lut;
}

/**
 * Convert the grouped-by-country FM map into ISO2-keyed map using multiple strategies:
 * 1) Direct LUT hit from seeds/aliases
 * 2) nameToIso2 heuristic
 */
export function fmByIso2(group: Record<string, { area?: string; months: number[] }[]>): Map<string, { area?: string; months: number[] }[]> {
  const out = new Map<string, { area?: string; months: number[] }[]>();
  const lut = buildNameLut();
  for (const countryName of Object.keys(group)) {
    const rows = group[countryName];
    // 0) Manual override always wins
    const override = FM_NAME_OVERRIDES[normName(countryName)];
    if (override) {
      out.set(override, rows);
      continue;
    }
    let iso2 = lut.get(normName(countryName));
    if (!iso2) {
      const guess = nameToIso2(countryName);
      if (guess) iso2 = guess.toUpperCase();
    }
    if (!iso2) continue; // could not map
    out.set(iso2, rows);
  }
  return out;
}