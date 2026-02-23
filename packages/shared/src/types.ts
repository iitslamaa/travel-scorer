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

export type VisaEase =
  | 'visa_free'
  | 'eta'
  | 'voa'
  | 'visa_required'
  | 'unknown';

export type CountryFacts = {
  iso2: string;

  // Safety and sentiment
  advisoryLevel?: 1 | 2 | 3 | 4;
  advisoryScore?: number;
  travelSafeOverall?: number;
  soloFemaleIndex?: number;
  redditComposite?: number;
  redditN?: number;

  // Travel logistics
  seasonality?: number;
  visaEase?: number;
  affordability?: number;
  directFlight?: number;
  infrastructure?: number;

  // Meta
  advisoryUrl?: string;
  advisorySummary?: string;
  updatedAt?: string;
};