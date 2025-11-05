// lib/countryMatch.ts
import { byNameKey, COUNTRY_SEEDS } from './seed';

// Manual overrides for tricky names
const OVERRIDES: Record<string, string> = {
  // Korea / Côte d’Ivoire
  koreasouth: 'KR',
  republicofkorea: 'KR',
  ivorycoast: 'CI',
  ctedivoire: 'CI',
  coteivoire: 'CI',

  // UK and variants
  uk: 'GB',
  unitedkingdom: 'GB',

  // Bahamas
  thebahamas: 'BS',
  bahamas: 'BS',

  // Myanmar / Burma
  myanmar: 'MM',
  burma: 'MM',

  // Laos / Lao PDR
  laopeoplesdemocraticrepublic: 'LA',
  lao: 'LA',
  laos: 'LA',

  // Vatican / Holy See
  holysee: 'VA',
  vaticancity: 'VA',

  // Curaçao (diacritics often dropped)
  curacao: 'CW',

  // Åland Islands (diacritics often dropped)
  alandislands: 'AX',
};

export function normalizeName(raw: string) {
  return raw.toLowerCase().replace(/[^a-z]/g, '');
}

function soften(raw: string) {
  // remove frequent long prefixes that appear in formal names (e.g., "Islamic Republic of Iran")
  const replacements = [
    'the',
    'republicof',
    'democraticrepublicof',
    'islamicrepublicof',
    'bolivarianrepublicof',
    'kingdomof',
    'stateof',
    'peoplesrepublicof',
    'federationof',
    'plurinationalstateof',
  ];
  let k = normalizeName(raw);
  for (const r of replacements) {
    k = k.replace(new RegExp('^' + r), ''); // drop only if it is leading
  }
  return k;
}

export function nameToIso2(raw: string): string | null {
  const key = normalizeName(raw);
  if (OVERRIDES[key]) return OVERRIDES[key];

  // direct hit on normalized name / aliases
  const hit = byNameKey.get(key);
  if (hit?.iso2) return hit.iso2;

  // try a softened form (drop leading government words)
  const soft = soften(raw);
  if (OVERRIDES[soft]) return OVERRIDES[soft];
  const softHit = byNameKey.get(soft);
  if (softHit?.iso2) return softHit.iso2;

  // last resort: substring match against names & aliases
  for (const c of COUNTRY_SEEDS) {
    const keys = [c.name, ...(c.aliases ?? [])].map(normalizeName);
    if (keys.some(k => k === key || k === soft || key.includes(k) || k.includes(key))) {
      return c.iso2;
    }
  }

  return null;
}