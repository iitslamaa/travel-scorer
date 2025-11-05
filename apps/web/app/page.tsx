'use client';

import { useEffect, useMemo, useState } from 'react';
import { DEFAULT_WEIGHTS, computeScoreFromFacts } from '@/lib/score';
// import type { CountryFacts } from '@/lib/types';

// Shape returned by /api/countries (seed + advisory overlay)
type CountryRow = {
  iso2: string;
  iso3: string;
  m49: number;
  name: string;
  region?: string;
  subregion?: string;
  aliases?: string[];
  advisory?: { level: 1 | 2 | 3 | 4; updatedAt: string; url: string; summary: string } | null;
};

export default function Home() {
  const [data, setData] = useState<CountryRow[]>([]);
  const [q, setQ] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        setLoading(true);
        const res = await fetch('/api/countries', { cache: 'no-store' });
        if (!res.ok) throw new Error('Failed to load countries');
        const rows: CountryRow[] = (await res.json()) as CountryRow[];
        if (alive) { setData(rows); setError(null); }
      } catch (e: unknown) {
        if (alive) setError(e instanceof Error ? e.message : 'Failed to load');
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => { alive = false; };
  }, []);

  const filtered = useMemo(() => {
    const qq = q.trim().toLowerCase();
    if (!qq) return data;
    return data.filter(c =>
      c.name.toLowerCase().includes(qq) ||
      (c.aliases ?? []).some(a => a.toLowerCase().includes(qq)) ||
      c.iso2.toLowerCase() === qq ||
      c.iso3.toLowerCase() === qq
    );
  }, [data, q]);

  const scoreFor = (c: CountryRow) => {
    const month = new Date().getMonth() + 1;
    // const facts: Partial<CountryFacts> = {
    //   iso2: c.iso2,
    //   advisoryLevel: c.advisory?.level,
    // };
    // try {
    //   return computeScoreFromFacts(facts as CountryFacts, DEFAULT_WEIGHTS, month);
    // } catch {
    //   return undefined;
    // }
  };

  return (
    <main className="mx-auto max-w-5xl p-6">
      <h1 className="text-3xl font-bold">TRAVEL APP AF</h1>
      <p className="text-zinc-600 dark:text-zinc-400 mb-4">
        Canonical UN/ISO countries & territories with live travel.state.gov advisory overlay.
      </p>

      <div className="flex items-center justify-between gap-3 mb-4">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search countries or codes (e.g., JP, JPN, 'Korea')"
          className="w-full max-w-md rounded border px-3 py-2 bg-white dark:bg-zinc-900"
        />
        <span className="text-sm text-zinc-600 dark:text-zinc-400">
          {filtered.length} countries
        </span>
      </div>

      {loading ? (
        <div className="text-zinc-600 dark:text-zinc-400">Loading…</div>
      ) : error ? (
        <div className="text-red-600">{error}</div>
      ) : (
        <div className="grid md:grid-cols-2 gap-4">
          {filtered.map((c) => {
            const s = scoreFor(c);
            return (
              <div key={c.iso2} className="rounded-xl border border-zinc-200 dark:border-zinc-800 p-4">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <div className="text-lg font-semibold">{c.name}</div>
                    <div className="text-sm text-zinc-600 dark:text-zinc-400">
                      {c.region || '—'} {c.subregion ? `• ${c.subregion}` : ''}
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="text-right text-sm text-zinc-500">
                      <div>{c.iso2} / {c.iso3}</div>
                      <div>M49: {c.m49 || '—'}</div>
                    </div>
                    {typeof s === 'number' && (
                      <span
                        title="Travelability score"
                        className="inline-flex h-7 min-w-[2.25rem] items-center justify-center rounded-full border px-2 text-sm font-semibold"
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
                      <a className="underline" href={c.advisory.url} target="_blank" rel="noreferrer">travel.state.gov</a>
                      <div className="text-xs text-zinc-500">
                        Updated {new Date(c.advisory.updatedAt).toLocaleDateString()}
                      </div>
                      {c.advisory.summary && (
                        <div className="text-xs mt-1 text-zinc-600 dark:text-zinc-400 line-clamp-3">
                          {c.advisory.summary}
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="text-sm text-zinc-500">No advisory found.</div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </main>
  );
}