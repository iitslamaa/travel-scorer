// packages/data/src/index.ts
import type { CountryRow } from './types';
import _countries from './countries.json';

export const countries = _countries as CountryRow[];

export function getCountryByIso2(code: string) {
  const k = code.toUpperCase();
  return countries.find((c) => c.iso2 === k);
}

export function searchCountries(q: string) {
  const s = q.trim().toLowerCase();
  if (!s) return countries;
  return countries.filter(
    (c) => c.name.toLowerCase().includes(s) || c.iso2.toLowerCase().includes(s)
  );
}

export type { CountryRow } from './types';