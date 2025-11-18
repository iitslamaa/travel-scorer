// packages/data/src/airports.ts
import airportsJson from "../seed/airports.json";

export type IataCode = string; // e.g. "LAX", "JFK", "CDG"

export interface Airport {
  iata: IataCode;
  name: string;        // "Los Angeles International Airport"
  cityName: string;    // "Los Angeles"
  citySlug: string;    // "los-angeles"
  countryIso2: string; // "US"
  lat: number;
  lon: number;
}

export interface CityScoreSummary {
  citySlug: string;        // "los-angeles"
  cityName: string;        // "Los Angeles"
  countryIso2: string;     // "US"
  overallScore: number;    // 0-100
}

export const AIRPORTS: Airport[] = airportsJson as Airport[];

export function findAirportByIata(code: string): Airport | undefined {
  const upper = code.toUpperCase();
  return AIRPORTS.find((a) => a.iata.toUpperCase() === upper);
}