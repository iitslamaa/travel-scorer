'use client';

import * as React from 'react';
import type { CountrySeasonality } from '../../../../packages/data/src';

interface CountryListProps {
  title: string;
  description?: string;
  tone: 'peak' | 'shoulder';
  countries: CountrySeasonality[];
}

export const CountryList: React.FC<CountryListProps> = ({
  title,
  description,
  tone,
  countries,
}) => {
  const toneClasses =
    tone === 'peak'
      ? {
          border: 'border-emerald-100',
          bg: 'bg-emerald-50/70',
        }
      : {
          border: 'border-amber-100',
          bg: 'bg-amber-50/70',
        };

  return (
    <section
      className={[
        'flex flex-col rounded-2xl border p-4 shadow-sm backdrop-blur-sm',
        toneClasses.border,
        toneClasses.bg,
      ].join(' ')}
    >
      <div className="mb-3">
        <h2 className="text-sm font-semibold text-stone-900">{title}</h2>
        {description && (
          <p className="mt-1 text-xs text-stone-600">{description}</p>
        )}
      </div>

      {countries.length === 0 ? (
        <p className="mt-4 text-xs text-stone-500">
          No destinations in this category for the selected month yet.
        </p>
      ) : (
        <ul className="mt-1 flex flex-wrap gap-2">
          {countries.map((c) => (
            <li
              key={c.isoCode}
              className="inline-flex items-center gap-2 rounded-full bg-white/70 px-3 py-1 text-xs text-stone-800 shadow-sm"
            >
              <span className="font-medium">{c.name}</span>
              <span className="text-[10px] uppercase tracking-[0.18em] text-stone-400">
                {c.region}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
};