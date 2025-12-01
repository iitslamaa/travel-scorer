'use client';

import { useMemo, useState } from 'react';
import {
  ALL_MONTHS,
  getCountriesForMonth,
  type MonthNumber,
} from '../../../../packages/data/src';
import { MonthScroller } from './MonthScroller';
import { CountryList } from './CountryList';

function getCurrentMonth(): MonthNumber {
  const now = new Date();
  return (now.getMonth() + 1) as MonthNumber;
}

export const SeasonalityExplorer: React.FC = () => {
  const [selectedMonth, setSelectedMonth] = useState<MonthNumber>(getCurrentMonth());

  const selectedMonthMeta = useMemo(
    () => ALL_MONTHS.find((m) => m.value === selectedMonth)!,
    [selectedMonth]
  );

  const { peak, shoulder } = useMemo(
    () => getCountriesForMonth(selectedMonth),
    [selectedMonth]
  );

  const totalCount = peak.length + shoulder.length;

  return (
    <section className="space-y-6">
      <MonthScroller
        months={ALL_MONTHS}
        selectedMonth={selectedMonth}
        onMonthChange={setSelectedMonth}
      />

      <div className="rounded-2xl border border-stone-200 bg-white/80 p-4 shadow-sm backdrop-blur-sm sm:flex sm:items-center sm:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-stone-400">
            Selected month
          </p>
          <p className="mt-1 text-lg font-medium text-stone-900">
            {selectedMonthMeta.label}
          </p>
        </div>
        <div className="mt-3 flex flex-wrap gap-2 sm:mt-0 sm:justify-end">
          <span className="inline-flex items-center rounded-full border border-emerald-200 bg-emerald-50 px-3 py-1 text-xs font-medium text-emerald-800">
            Peak: {peak.length}
          </span>
          <span className="inline-flex items-center rounded-full border border-amber-200 bg-amber-50 px-3 py-1 text-xs font-medium text-amber-800">
            Shoulder: {shoulder.length}
          </span>
          <span className="inline-flex items-center rounded-full border border-stone-200 bg-stone-50 px-3 py-1 text-xs font-medium text-stone-700">
            Total: {totalCount}
          </span>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <CountryList
          title="Peak season"
          description="Best weather and overall conditions — usually the busiest and priciest."
          tone="peak"
          countries={peak}
        />
        <CountryList
          title="Shoulder season"
          description="Still good conditions, often fewer crowds and better value."
          tone="shoulder"
          countries={shoulder}
        />
      </div>
    </section>
  );
};