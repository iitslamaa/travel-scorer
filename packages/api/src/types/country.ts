export type Advisory = {
  levelNumber: number | null;
  levelText: string | null;
  summary?: string | null;
};

export type Seasonality = { bestMonths: number[]; summary: string | null };

export type CountryWire = {
  name: string;
  score?: number | null;
  visa?: number | null;
  advisory?: Advisory;
  seasonality?: Seasonality;
};