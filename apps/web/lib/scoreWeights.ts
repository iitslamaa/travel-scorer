import type { ScoreWeights } from '@travel-af/domain/src/scoring';

export const DEFAULT_WEIGHTS: ScoreWeights = {
  travelGov: 0.4,
  seasonality: 0.2,
  visa: 0.2,
  affordability: 0.2,
};

export function normalizeWeights(
  weights: Partial<ScoreWeights>
): ScoreWeights {
  const merged = { ...DEFAULT_WEIGHTS, ...weights };

  const sum =
    merged.travelGov +
    merged.seasonality +
    merged.visa +
    merged.affordability;

  if (sum === 0) return DEFAULT_WEIGHTS;

  return {
    travelGov: merged.travelGov / sum,
    seasonality: merged.seasonality / sum,
    visa: merged.visa / sum,
    affordability: merged.affordability / sum,
  };
}

export function loadWeights(): ScoreWeights {
  if (typeof window === 'undefined') return DEFAULT_WEIGHTS;

  const raw = localStorage.getItem('travelScoreWeights');
  if (!raw) return DEFAULT_WEIGHTS;

  try {
    return normalizeWeights(JSON.parse(raw));
  } catch {
    return DEFAULT_WEIGHTS;
  }
}

export function saveWeights(weights: ScoreWeights) {
  if (typeof window === 'undefined') return;
  localStorage.setItem(
    'travelScoreWeights',
    JSON.stringify(weights)
  );
}