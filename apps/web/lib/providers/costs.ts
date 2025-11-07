/**
 * Lightweight affordability helpers.
 * We estimate a daily spend for a hotel traveler by scaling global baselines
 * using country price indexes that already exist in our facts.
 *
 * Inputs are intentionally minimal to avoid importing large shared types here.
 */

export type CostInputs = {
  /** General cost-of-living price index where ~100 ~= global baseline */
  costOfLivingIndex?: number | null;
  /** Food-specific price index where ~100 ~= baseline */
  foodCostIndex?: number | null;
  /** Local currency units per 1 USD (preferred) */
  fxLocalPerUSD?: number | null;
  /** Fallback: local currency units per 1 USD (same semantics as fxLocalPerUSD) */
  usdToLocalRate?: number | null;
  /** Optional: GDP per capita (USD) – currently unused, but kept for future tuning */
  gdpPerCapitaUsd?: number | null;
};

export type DailySpend = {
  /** Estimated daily food spend in USD */
  foodUsd: number;
  /** Estimated daily activities/transit/incidentals in USD */
  activitiesUsd: number;
  /** Mid-range hotel (taxes/fees included) in USD */
  hotelUsd: number;
  /** Sum of the above in USD */
  totalUsd: number;
  /** Indices/baselines used to compute */
  basis: {
    col?: number;
    food?: number;
  };
  /** Free-form notes for UI if we had to fall back or impute */
  notes?: string[];
};

/** Round to nearest dollar with a floor at 0 */
function roundUsd(n: number): number {
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.round(n));
}

/**
 * Pick an FX value if we ever want to convert local → USD explicitly.
 * For now the baseline amounts are already in USD and the indices are
 * relative (unitless), so FX is only kept for future data sources.
 */
function pickFx(f: CostInputs): number | undefined {
  const fx =
    (typeof f.fxLocalPerUSD === 'number' && isFinite(f.fxLocalPerUSD) && f.fxLocalPerUSD! > 0 && f.fxLocalPerUSD!) ??
    (typeof f.usdToLocalRate === 'number' && isFinite(f.usdToLocalRate) && f.usdToLocalRate! > 0 && f.usdToLocalRate!);
  return typeof fx === 'number' && isFinite(fx) && fx > 0 ? fx : undefined;
}

/**
 * Estimate daily spend for a hotel traveler.
 * - Uses simple baselines (USD) that scale with price indices.
 * - foodCostIndex overrides costOfLivingIndex for food if present.
 * - If no indices are available, returns undefined so callers can hide the row.
 */
export function estimateDailySpendHotel(f: CostInputs): DailySpend | undefined {
  const notes: string[] = [];

  const col = typeof f.costOfLivingIndex === 'number' && isFinite(f.costOfLivingIndex) ? f.costOfLivingIndex : undefined;
  const foodIdx = typeof f.foodCostIndex === 'number' && isFinite(f.foodCostIndex) ? f.foodCostIndex : undefined;

  // If we have neither index, we don't compute.
  if (col == null && foodIdx == null) return undefined;

  // Global mid-range traveler baselines (USD) at index = 100.
  // Tunable constants – chosen to feel realistic without external hotel dataset.
  const BASE_FOOD_USD = 25;       // 2–3 inexpensive meals + snacks
  const BASE_ACTIVITIES_USD = 30; // transit, attractions, misc
  const BASE_HOTEL_USD = 70;      // mid-range hotel after taxes/fees

  // Scale helpers: index of 100 → 1.0; cap extremes to avoid wild outliers.
  const scale = (idx?: number) => {
    if (idx == null) return 1;
    const s = idx / 100;
    // clamp to reasonable band
    return Math.min(3, Math.max(0.35, s));
  };

  const foodScale = scale(foodIdx ?? col);
  const genericScale = scale(col);

  const foodUsd = BASE_FOOD_USD * foodScale;
  const activitiesUsd = BASE_ACTIVITIES_USD * genericScale;
  const hotelUsd = BASE_HOTEL_USD * genericScale;

  // Keep FX around for future local→USD conversions if we add local price data.
  const _fx = pickFx(f);
  if (_fx == null) {
    // No FX needed for current model; leave a breadcrumb only.
  }

  const result: DailySpend = {
    foodUsd: roundUsd(foodUsd),
    activitiesUsd: roundUsd(activitiesUsd),
    hotelUsd: roundUsd(hotelUsd),
    totalUsd: roundUsd(foodUsd + activitiesUsd + hotelUsd),
    basis: { col: col ?? undefined, food: foodIdx ?? undefined },
    notes: notes.length ? notes : undefined,
  };

  return result;
}

/**
 * Convenience formatter the UI can use if desired.
 * Example: "$84" (no decimals).
 */
export function fmtUsd(n?: number): string {
  if (typeof n !== 'number' || !isFinite(n)) return '—';
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(n);
}
