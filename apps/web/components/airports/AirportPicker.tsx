"use client";

// apps/web/components/airports/AirportPicker.tsx

import { useEffect, useState } from "react";
import type { Airport } from "../../../../packages/data/src";

interface AirportPickerProps {
  label?: string;
  placeholder?: string;
  onSelect?: (airport: Airport) => void;
}

interface AirportsResponse {
  airports: Airport[];
}

export default function AirportPicker({
  label = "Departing from",
  placeholder = "Search by city or IATA code (e.g. LAX, Beirut, Paris)...",
  onSelect,
}: AirportPickerProps) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<Airport[]>([]);
  const [isOpen, setIsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [selected, setSelected] = useState<Airport | null>(null);

  // Simple debounce
  useEffect(() => {
    if (!query) {
      setResults([]);
      setIsOpen(false);
      return;
    }

    setIsLoading(true);
    const handle = setTimeout(async () => {
      try {
        const res = await fetch(`/api/airports?q=${encodeURIComponent(query)}`);
        if (!res.ok) {
          throw new Error("Failed to fetch airports");
        }
        const data: AirportsResponse = await res.json();
        setResults(data.airports);
        setIsOpen(true);
      } catch (err) {
        console.error(err);
        setResults([]);
        setIsOpen(false);
      } finally {
        setIsLoading(false);
      }
    }, 300);

    return () => clearTimeout(handle);
  }, [query]);

  function handleSelect(airport: Airport) {
    setSelected(airport);
    setQuery(`${airport.iata} — ${airport.cityName}`);
    setIsOpen(false);
    onSelect?.(airport);
  }

  return (
    <div className="w-full max-w-md">
      {label && (
        <label className="block mb-1 text-sm font-medium text-neutral-800">
          {label}
        </label>
      )}
      <div className="relative">
        <input
          type="text"
          className="w-full rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-neutral-800/60"
          placeholder={placeholder}
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setSelected(null);
          }}
          onFocus={() => {
            if (results.length > 0) setIsOpen(true);
          }}
        />
        {isLoading && (
          <div className="absolute inset-y-0 right-3 flex items-center text-xs text-neutral-400">
            loading...
          </div>
        )}

        {isOpen && results.length > 0 && (
          <ul className="absolute z-20 mt-1 max-h-64 w-full overflow-auto rounded-xl border border-neutral-200 bg-white text-sm shadow-lg">
            {results.map((airport) => (
              <li
                key={airport.iata}
                className="cursor-pointer px-3 py-2 hover:bg-neutral-50"
                onMouseDown={(e) => {
                  // prevent input blur before click
                  e.preventDefault();
                  handleSelect(airport);
                }}
              >
                <div className="flex items-center justify-between">
                  <span className="font-semibold">{airport.iata}</span>
                  <span className="text-xs text-neutral-500">
                    {airport.countryIso2}
                  </span>
                </div>
                <div className="text-xs text-neutral-700">
                  {airport.cityName} · {airport.name}
                </div>
              </li>
            ))}
          </ul>
        )}

        {!isLoading && query && results.length === 0 && (
          <div className="absolute z-10 mt-1 w-full rounded-xl border border-neutral-200 bg-white px-3 py-2 text-xs text-neutral-500 shadow-sm">
            No airports found. Try a different city or code.
          </div>
        )}
      </div>

      {selected && (
        <p className="mt-2 text-xs text-neutral-600">
          Selected: <strong>{selected.iata}</strong> — {selected.cityName},{" "}
          {selected.countryIso2}
        </p>
      )}
    </div>
  );
}