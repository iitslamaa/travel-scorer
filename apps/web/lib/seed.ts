// lib/seed.ts
import seeds from '@/data/seeds/countries.json';
import type { CountrySeed } from './types';

const US_TERRITORIES = new Set(['AS','GU','MP','PR','VI']);

export const COUNTRY_SEEDS: CountrySeed[] = (seeds as CountrySeed[]).map(c => ({
  ...c,
  isUSTerritory: US_TERRITORIES.has(c.iso2.toUpperCase()),
}));

// Lookup maps
export const byIso2 = new Map(COUNTRY_SEEDS.map(c => [c.iso2.toUpperCase(), c]));

// Build a normalized name key map (name + aliases)
const entries: [string, CountrySeed][] = [];
for (const c of COUNTRY_SEEDS) {
  const names = [c.name, ...(c.aliases ?? [])];
  for (const n of names) {
    const key = n.toLowerCase().replace(/[^a-z]/g, '');
    entries.push([key, c]);
  }
}
export const byNameKey = new Map(entries);