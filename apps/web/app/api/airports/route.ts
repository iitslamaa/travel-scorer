// apps/web/app/api/airports/route.ts

import { NextResponse } from "next/server";
import {
  AIRPORTS,
  findAirportByIata,
  type Airport,
} from "../../../../../packages/data/src";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const iata = searchParams.get("iata");
  const q = searchParams.get("q");

  let airports: Airport[] = AIRPORTS;

  // If ?iata= is provided, return that exact airport (or empty array)
  if (iata) {
    const airport = findAirportByIata(iata);
    airports = airport ? [airport] : [];
  } else if (q) {
    // If ?q= is provided, do a simple text search
    const query = q.toLowerCase();
    airports = AIRPORTS.filter((a) => {
      return (
        a.iata.toLowerCase().includes(query) ||
        a.name.toLowerCase().includes(query) ||
        a.cityName.toLowerCase().includes(query)
      );
    });
  }

  return NextResponse.json({ airports });
}