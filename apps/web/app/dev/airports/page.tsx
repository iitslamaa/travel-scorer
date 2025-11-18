"use client";

// apps/web/app/dev/airports/page.tsx

import { useState } from "react";
import AirportPicker from "../../../components/airports/AirportPicker";
import type { Airport } from "../../../../../packages/data/src";

export default function AirportDevPage() {
  const [selected, setSelected] = useState<Airport | null>(null);

  return (
    <main className="mx-auto flex min-h-screen max-w-2xl flex-col gap-6 px-4 py-8">
      <div>
        <h1 className="text-2xl font-semibold text-neutral-900">
          Airport Picker Dev
        </h1>
        <p className="mt-1 text-sm text-neutral-600">
          Type a city or IATA code to search your seed airports.
        </p>
      </div>

      <AirportPicker onSelect={setSelected} />

      {selected && (
        <div className="rounded-2xl border border-neutral-200 bg-white p-4 text-sm shadow-sm">
          <h2 className="mb-1 text-sm font-semibold text-neutral-900">
            Selected airport
          </h2>
          <p>
            <span className="font-mono">{selected.iata}</span> —{" "}
            {selected.name}
          </p>
          <p className="text-neutral-600">
            {selected.cityName}, {selected.countryIso2}
          </p>
          <p className="mt-1 text-xs text-neutral-500">
            lat: {selected.lat}, lon: {selected.lon}
          </p>
        </div>
      )}
    </main>
  );
}