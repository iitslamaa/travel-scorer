'use client';

import { useState } from 'react';
import type { CountryFacts } from '@travel-af/shared';
import type { ScoreWeights } from '@travel-af/domain/src/scoring';
import { buildRows } from '@travel-af/domain';
import { loadWeights, saveWeights, normalizeWeights, DEFAULT_WEIGHTS } from '@/lib/scoreWeights';
import { AdvisoryBadge } from '@/lib/display/AdvisoryBadge';
import { ScorePill } from '@/lib/display/ScorePill';
import { VisaSection } from './components/VisaSection';
import { Seasonality } from './components/Seasonality';

type Props = {
  facts: CountryFacts;
  row: any;
};

export default function InteractiveScoring({ facts, row }: Props) {
  const [weights, setWeights] = useState<ScoreWeights>(loadWeights());

  const { rows, total } = buildRows(facts, weights);

  function update(key: keyof ScoreWeights, value: number) {
    const updated = normalizeWeights({
      ...weights,
      [key]: value,
    });

    setWeights(updated);
    saveWeights(updated);
  }

  return (
    <>
      {/* Weight Controls */}
      <section className="card p-5 mb-8">
        <h3 className="font-medium mb-4">Adjust Score Weights</h3>

        {(Object.keys(weights) as (keyof ScoreWeights)[]).map((key) => (
          <div key={key} className="mb-4">
            <div className="flex justify-between text-sm mb-1">
              <span>{key}</span>
              <span>{Math.round(weights[key] * 100)}%</span>
            </div>

            <input
              type="range"
              min="0"
              max="1"
              step="0.01"
              value={weights[key]}
              onChange={(e) =>
                update(key, Number(e.target.value))
              }
              className="w-full"
            />
          </div>
        ))}

        <button
          onClick={() => {
            setWeights(DEFAULT_WEIGHTS);
            saveWeights(DEFAULT_WEIGHTS);
          }}
          className="text-sm underline mt-2"
        >
          Reset to defaults
        </button>
      </section>

      {/* Score */}
      <div className="card p-5 mb-8">
        <div className="flex items-baseline justify-between mb-2">
          <h2 className="font-medium">Overall Travelability Score</h2>
          <div className="text-3xl font-bold">{total}</div>
        </div>
      </div>

      {/* Advisory */}
      <section className="card p-5 mb-8">
        <h3 className="font-medium mb-2">Travel Advisory</h3>
        {row.advisory && (
          <>
            <AdvisoryBadge level={row.advisory.level} />
          </>
        )}
      </section>

      {/* Seasonality */}
      <section className="card p-5 mb-8">
        <h3 className="font-medium mb-2">Seasonality</h3>
        <Seasonality rows={rows} fm={{}} />
      </section>

      {/* Visa */}
      <section className="card p-5 mb-8">
        <h3 className="font-medium mb-2">Visa Ease</h3>
        <VisaSection rows={rows} facts={facts} />
      </section>

      {/* Affordability */}
      <section className="card p-5 mb-8">
        <h3 className="font-medium mb-2">Affordability</h3>
        <ScorePill
          value={
            typeof rows.find(r => r.key === 'affordability')?.raw === 'number'
              ? Math.round(rows.find(r => r.key === 'affordability')!.raw as number)
              : undefined
          }
        />
      </section>
    </>
  );
}