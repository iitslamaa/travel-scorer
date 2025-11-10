import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { dirname, resolve } from 'path';
import { fileURLToPath } from 'url';

import countriesLib from 'i18n-iso-countries';
import en from 'i18n-iso-countries/langs/en.json' with { type: 'json' };
countriesLib.registerLocale(en);

const __dirname = dirname(fileURLToPath(import.meta.url));
const srcRoot = resolve(__dirname, '..');          // packages/data/src
const rawDir  = resolve(srcRoot, 'raw');

const rawPath = resolve(rawDir, 'reddit_composite.json');
const outPath = resolve(srcRoot, 'countries.json');

// Product-specific naming preferences or fallback entries.
const OVERRIDES = {
  XK: 'Kosovo',
  // CI: 'Côte d’Ivoire',
  // HK: 'Hong Kong SAR',
};

function officialName(iso2) {
  return (
    OVERRIDES[iso2] ||
    countriesLib.getName(iso2, 'en', { select: 'official' }) ||
    countriesLib.getName(iso2, 'en') ||
    iso2
  );
}

/**
 * Normalize input that can be:
 * 1) a map of { "US": { score: number, n?, updatedAt? }, ... }
 * 2) an array of objects [{ iso2, name?, facts?: { scoreTotal?, redditN? }, advisory?: { updatedAt? } }, ...]
 */
function normalize(raw) {
  let items = [];

  if (Array.isArray(raw)) {
    // API-style array
    items = raw.map((row) => {
      const iso2 = (row.iso2 || row.code || '').toString().toUpperCase();
      const facts = row.facts || {};
      const score =
        (typeof facts.scoreTotal === 'number' ? facts.scoreTotal : undefined) ??
        (typeof row.score === 'number' ? row.score : undefined) ??
        0;

      const n =
        (typeof facts.redditN === 'number' ? facts.redditN : undefined) ??
        (typeof row.n === 'number' ? row.n : undefined);

      const updatedAt = row.advisory?.updatedAt || row.updatedAt;

      return {
        iso2,
        name: row.name || officialName(iso2),
        score,
        n,
        updatedAt,
      };
    });
  } else if (raw && typeof raw === 'object') {
    // Map-style object
    items = Object.entries(raw).map(([iso2, v]) => {
      const score =
        (v && typeof v.score === 'number' ? v.score : undefined) ??
        (v?.facts && typeof v.facts.scoreTotal === 'number' ? v.facts.scoreTotal : undefined) ??
        0;

      const n =
        (v?.facts && typeof v.facts.redditN === 'number' ? v.facts.redditN : undefined) ??
        (typeof v?.n === 'number' ? v.n : undefined);

      const updatedAt = v?.advisory?.updatedAt || v?.updatedAt;

      const code = iso2.toUpperCase();
      return {
        iso2: code,
        name: v?.name || officialName(code),
        score,
        n,
        updatedAt,
      };
    });
  } else {
    throw new Error('Unsupported raw input; expected array or object map.');
  }

  // Filter out bad rows
  items = items.filter((x) => x && x.iso2 && typeof x.score === 'number');

  // Sort by highest score first
  items.sort((a, b) => b.score - a.score);

  return items;
}

const rawJson = JSON.parse(readFileSync(rawPath, 'utf8'));
const entries = normalize(rawJson);

// Guard: fail loudly if we ingested a tiny dataset by mistake
if (entries.length < 50) {
  throw new Error(
    `Expected many countries; got ${entries.length}. Did you feed a sample or .next artifact?`
  );
}

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, JSON.stringify(entries, null, 2));
console.log(`Wrote ${entries.length} countries to ${outPath}`);