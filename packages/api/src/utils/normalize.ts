import type { Advisory, Seasonality } from "../types/country";

function decodeHtmlEntities(input: string): string {
  if (!input) return input;

  let decoded = input;

  // 1) Decode HTML entities using DOM when available
  if (typeof document !== 'undefined') {
    const txt = document.createElement('textarea');
    txt.innerHTML = decoded;
    decoded = txt.value;
  }

  // 2) Fix common UTF-8 mojibake from RSS / feeds
  const mojibakeMap: Record<string, string> = {
    'â€™': '’',
    'â€œ': '“',
    'â€�': '”',
    'â€“': '–',
    'â€”': '—',
    'â€¦': '…',
    'Ã©': 'é',
    'Ã¨': 'è',
    'Ãª': 'ê',
    'Ã¡': 'á',
    'Ã³': 'ó',
    'Ã±': 'ñ',
    'Ã¼': 'ü',
  };

  for (const [bad, good] of Object.entries(mojibakeMap)) {
    decoded = decoded.split(bad).join(good);
  }

  // 3) Normalize whitespace
  return decoded
    .replace(/\u00a0/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function normalizeAdvisory(input: any): Advisory {
  const raw =
    input?.level ??
    input?.advisory_level ??
    input?.advisoryLevel ??
    input?.levelNumber ??
    null;

  const levelNumber =
    typeof raw === "number"
      ? raw
      : typeof raw === "string"
      ? parseInt(raw, 10) || null
      : null;

  const summary =
    typeof input?.summary === "string"
      ? decodeHtmlEntities(input.summary)
      : null;

  return {
    levelNumber,
    levelText: levelNumber ? `Level ${levelNumber}` : null,
    summary,
  };
}

export function normalizeSeasonality(input: any): Seasonality {
  const monthsFromNames = (names: string[]) => {
    const map: Record<string, number> = {jan:1,feb:2,mar:3,apr:4,may:5,jun:6,jul:7,aug:8,sep:9,oct:10,nov:11,dec:12};
    return names.map(m => map[String(m).slice(0,3).toLowerCase()]).filter(Boolean);
  };

  let best: number[] = [];
  if (Array.isArray(input?.best)) {
    best = input.best.map((m: any) => Number(m)).filter((n: number) => n >= 1 && n <= 12);
  } else if (Array.isArray(input?.months)) {
    const arr = input.months;
    best = typeof arr[0] === "string" ? monthsFromNames(arr)
         : arr.map((m: any) => Number(m)).filter((n: number) => n >= 1 && n <= 12);
  }

  const summary = typeof input?.summary === "string" ? input.summary : null;
  return { bestMonths: [...new Set(best)].sort((a,b)=>a-b), summary };
}