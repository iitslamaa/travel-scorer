// packages/shared/src/types.ts
export type Weights = {
  safety: number;
  affordability: number;
  english: number;
  seasonality: number;
  visa: number;
  flightTime: number;
  transit: number;
  womenSafety: number;
  soloSafety: number;
};

export type CountryFacts = {
  iso2: string;

  // Inputs that may be present or null-ish
  advisoryLevel?: 1 | 2 | 3 | 4;
  gdpPppPerCapita?: number;         // USD PPP per capita
  englishProficiency?: number;      // 0..100
  bestMonths?: number[];            // e.g., [4,5,9,10]
  visaEaseUS?: 'visa-free' | 'evisa' | 'visa-required' | 'unknown';
  estFlightHrsFromNYC?: number;     // hours
  transit?: 'great-pt' | 'mixed' | 'car-only';
  womenSafety?: number;             // 0..100
  soloSafety?: number;              // 0..100
};