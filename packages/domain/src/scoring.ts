// packages/domain/src/scoring.ts

import type { CountryFacts } from '@travel-af/shared';

// --- Weights (sum = 1.0)
export const W = {
  travelGov: 0.30,
  travelSafe: 0.15,
  sfti: 0.10,
  reddit: 0.20,
  seasonality: 0.05,
  visa: 0.05,
  affordability: 0.05,
  directFlight: 0.05,
  infrastructure: 0.05,
} as const;

export const DEFAULT_WEIGHTS = W;

export type FactRow = {
  key: keyof typeof W;
  label: string;
  raw?: number;   // 0..100
  weight: number; // original weight (0..1)
  contrib: number; // raw * (weight / sumPresentWeights)
};

// --- Internal helpers (pure math only)

function clamp01(x: number) {
  return Math.max(0, Math.min(1, x));
}

function toNumber(x: unknown): number | undefined {
  const n = Number(x);
  return Number.isFinite(n) ? n : undefined;
}

function scaleTo100(value: number, min: number, max: number, invert = false) {
  if (min === max) return 50;
  const t = clamp01((value - min) / (max - min));
  const y = invert ? 1 - t : t;
  return Math.round(y * 100);
}

// --- Affordability derivation (pure scoring logic only)

type FactsExtra = CountryFacts & {
  costOfLivingIndex?: number;
  foodCostIndex?: number;
  gdpPerCapitaUsd?: number;
  fxLocalPerUSD?: number;
  localPerUSD?: number;
  usdToLocalRate?: number;
  affordability?: number;
};

export function computeAffordability(
  facts: FactsExtra
): number | undefined {
  const col = toNumber(facts.costOfLivingIndex);
  const food = toNumber(facts.foodCostIndex);
  const gdp = toNumber(facts.gdpPerCapitaUsd);
  const fxLocalPerUsd = toNumber(
    facts.fxLocalPerUSD ?? facts.localPerUSD ?? facts.usdToLocalRate
  );

  const parts: number[] = [];

  if (col != null) parts.push(scaleTo100(col, 30, 120, true));
  if (food != null) parts.push(scaleTo100(food, 20, 200, true));
  if (gdp != null) parts.push(scaleTo100(gdp, 2000, 80000, true));
  if (fxLocalPerUsd != null)
    parts.push(scaleTo100(fxLocalPerUsd, 0.2, 400, false));

  if (parts.length === 0) return 50;

  return Math.round(parts.reduce((a, b) => a + b, 0) / parts.length);
}

// --- Advisory mapping

function advisoryToScore(level?: 1 | 2 | 3 | 4) {
  if (!level) return 50;
  return ((5 - level) / 4) * 100;
}

// --- Main scoring engine

export function buildRows(
  facts: CountryFacts
): { rows: FactRow[]; total: number } {
  const fx = facts as FactsExtra;

  const signals: {
    key: FactRow['key'];
    label: string;
    value?: number;
  }[] = [
    {
      key: 'travelGov',
      label: 'Travel.gov advisory',
      value: advisoryToScore(facts.advisoryLevel),
    },
    {
      key: 'travelSafe',
      label: 'TravelSafe Abroad',
      value: facts.travelSafeOverall,
    },
    {
      key: 'sfti',
      label: 'Solo Female Travelers',
      value: facts.soloFemaleIndex,
    },
    {
      key: 'reddit',
      label: 'Reddit sentiment',
      value: facts.redditComposite,
    },
    {
      key: 'seasonality',
      label: 'Seasonality (now)',
      value: facts.seasonality,
    },
    {
      key: 'visa',
      label: 'Visa ease (US passport)',
      value: facts.visaEase,
    },
    {
      key: 'affordability',
      label: 'Affordability',
      value:
        fx.affordability ??
        computeAffordability(fx),
    },
    {
      key: 'directFlight',
      label: 'Direct flight',
      value: facts.directFlight,
    },
    {
      key: 'infrastructure',
      label: 'Tourist infrastructure',
      value: facts.infrastructure,
    },
  ];

  // Only count weights for present signals
  const presentWeightSum = signals
    .filter((s) => Number.isFinite(s.value))
    .reduce((acc, s) => acc + (W[s.key] ?? 0), 0);

  const rows: FactRow[] = signals.map((s) => {
    const raw = Number.isFinite(s.value as number)
      ? (s.value as number)
      : undefined;

    const w = W[s.key] ?? 0;
    const effW = presentWeightSum > 0 ? w / presentWeightSum : 0;

    const contrib = raw != null ? raw * effW : 0;

    return {
      key: s.key,
      label: s.label,
      raw,
      weight: w,
      contrib,
    };
  });

  const total = Math.round(
    rows.reduce((a, r) => a + r.contrib, 0)
  );

  return { rows, total };
}