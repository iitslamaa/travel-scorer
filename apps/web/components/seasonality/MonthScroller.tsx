'use client';

import * as React from 'react';
import type { MonthNumber } from '../../../../packages/data/src';

interface MonthMeta {
  value: MonthNumber;
  label: string;
  short: string;
}

interface MonthScrollerProps {
  months: MonthMeta[];
  selectedMonth: MonthNumber;
  onSelectMonth: (month: MonthNumber) => void;
}

export const MonthScroller: React.FC<MonthScrollerProps> = ({
  months,
  selectedMonth,
  onSelectMonth,
}) => {
  const handleClick = (month: MonthNumber) => {
    onSelectMonth(month);
  };

  return (
    <div className="space-y-2">
      <p className="text-xs font-medium uppercase tracking-[0.2em] text-stone-400">
        Calendar year
      </p>
      <div className="no-scrollbar flex gap-2 overflow-x-auto rounded-2xl border border-stone-200 bg-white/80 p-2 shadow-sm backdrop-blur-sm scroll-smooth snap-x snap-mandatory">
        {months.map((m) => {
          const isActive = m.value === selectedMonth;
          return (
            <button
              key={m.value}
              type="button"
              onClick={() => handleClick(m.value)}
              className={[
                'flex min-w-[72px] flex-col items-center justify-center rounded-xl px-3 py-2 text-xs font-medium transition-all snap-center',
                isActive
                  ? 'bg-stone-900 text-stone-50 shadow-sm'
                  : 'bg-stone-50 text-stone-700 hover:bg-stone-100',
              ].join(' ')}
            >
              <span className="text-[11px] uppercase tracking-[0.18em] opacity-70">
                {m.short}
              </span>
              <span className="mt-1 text-sm">
                {m.value.toString().padStart(2, '0')}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
};