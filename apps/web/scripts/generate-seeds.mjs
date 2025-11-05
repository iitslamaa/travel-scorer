// scripts/generate-seeds.mjs
import fs from 'node:fs';
import path from 'node:path';
import countries from 'world-countries';

/**
 * Our target schema:
 * {
 *   iso2, iso3, m49, name, officialName?,
 *   region?, subregion?, intermediateRegion?,
 *   aliases?: string[], territory?: boolean,
 *   lat?, lng?, currency?, languages?: string[]
 * }
 */

function cleanAliases(arr) {
  return Array.from(
    new Set(
      (arr || [])
        .map((s) => String(s).trim())
        .filter(Boolean)
    )
  );
}

function mapCountry(c) {
  const iso2 = c.cca2;
  const iso3 = c.cca3;
  const m49 = Number(c.ccn3 || 0) || 0;
  const name = c.name?.common || iso3 || iso2;
  const officialName = c.name?.official || undefined;
  const region = c.region || undefined;
  const subregion = c.subregion || undefined;

  // Heuristic for territories/dependencies
  const territory =
    (c.independent === false) ||
    (c.status && c.status.toLowerCase().includes('territory')) ||
    false;

  const aliases = cleanAliases([
    ...(c.altSpellings || []),
    c.name?.official,
    c.name?.common,
    // common exonyms we want to normalize
    iso2 === 'KR' ? 'South Korea' : undefined,
    iso2 === 'CI' ? 'Ivory Coast' : undefined,
    iso2 === 'BO' ? 'Bolivia' : undefined,
    iso2 === 'IR' ? 'Iran' : undefined,
    iso2 === 'SY' ? 'Syria' : undefined,
    iso2 === 'RU' ? 'Russia' : undefined,
    iso2 === 'TW' ? 'Taiwan' : undefined,
  ]);

  const lat = Array.isArray(c.latlng) ? c.latlng[0] : undefined;
  const lng = Array.isArray(c.latlng) ? c.latlng[1] : undefined;

  const currency =
    c.currencies ? Object.keys(c.currencies)[0] : undefined;

  const languages = c.languages ? Object.keys(c.languages) : undefined;

  return {
    iso2,
    iso3,
    m49,
    name,
    officialName,
    region,
    subregion,
    intermediateRegion: undefined, // world-countries doesn't include UN intermediate region
    aliases,
    territory,
    lat,
    lng,
    currency,
    languages,
  };
}

const mapped = countries
  .map(mapCountry)
  .sort((a, b) => a.name.localeCompare(b.name));

const outDir = path.join(process.cwd(), 'data', 'seeds');
fs.mkdirSync(outDir, { recursive: true });
const outFile = path.join(outDir, 'countries.json');

fs.writeFileSync(outFile, JSON.stringify(mapped, null, 2));
console.log(`Wrote ${mapped.length} records → ${outFile}`);