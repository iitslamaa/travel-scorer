'use client';

import React, { useEffect, useMemo, useState } from 'react';
import {
  ALL_MONTHS,
  getCountriesForMonth,
  type MonthNumber,
  type CountrySeasonality,
} from '../../../../packages/data/src/seasonality';
import { MonthScroller } from './MonthScroller';
import { CountryList } from './CountryList';

type UiCountry = {
  isoCode: string;
  name: string;
  score?: number;
};

type CountriesApiCountry = {
  iso2: string;
  name: string;
  score?: number;
};

type CountriesApiResponse = {
  countries: CountriesApiCountry[];
};

function getCurrentMonth(): MonthNumber {
  const now = new Date();
  return (now.getMonth() + 1) as MonthNumber;
}

export const SeasonalityExplorer: React.FC = () => {
  const [selectedMonth, setSelectedMonth] = useState<MonthNumber>(getCurrentMonth());

  const [countryMetaByIso, setCountryMetaByIso] = useState<
    Record<string, { name: string; score?: number }>
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

        const map: Record<string, { name: string; score?: number }> = {};
        for (const c of list) {
          if (!c || !c.iso2) continue;
          const iso = String(c.iso2).toUpperCase();
          map[iso] = {
            name: c.name ?? iso,
            score: c.score,
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
        };
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
          onSelectMonth={(month: MonthNumber) => setSelectedMonth(month)}
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

      <section className="grid gap-4 md:grid-cols-2">
        <CountryList
          title="Peak season"
          tone="peak"
          description="Best weather and overall conditions — usually the busiest and priciest."
          countries={peak}
        />
        <CountryList
          title="Shoulder season"
          tone="shoulder"
          description="Still good conditions, often fewer crowds and better value."
          countries={shoulder}
        />
      </section>
    </div>
  );
};