// packages/data/src/types.ts

/** Travel advisory information for a country. */
export type AdvisoryInfo = {
  level?: string;          // e.g., "Level 2 – Exercise Increased Caution"
  headline?: string;       // short summary if available
  updatedAt?: string;      // ISO date string
  source?: string;         // URL or identifier for provenance
};

/** Numeric category breakdown and related facts. */
export type CountryFacts = {
  scoreTotal?: number;     // overall composite score (0–100)
  redditN?: number;        // Reddit sample size if applicable
  [key: string]: number | undefined;
};

/** Primary normalized country row used across web + mobile. */
export type CountryRow = {
  iso2: string;
  name: string;
  score: number;
  n?: number;
  updatedAt?: string;
  facts?: CountryFacts;    // category data like safety, cost, etc.
  advisory?: AdvisoryInfo; // travel advisory details
  explanation?: string;    // textual explanation (why this score)
};