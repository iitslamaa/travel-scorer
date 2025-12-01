'use client';

import { useEffect, useMemo, useState } from 'react';
import type { CountryFacts } from '@travel-af/shared';
import Link from 'next/link';
import Image from 'next/image';

// Shape returned by /api/countries (seed + advisory overlay)

type CountryRow = {
  iso2: string;
  iso3: string;
  m49: number;
  name: string;
  score?: number;
  region?: string;
  subregion?: string;
  aliases?: string[];
  advisory?: { level: 1 | 2 | 3 | 4; updatedAt: string; url: string; summary: string } | null;
  facts?: (Partial<CountryFacts> & { scoreTotal?: number }) | undefined;
};

type CountriesResponse = {
  countries: CountryRow[];
};

type CountriesResult = CountriesResponse | CountryRow[];

function isCountriesResponse(json: unknown): json is CountriesResponse {
  return (
    typeof json === 'object' &&
    json !== null &&
    Array.isArray((json as CountriesResponse).countries)
  );
}

export default function Home() {
  const [data, setData] = useState<CountryRow[]>([]);
  const [q, setQ] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc'); // default: high → low

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        setLoading(true);
        const res = await fetch('/api/countries', { cache: 'no-store' });
        if (!res.ok) throw new Error('Failed to load countries');

        const json: CountriesResult | unknown = await res.json();
        let rows: CountryRow[] = [];

        if (Array.isArray(json)) {
          // Old shape: API returns an array directly
          rows = json as CountryRow[];
        } else if (isCountriesResponse(json)) {
          // New shape: { countries: [...] }
          rows = json.countries;
        }

        if (alive) {
          setData(rows);
          setError(null);
        }
      } catch (e: unknown) {
        if (alive) setError(e instanceof Error ? e.message : 'Failed to load');
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => {
      alive = false;
    };
  }, []);

  const scoreFor = (c: CountryRow) => {
    const raw =
      c.score ??
      (typeof c.facts?.scoreTotal === 'number' ? c.facts!.scoreTotal : c.facts?.scoreTotal);
    const num = typeof raw === 'string' ? Number(raw) : raw;
    return typeof num === 'number' && Number.isFinite(num) ? num : undefined;
  };

  const filtered = useMemo(() => {
    if (!data) return [];

    const term = q.trim().toLowerCase();

    const base = data.filter((row) => {
      if (!term) return true;

      const haystack = [
        row.name,
        row.iso2,
        row.iso3,
        row.m49?.toString(),
        ...(row.aliases ?? []),
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();

      return haystack.includes(term);
    });

    // Sort by score, using the same logic as Swift
    const sorted = [...base].sort((a, b) => {
      const sa = scoreFor(a) ?? 0;
      const sb = scoreFor(b) ?? 0;
      return sortOrder === 'asc' ? sa - sb : sb - sa;
    });

    return sorted;
  }, [data, q, sortOrder]);

  return (
    <>
      <h1 className="h1 mt-1 mb-5">TravelScorer</h1>
      <p className="muted mb-6">
        Canonical UN/ISO countries & territories with live travel.state.gov advisory overlay.
      </p>

      <section className="mb-6">
        <div className="flex flex-col gap-3 rounded-2xl border border-zinc-200 bg-white/80 px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-5 sm:py-4 dark:border-zinc-800 dark:bg-zinc-900/60">
          <div className="space-y-1">
            <p className="text-[11px] font-semibold tracking-wide text-zinc-500 uppercase">
              New · When to Go
            </p>
            <p className="text-sm text-zinc-700 dark:text-zinc-300 max-w-xl">
              Explore which countries are in peak or shoulder season for each month of the year
              before you compare safety and affordability.
            </p>
          </div>
          <div className="flex-shrink-0">
            <Link
              href="/seasonality"
              className="inline-flex items-center rounded-full border border-zinc-300 bg-white/90 px-4 py-2 text-sm font-medium text-zinc-900 shadow-sm hover:bg-zinc-50 hover:border-zinc-400 focus:outline-none focus-visible:ring-2 focus-visible:ring-zinc-900/40 focus-visible:ring-offset-2 focus-visible:ring-offset-white dark:bg-zinc-900 dark:text-zinc-50 dark:border-zinc-700 dark:hover:bg-zinc-800 dark:hover:border-zinc-500 dark:focus-visible:ring-offset-zinc-950"
            >
              Open “When to Go”
              <span className="ml-1.5 text-xs">→</span>
            </Link>
          </div>
        </div>
      </section>

      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 sm:gap-3 mb-4">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search destinations by country or code (e.g., JP, JPN, 'Korea')"
          className="w-full rounded border px-3 py-2 bg-white dark:bg-zinc-900"
        />
        <div className="flex items-center gap-2 sm:ml-3 self-end sm:self-auto mt-1 sm:mt-0">
          <button
            type="button"
            className="text-xs px-2 py-1 rounded border border-zinc-300 bg-white hover:bg-zinc-50 dark:bg-zinc-900 dark:border-zinc-700"
            onClick={() => setSortOrder((prev) => (prev === 'asc' ? 'desc' : 'asc'))}
          >
            Sort by score: {sortOrder === 'asc' ? '↑ low → high' : '↓ high → low'}
          </button>
          <span className="text-sm muted">
            {filtered.length} countries
          </span>
        </div>
      </div>

      {loading ? (
        <div className="muted">Loading…</div>
      ) : error ? (
        <div className="text-red-600">{error}</div>
      ) : (
        <div className="grid-cards">
          {filtered.map((c) => {
            const s = scoreFor(c);
            return (
              <Link
                key={c.iso2}
                href={`/country/${c.iso2.toLowerCase()}`}
                className="card p-3 sm:p-4 block hover:-translate-y-0.5 transition-transform"
              >
                <div className="flex flex-col gap-1.5 sm:flex-row sm:items-center sm:justify-between">
                  <div className="flex items-center gap-2">
                    <Image
                      src={`https://flagcdn.com/w40/${c.iso2.toLowerCase()}.png`}
                      alt={`${c.name} flag`}
                      width={24}
                      height={16}
                      className="rounded shadow-sm ring-1 ring-black/10 dark:ring-white/10 bg-white"
                      unoptimized
                    />
                    <div>
                      <div className="h2">{c.name}</div>
                      <div className="text-sm muted">
                        {c.region || '—'} {c.subregion ? `• ${c.subregion}` : ''}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center justify-between sm:justify-end gap-3 order-2 sm:order-none">
                    <div className="hidden sm:block text-sm muted text-right">
                      <div>{c.iso2} / {c.iso3}</div>
                      <div>M49: {c.m49 || '—'}</div>
                    </div>
                    {typeof s === 'number' && (
                      <span
                        title="Travelability score"
                        className={`pill ${s >= 80 ? 'pill--good' : s >= 60 ? 'pill--warn' : 'pill--bad'}`}
                      >
                        {s}
                      </span>
                    )}
                  </div>
                </div>
                {/* rest of the card stays the same */}
                <div className="mt-3">
                  {c.advisory ? (
                    <div className="text-sm">
                      <span className="font-medium">Advisory:</span>{' '}
                      Level {c.advisory.level} •{' '}
                      <button
                        className="underline text-blue-600"
                        onClick={(e) => {
                          e.preventDefault();
                          e.stopPropagation();
                          if (c.advisory?.url) {
                            window.open(c.advisory.url, '_blank', 'noopener,noreferrer');
                          }
                        }}
                      >
                        travel.state.gov
                      </button>
                      <div className="text-xs muted hidden sm:block">
                        Updated {new Date(c.advisory.updatedAt).toLocaleDateString()}
                      </div>
                      {c.advisory.summary && (
                        <div className="hidden sm:block text-xs mt-1 muted line-clamp-3 max-w-prose">
                          {c.advisory.summary}
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="text-sm muted">No advisory found.</div>
                  )}
                </div>
                <div className="mt-3 text-sm hidden sm:block">
                  <span className="muted">Details: </span>
                  <span className="text-blue-600 underline">Open country page →</span>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </>
  );
}