'use client';

import React, { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import {
  ALL_MONTHS,
  getCountriesForMonth,
  type MonthNumber,
  type CountrySeasonality,
} from '../../../../packages/data/src/seasonality';
import { MonthScroller } from './MonthScroller';
import { CountryList } from './CountryList';

const SCORE_BANDS = {
  high: 90,
  medium: 75,
} as const;

function getScoreTone(score?: number) {
  if (typeof score !== 'number') return 'neutral';
  if (score >= SCORE_BANDS.high) return 'high';
  if (score >= SCORE_BANDS.medium) return 'medium';
  return 'low';
}

type UiCountry = {
  isoCode: string;
  name: string;
  score?: number;
  region?: string;
  advisoryLevel?: number;
};

type CountriesApiCountry = {
  iso2: string;
  name: string;
  score?: number; // legacy / fallback
  region?: string;
  advisoryLevel?: number;
  facts?: {
    scoreTotal?: number; // overall TravelScorer score used for coloring
  };
};

type CountriesApiResponse = {
  countries: CountriesApiCountry[];
};

function getCurrentMonth(): MonthNumber {
  const now = new Date();
  return (now.getMonth() + 1) as MonthNumber;
}

type CountryPreviewProps = {
  country: UiCountry;
};

const CountryPreviewCard: React.FC<CountryPreviewProps> = ({ country }) => {
  const tone = getScoreTone(country.score);

  const scoreBadgeClasses =
    tone === 'high'
      ? 'bg-emerald-50 text-emerald-700'
      : tone === 'medium'
      ? 'bg-amber-50 text-amber-700'
      : tone === 'low'
      ? 'bg-red-50 text-red-700'
      : 'bg-neutral-100 text-neutral-700';

  return (
    <div className="h-full rounded-2xl border border-neutral-200 bg-white/80 p-4 shadow-sm">
      <p className="mb-1 text-xs font-semibold uppercase tracking-wide text-neutral-500">
        Selected destination
      </p>
      <h3 className="mb-1 text-lg font-semibold text-neutral-900">{country.name}</h3>
      {country.region && (
        <p className="mb-1 text-xs text-neutral-500">{country.region}</p>
      )}
      <div className="mt-2 flex items-center gap-2">
        {typeof country.score === 'number' && (
          <span
            className={
              'inline-flex items-center rounded-full px-3 py-1 text-xs font-medium ' +
              scoreBadgeClasses
            }
          >
            TravelScorer score: <span className="ml-1">{country.score}</span>
          </span>
        )}
        {typeof country.advisoryLevel === 'number' && (
          <span className="inline-flex items-center rounded-full bg-neutral-100 px-3 py-1 text-xs font-medium text-neutral-700">
            Advisory level {country.advisoryLevel}
          </span>
        )}
      </div>
      <p className="mt-3 text-sm text-neutral-600">
        This month is one of the best times to visit based on weather, crowds, and overall
        conditions.
      </p>
      <div className="mt-4">
        <Link
          href={`/country/${country.isoCode.toLowerCase()}`}
          className="inline-flex items-center text-sm font-medium text-neutral-900 underline underline-offset-4 hover:text-neutral-700"
        >
          Open full country page
          <span className="ml-1 text-xs">→</span>
        </Link>
      </div>
    </div>
  );
};

export const SeasonalityExplorer: React.FC = () => {
  const [selectedMonth, setSelectedMonth] = useState<MonthNumber>(getCurrentMonth());
  const [selectedCountry, setSelectedCountry] = useState<UiCountry | null>(null);

  const [countryMetaByIso, setCountryMetaByIso] = useState<
    Record<string, { name: string; score?: number; region?: string; advisoryLevel?: number }>
  >({});
  const [isLoadingMeta, setIsLoadingMeta] = useState<boolean>(true);

  // Load country names + scores from /api/countries once
  useEffect(() => {
    let isCancelled = false;

    async function loadCountries() {
      try {
        const res = await fetch('/api/countries');
        if (!res.ok) {
          throw new Error(`Failed to fetch countries: ${res.status}`);
        }

        const raw = (await res.json()) as CountriesApiResponse | CountriesApiCountry[];

        let list: CountriesApiCountry[] = [];
        if (Array.isArray(raw)) {
          list = raw;
        } else if (raw && Array.isArray(raw.countries)) {
          list = raw.countries;
        }

        const map: Record<string, { name: string; score?: number; region?: string; advisoryLevel?: number }> = {};
        for (const c of list) {
          if (!c || !c.iso2) continue;
          const iso = String(c.iso2).toUpperCase();
          const overallScore =
            typeof c.score === 'number'
              ? c.score
              : typeof c.facts?.scoreTotal === 'number'
                ? c.facts.scoreTotal
                : undefined;

          map[iso] = {
            name: c.name ?? iso,
            score: overallScore,
            region: c.region,
            advisoryLevel: c.advisoryLevel,
          };
        }

        if (!isCancelled) {
          setCountryMetaByIso(map);
        }
      } catch (err) {
        console.error('Failed to load countries for seasonality explorer', err);
      } finally {
        if (!isCancelled) {
          setIsLoadingMeta(false);
        }
      }
    }

    void loadCountries();

    return () => {
      isCancelled = true;
    };
  }, []);

  const handleSelectMonth = (month: MonthNumber) => {
    setSelectedMonth(month);
    setSelectedCountry(null);
  };

  // Raw seasonality from shared dataset (iso-only)
  const { peak: rawPeak, shoulder: rawShoulder } = useMemo(
    () => getCountriesForMonth(selectedMonth),
    [selectedMonth]
  );

  const selectedMonthMeta = useMemo(
    () => ALL_MONTHS.find((m) => m.value === selectedMonth)!,
    [selectedMonth]
  );

  // Enrich with names + scores and sort by score (high → low)
  const { peak, shoulder } = useMemo(() => {
    const enrich = (raw: CountrySeasonality[]): UiCountry[] => {
      const enriched = raw.map((c) => {
        const meta = countryMetaByIso[c.isoCode] ?? {};
        return {
          isoCode: c.isoCode,
          name: meta.name ?? c.name ?? c.isoCode,
          score: meta.score,
          region: meta.region,
          advisoryLevel: meta.advisoryLevel,
        } as UiCountry;
      });

      enriched.sort((a, b) => {
        const scoreA = a.score ?? -Infinity;
        const scoreB = b.score ?? -Infinity;
        return scoreB - scoreA;
      });

      return enriched;
    };

    return {
      peak: enrich(rawPeak),
      shoulder: enrich(rawShoulder),
    };
  }, [rawPeak, rawShoulder, countryMetaByIso]);

  const totalCount = peak.length + shoulder.length;
  const selectedIsoCode = selectedCountry?.isoCode ?? null;

  return (
    <div className="space-y-8">
      <header className="space-y-2">
        <h1 className="text-2xl font-semibold text-neutral-900">When to Go</h1>
        <p className="max-w-2xl text-sm text-neutral-500">
          Select a month to explore where it&apos;s peak or shoulder season around the world.
        </p>
      </header>

      <section className="space-y-4">
        <div className="text-xs font-medium uppercase tracking-[0.15em] text-neutral-500">
          Calendar year
        </div>
        <MonthScroller
          months={ALL_MONTHS}
          selectedMonth={selectedMonth}
          onSelectMonth={handleSelectMonth}
        />
      </section>

      <section className="flex items-center justify-between rounded-2xl border border-neutral-200 bg-white/70 px-4 py-3 text-xs">
        <div className="space-y-1">
          <div className="font-semibold text-neutral-800">Selected month</div>
          <div className="text-neutral-600">{selectedMonthMeta.label}</div>
        </div>
        <div className="flex items-center gap-3 text-[11px]">
          <span className="rounded-full bg-emerald-50 px-3 py-1 font-medium text-emerald-700">
            Peak: {peak.length}
          </span>
          <span className="rounded-full bg-amber-50 px-3 py-1 font-medium text-amber-700">
            Shoulder: {shoulder.length}
          </span>
          <span className="rounded-full bg-neutral-100 px-3 py-1 font-medium text-neutral-700">
            Total: {totalCount}
          </span>
        </div>
      </section>

      <section className="grid gap-6 md:grid-cols-[minmax(0,2fr)_minmax(0,1.4fr)]">
        {/* Left: peak + shoulder lists */}
        <div className="space-y-4">
          <CountryList
            title="Peak season"
            tone="peak"
            description="Best weather and overall conditions — usually the busiest and priciest."
            countries={peak}
            selectedIsoCode={selectedIsoCode}
            onSelectCountry={setSelectedCountry}
          />
          <CountryList
            title="Shoulder season"
            tone="shoulder"
            description="Still good conditions, often fewer crowds and better value."
            countries={shoulder}
            selectedIsoCode={selectedIsoCode}
            onSelectCountry={setSelectedCountry}
          />
        </div>

        {/* Right: desktop side panel */}
        <aside className="hidden md:block">
          {selectedCountry ? (
            <CountryPreviewCard country={selectedCountry} />
          ) : (
            <div className="h-full rounded-2xl border border-dashed border-neutral-200 bg-neutral-50/60 p-4 text-sm text-neutral-500">
              Click any country in the list to preview its details here.
            </div>
          )}
        </aside>
      </section>

      {/* Mobile: selected country card below lists */}
      {selectedCountry && (
        <section className="md:hidden">
          <CountryPreviewCard country={selectedCountry} />
        </section>
      )}
    </div>
  );
};