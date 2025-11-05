// lib/types.ts
export type CountrySeed = {
  // Stable identifiers
  iso2: string;          // ISO 3166-1 alpha-2 (e.g., "JP")
  iso3: string;          // ISO 3166-1 alpha-3 (e.g., "JPN")
  m49: number;           // UN M49 numeric code (e.g., 392)
  name: string;          // English short name
  officialName?: string; // Long/official name

  // Classification
  region?: string;       // UN region
  subregion?: string;    // UN subregion
  intermediateRegion?: string;

  // Matching / display
  aliases?: string[];    // Exonyms/alternate forms ("UK", "South Korea", "Ivory Coast")
  territory?: boolean;   // true for territories/dependencies

  // Optional enrichables (safe defaults for future overlays)
  lat?: number;
  lng?: number;
  currency?: string;
  languages?: string[];  // ISO 639-1 codes
};