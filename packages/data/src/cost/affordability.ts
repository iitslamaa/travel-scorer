// packages/data/src/cost/affordability.ts

export type RawAffordabilityCost = {
  hotelPerNight?: number;   // mid-range hotel, per person (or per room / 2)
  hostelPerNight?: number;  // budget hostel
  foodPerDay?: number;      // 3 meals per day per person
  transportPerDay?: number; // local transport per person per day
};

// ISO2 → travel-ish cost estimates in USD.
// These are placeholder examples – you’ll expand/adjust them.
export const COST_DATA: Record<string, RawAffordabilityCost> = {
  US: {
    hotelPerNight: 150,
    hostelPerNight: 50,
    foodPerDay: 60,
    transportPerDay: 25,
  },
  TH: {
    hotelPerNight: 50,
    hostelPerNight: 15,
    foodPerDay: 20,
    transportPerDay: 8,
  },
  JP: {
    hotelPerNight: 120,
    hostelPerNight: 45,
    foodPerDay: 45,
    transportPerDay: 20,
  },
  MX: {
    hotelPerNight: 70,
    hostelPerNight: 25,
    foodPerDay: 25,
    transportPerDay: 12,
  },
  // add more countries here over time...
};