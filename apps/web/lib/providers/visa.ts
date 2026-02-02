import { nameToIso2 } from '@/lib/countryMatch';
const WP_URL = 'https://en.wikipedia.org/wiki/Visa_requirements_for_United_States_citizens';
// --- Types & helpers for visa parsing --------------------------------------
export type VisaType = 'visa_free' | 'voa' | 'evisa' | 'visa_required' | 'ban';

export interface VisaRow {
  visaType: VisaType;
  allowedDays?: number;
  feeUsd?: number;
  notes?: string;
  sourceUrl: string;
  visaEase: number; // 0..100
}

// Parse durations like "90 days", "3 months", "1 year", "2 weeks" into days
function parseDays(text?: string | null): number | undefined {
  const s = (text || '').toLowerCase();
  if (!s) return undefined;

  // days
  let m = s.match(/(\d{1,4})\s*day/);
  if (m) return Number(m[1]);

  // weeks
  m = s.match(/(\d{1,3})\s*week/);
  if (m) return Number(m[1]) * 7;

  // months (approx)
  m = s.match(/(\d{1,2})\s*month/);
  if (m) return Number(m[1]) * 30;

  // years
  m = s.match(/(\d{1,2})\s*year/);
  if (m) return Number(m[1]) * 365;

  return undefined;
}

// Score mapping for visa ease (0..100) with simple fee-aware adjustments
function scoreFor(visaType: VisaType, feeUsd?: number): number {
  let score = 0;
  switch (visaType) {
    case 'visa_free':
      score = 100;
      break;
    case 'voa':
      // Visa on arrival
      score = feeUsd && feeUsd > 0 ? 75 : 90;
      break;
    case 'evisa':
      // Electronic visa / ETA
      score = feeUsd && feeUsd > 0 ? 35 : 50;
      break;
    case 'visa_required':
      score = 30;
      break;
    case 'ban':
    default:
      score = 0;
      break;
  }
  // Clamp and round just in case
  if (!Number.isFinite(score)) score = 0;
  if (score < 0) score = 0;
  if (score > 100) score = 100;
  return Math.round(score);
}

/**
 * Parse the Wikipedia page table into a Map<ISO2, VisaRow>.
 * Target the US-citizen visa requirements wikitable and map columns accurately:
 * [0] Country | [1] Requirement | [2] Allowed stay | [3] Notes
 */
async function fetchVisaFromWikipedia(): Promise<Map<string, VisaRow>> {
  const res = await fetch(WP_URL, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error(`Visa WP fetch failed: ${res.status}`);
  const html = await res.text();

  // Select the main wikitable that contains Country + Requirement columns
  const tableMatches = [...html.matchAll(/<table[^>]*class="[^"]*wikitable[^"]*"[^>]*>([\s\S]*?)<\/table>/gi)];
  let tableHtml = '';
  for (const t of tableMatches) {
    const inner = t[1];
    const hasCountry = /<th[^>]*>\s*(Country|Territory)/i.test(inner) || /<th[^>]*>\s*Country\/?Territory/i.test(inner);
    const hasReq = /<th[^>]*>\s*(Visa requirement|Visa)/i.test(inner) || /Visa (not required|on arrival)|e-?visa|electronic travel authorization|ETA/i.test(inner);
    if (hasCountry && hasReq) { tableHtml = inner; break; }
  }

  const byIso2 = new Map<string, VisaRow>();
  if (!tableHtml) return byIso2; // structure changed – fail safe

  const rowMatches = [...tableHtml.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi)];

  const clean = (s: string) => (s || '')
    .replace(/<sup[\s\S]*?<\/sup>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  for (const m of rowMatches) {
    const rowHtml = m[1];

    // Skip pure header rows
    const isHeaderRow = /<th[\s\S]*<\/th>/i.test(rowHtml) && !/<td/i.test(rowHtml);
    if (isHeaderRow) continue;

    const thName = rowHtml.match(/<th[^>]*>([\s\S]*?)<\/th>/i)?.[1] ?? '';
    const tdCells = [...rowHtml.matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map(x => x[1]);

    // Expect at least 3 data cells when <th> is present; else 4 when the name is in the first <td>
    if (!thName && tdCells.length < 3) continue;

    const nameCell = thName || tdCells[0] || '';
    const name = clean(nameCell);
    if (!name) continue;

    const iso2 = nameToIso2(name)?.toUpperCase();
    if (!iso2) continue;

    // Column mapping depends on whether name is in <th> (typical) or first <td>
    const requirement = clean(tdCells[thName ? 0 : 1] || '').toLowerCase();
    const stayText   = clean(tdCells[thName ? 1 : 2] || '');
    const notes      = clean(tdCells[thName ? 2 : 3] || '');

    let visaType: VisaType = 'visa_required';
    if (/visa[- ]?free|not required/i.test(requirement)) visaType = 'visa_free';
    else if (/visa on arrival|\bvoa\b/i.test(requirement)) visaType = 'voa';
    else if (/(^|\b)e-?visa\b|electronic travel authorization|\beta\b/i.test(requirement)) visaType = 'evisa';
    else if (/not allowed|prohibit|ban/i.test(requirement)) visaType = 'ban';

    const allowedDays = parseDays(stayText) ?? parseDays(requirement);

    // Crude fee parse from notes; refine in future if needed
    const feeMatch = notes.match(/(?:US?\$|\$|€|£)\s?(\d{1,4})/);
    const feeUsd = feeMatch ? parseInt(feeMatch[1], 10) : undefined;

    const visaEase = scoreFor(visaType, feeUsd);

    byIso2.set(iso2, {
      visaType,
      allowedDays,
      feeUsd,
      notes: notes || undefined,
      sourceUrl: WP_URL,
      visaEase,
    });
  }

  // Merge manual overrides if present (typed, no `any`)
  try {
    const mod = await import('@/data/sources/visa_overrides.json');
    const ovUnknown: unknown = (mod as { default?: unknown }).default ?? mod;

    if (ovUnknown && typeof ovUnknown === 'object' && !Array.isArray(ovUnknown)) {
      const ov = ovUnknown as Record<string, Partial<VisaRow>>;
      for (const [k, v] of Object.entries(ov)) {
        const base: VisaRow = byIso2.get(k) ?? {
          visaType: 'visa_required',
          sourceUrl: WP_URL,
          visaEase: 30,
        } as VisaRow;
        const merged: VisaRow = { ...base, ...v } as VisaRow;
        merged.visaEase = v.visaEase ?? scoreFor(merged.visaType, merged.feeUsd);
        byIso2.set(k.toUpperCase(), merged);
      }
    }
  } catch {
    // optional file, ignore if missing
  }

  return byIso2;
}

// Build a ready-to-use index for API routes.
// Having a runtime export ensures this module has value exports (types are erased).
import visaSnapshot from '@/data/snapshots/visa_us_citizens.json';

// Runtime source of truth: static snapshot (no Wikipedia fetches in prod)
export async function buildVisaIndex(): Promise<Map<string, VisaRow>> {
  const map = new Map<string, VisaRow>();

  for (const [iso2, row] of Object.entries(visaSnapshot)) {
    map.set(iso2.toUpperCase(), row as VisaRow);
  }

  return map;
}

// Debug-only export for snapshot scripts (never used at runtime)
export { fetchVisaFromWikipedia };