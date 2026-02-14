export type Weights = {
  advisorySafety: number;
  travelSafe: number;
  soloFemale: number;
  redditComposite: number;
  seasonality: number;
  visaEase: number;
  affordability: number;
  directFlight: number;
  infrastructure: number;
};

export type CountryFacts = {
  iso2: string;

  // Safety and sentiment
  advisoryLevel?: 1 | 2 | 3 | 4;
  travelSafeOverall?: number;   // 0–100
  travelSafeUrl?: string;       // TravelSafe Abroad source URL
  soloFemaleIndex?: number;     // 0–100
  redditComposite?: number;     // 0–100
  redditN?: number;             // sample size

  // Travel logistics
  seasonality?: number;         // 0–100 (100 = currently peak season)
  visaEase?: number;            // 0–100
  affordability?: number;       // 0–100 (higher = cheaper)
  directFlight?: number;        // 0–100 (1 = direct flight exists, or score inverse to hours)
  infrastructure?: number;      // 0–100 (higher = better)

  // Meta
  advisoryUrl?: string;
  advisorySummary?: string;
  updatedAt?: string;
};