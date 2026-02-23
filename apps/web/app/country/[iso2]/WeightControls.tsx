'use client';

import { useEffect, useState } from 'react';
import type { ScoreWeights } from '@travel-af/domain/src/scoring';
import { normalizeWeights, DEFAULT_WEIGHTS } from '@travel-af/domain/src/scoring';

type Props = {
  onChange: (weights: ScoreWeights) => void;
};

export default function WeightControls({ onChange }: Props) {
  const [weights, setWeights] = useState<ScoreWeights>(DEFAULT_WEIGHTS);

  useEffect(() => {
    setWeights(DEFAULT_WEIGHTS);
    onChange(DEFAULT_WEIGHTS);
  }, []);

  function update(key: keyof ScoreWeights, value: number) {
    const updated = normalizeWeights({
      ...weights,
      [key]: value,
    });

    setWeights(updated);
    onChange(updated);

    // Persist to backend
    fetch('/api/score-weights', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(updated),
    }).catch((err) => {
      console.error('[WeightControls] failed to save weights', err);
    });
  }

  return (
    <div className="card p-5 mb-8">
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
          onChange(DEFAULT_WEIGHTS);

          fetch('/api/score-weights', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(DEFAULT_WEIGHTS),
          }).catch((err) => {
            console.error('[WeightControls] failed to reset weights', err);
          });
        }}
        className="text-sm underline mt-2"
      >
        Reset to defaults
      </button>
    </div>
  );
}