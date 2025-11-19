// apps/web/app/api/countries/types.ts

export type CountryAffordability = {
  category: number;          // 1 (cheapest) - 10 (most expensive)
  score100: number;          // 100 = cheapest, 10 = most expensive
  averageDailyCost: number;  // per person per day

  breakdown: {
    hotelPerNight?: number;
    hostelPerNight?: number;
    foodPerDay?: number;
    transportPerDay?: number;
  };
};

// This is the shape your API returns to the frontend.
// Start minimal; we only need fields that the web/iOS actually use.
export type Country = {
  iso2: string;              // e.g. "US", "TH"
  name: string;              // "United States", etc.

  // ...add whatever else you're already returning in /api/countries
  // advisory?: ...
  // visa?: ...
  // seasonality?: ...

  affordability?: CountryAffordability;
};