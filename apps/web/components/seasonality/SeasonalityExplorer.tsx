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
import { ScorePill } from '@/lib/display/ScorePill';

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

function isoToFlagEmoji(isoCode?: string) {
  if (!isoCode) return '';
  const code = isoCode.toUpperCase();
  if (code.length !== 2) return '';
  const A = 0x1f1e6;
  const alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  const chars = [...code].map((ch) => {
    const index = alpha.indexOf(ch);
    if (index === -1) return '';
    return String.fromCodePoint(A + index);
  });

  return chars.join('');
}

type UiCountry = {
  isoCode: string;
  name: string;
  score?: number;
  region?: string;
  advisoryLevel?: number;
  seasonalityScore?: number;
  affordabilityScore?: number;
  visaEaseScore?: number;
};

type CountriesApiCountry = {
  iso2: string;
  name: string;
  score?: number; // legacy / fallback
  region?: string;
  advisoryLevel?: number;
  facts?: {
    scoreTotal?: number; // overall TravelScorer score used for coloring
    seasonality?: number;
    affordability?: number;
    visaEase?: number;
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
  const flag = isoToFlagEmoji(country.isoCode);

  const safetyLabel =
    typeof country.advisoryLevel === 'number'
      ? `Safety · Lvl ${country.advisoryLevel}`
      : 'Safety info';

  const safetyClasses =
    typeof country.advisoryLevel !== 'number'
      ? 'bg-neutral-100 text-neutral-700'
      : country.advisoryLevel <= 2
      ? 'bg-emerald-50 text-emerald-700'
      : country.advisoryLevel === 3
      ? 'bg-amber-50 text-amber-700'
      : 'bg-red-50 text-red-700';

  return (
    <div className="h-full rounded-2xl border border-neutral-200 bg-white/80 p-4 shadow-sm">
      {/* Header: label + flag + name + region + score pill */}
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-neutral-500">
            Selected destination
          </p>
          <div className="mt-1 flex items-center gap-2">
            {flag && (
              <span className="text-2xl" aria-hidden="true">
                {flag}
              </span>
            )}
            <div>
              <h3 className="text-lg font-semibold text-neutral-900">
                {country.name}
              </h3>
              {country.region && (
                <p className="text-xs text-neutral-500">{country.region}</p>
              )}
            </div>
          </div>
        </div>

        {typeof country.score === 'number' && (
          <ScorePill
            value={country.score}
            title="Overall TravelScorer score"
          />
        )}
      </div>

      {/* Badges row */}
      <div className="mt-3 flex flex-wrap items-center gap-2 text-[11px]">
        <span
          className={`inline-flex items-center rounded-full px-2.5 py-1 font-medium ${safetyClasses}`}
        >
          {safetyLabel}
        </span>

        {country.region && (
          <span className="inline-flex items-center rounded-full bg-neutral-50 px-2.5 py-1 font-medium text-neutral-700">
            Region · {country.region}
          </span>
        )}
      </div>

      {/* Compact score breakdown */}
      {(typeof country.seasonalityScore === 'number' ||
        typeof country.affordabilityScore === 'number' ||
        typeof country.visaEaseScore === 'number') && (
        <div className="mt-3 rounded-xl bg-neutral-50 px-3 py-2">
          <p className="mb-1 text-xs font-semibold text-neutral-600">
            Score snapshot
          </p>
          <dl className="space-y-1 text-xs">
            {typeof country.seasonalityScore === 'number' && (
              <div className="flex items-center justify-between">
                <dt className="text-neutral-500">Seasonality</dt>
                <dd>
                  <ScorePill value={country.seasonalityScore} />
                </dd>
              </div>
            )}
            {typeof country.affordabilityScore === 'number' && (
              <div className="flex items-center justify-between">
                <dt className="text-neutral-500">Affordability</dt>
                <dd>
                  <ScorePill value={country.affordabilityScore} />
                </dd>
              </div>
            )}
            {typeof country.visaEaseScore === 'number' && (
              <div className="flex items-center justify-between">
                <dt className="text-neutral-500">Visa ease</dt>
                <dd>
                  <ScorePill value={country.visaEaseScore} />
                </dd>
              </div>
            )}
          </dl>
        </div>
      )}

      {/* Short summary */}
      <p className="mt-3 text-sm text-neutral-600">
        This month is one of the best times to visit based on weather, crowds, and
        overall conditions. Open the full country page to compare safety, affordability,
        and visa details.
      </p>

      {/* Footer link */}
      <div className="mt-4 border-t border-neutral-100 pt-3">
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
    Record<
      string,
      {
        name: string;
        score?: number;
        region?: string;
        advisoryLevel?: number;
        seasonalityScore?: number;
        affordabilityScore?: number;
        visaEaseScore?: number;
      }
    >
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

        const map: Record<
          string,
          {
            name: string;
            score?: number;
            region?: string;
            advisoryLevel?: number;
            seasonalityScore?: number;
            affordabilityScore?: number;
            visaEaseScore?: number;
          }
        > = {};
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
            seasonalityScore: c.facts?.seasonality,
            affordabilityScore: c.facts?.affordability,
            visaEaseScore: c.facts?.visaEase,
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
          seasonalityScore: meta.seasonalityScore,
          affordabilityScore: meta.affordabilityScore,
          visaEaseScore: meta.visaEaseScore,
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