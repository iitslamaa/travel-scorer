'use client';

import { useState } from 'react';
import type { CountryFacts } from '@travel-af/shared';
import type { ScoreWeights } from '@travel-af/domain/src/scoring';
import { buildRows, normalizeWeights, DEFAULT_WEIGHTS } from '@travel-af/domain/src/scoring';
import { AdvisoryBadge } from '@/lib/display/AdvisoryBadge';
import { ScorePill } from '@/lib/display/ScorePill';
import { VisaSection } from './components/VisaSection';
import { Seasonality } from './components/Seasonality';
import { AffordabilitySection } from './components/AffordabilitySection';


type CountryRowLite = {
  advisory?: {
    level?: 1 | 2 | 3 | 4;
  } | null;
};

type Props = {
  facts: CountryFacts;
  row: CountryRowLite;
};

export default function InteractiveScoring({ facts, row }: Props) {
  const [weights, setWeights] = useState<ScoreWeights>(DEFAULT_WEIGHTS);

  const { rows, total } = buildRows(facts, weights);

  async function persist(updated: ScoreWeights) {
    try {
      await fetch('/api/score-weights', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(updated),
      });
    } catch (err) {
      console.error('[InteractiveScoring] failed to persist weights', err);
    }
  }

  function update(key: keyof ScoreWeights, value: number) {
    const updated = normalizeWeights({
      ...weights,
      [key]: value,
    });

    setWeights(updated);
    persist(updated);
  }

  function reset() {
    setWeights(DEFAULT_WEIGHTS);
    persist(DEFAULT_WEIGHTS);
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
              onChange={(e) => update(key, Number(e.target.value))}
              className="w-full"
            />
          </div>
        ))}

        <button
          onClick={reset}
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
        {row.advisory && <AdvisoryBadge level={row.advisory.level} />}
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
        <AffordabilitySection facts={facts} />
      </section>
    </>
  );
}