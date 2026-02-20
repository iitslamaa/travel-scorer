'use client';

import { useEffect, useState } from 'react';
import type { ScoreWeights } from '@travel-af/domain/src/scoring';
import { normalizeWeights, loadWeights, saveWeights, DEFAULT_WEIGHTS } from '@/lib/scoreWeights';

type Props = {
  onChange: (weights: ScoreWeights) => void;
};

export default function WeightControls({ onChange }: Props) {
  const [weights, setWeights] = useState<ScoreWeights>(DEFAULT_WEIGHTS);

  useEffect(() => {
    const stored = loadWeights();
    setWeights(stored);
    onChange(stored);
  }, []);

  function update(key: keyof ScoreWeights, value: number) {
    const updated = normalizeWeights({
      ...weights,
      [key]: value,
    });

    setWeights(updated);
    saveWeights(updated);
    onChange(updated);
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
          saveWeights(DEFAULT_WEIGHTS);
          onChange(DEFAULT_WEIGHTS);
        }}
        className="text-sm underline mt-2"
      >
        Reset to defaults
      </button>
    </div>
  );
}