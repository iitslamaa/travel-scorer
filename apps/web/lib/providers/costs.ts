/**
 * Lightweight affordability helpers.
 * We estimate a daily spend for a hotel traveler by scaling global baselines
 * using country price indexes that already exist in our facts.
 *
 * Inputs are intentionally minimal to avoid importing large shared types here.
 */

import { DAILY_COSTS } from "@/data/sources/daily_costs";

export type CostInputs = {
  /** General cost-of-living price index where ~100 ~= global baseline */
  costOfLivingIndex?: number | null;
  /** Food-specific price index where ~100 ~= baseline */
  foodCostIndex?: number | null;
  /** Housing / lodging price index where ~100 ~= baseline */
  housingCostIndex?: number | null;
  /** Local transport price index where ~100 ~= baseline */
  transportCostIndex?: number | null;

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
  /** Estimated daily local transport in USD */
  transportUsd: number;
  /** Estimated daily activities/incidentals in USD (excl. transport) */
  activitiesUsd: number;
  /** Mid-range hotel (taxes/fees included) in USD */
  hotelUsd: number;
  /** Approximate budget hostel bed (nightly, USD) */
  hostelUsd?: number;
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

  const col =
    typeof f.costOfLivingIndex === "number" && isFinite(f.costOfLivingIndex)
      ? f.costOfLivingIndex
      : undefined;

  const foodIdx =
    typeof f.foodCostIndex === "number" && isFinite(f.foodCostIndex)
      ? f.foodCostIndex
      : undefined;

  const housingIdx =
    typeof f.housingCostIndex === "number" &&
    isFinite(f.housingCostIndex)
      ? f.housingCostIndex
      : undefined;

  const transportIdx =
    typeof f.transportCostIndex === "number" &&
    isFinite(f.transportCostIndex)
      ? f.transportCostIndex
      : undefined;

  // NOTE: We deliberately ignore FX and GDP in this helper for now.
  // The ICP price level index (`col` in our facts) already encodes
  // relative price differences across countries, and adding extra
  // nudges on top made some destinations (islands, very low‑GDP
  // countries) behave in surprising ways. If we later find a
  // principled adjustment, we can reintroduce FX/GDP here.

  // Global mid-range traveler baselines (USD) at index = 100.
  // Tunable constants – chosen to feel realistic without external hotel dataset.
  const BASE_FOOD_USD = 25; // 2–3 inexpensive meals + snacks
  const BASE_TRANSPORT_USD = 15; // public transit / local transport
  const BASE_ACTIVITIES_USD = 15; // attractions, extras, misc
  const BASE_HOTEL_USD = 70; // mid-range hotel after taxes/fees

  // Scale helpers:
  // - If the index is small (≤ 3), treat it as a relative multiplier from ICP (0.2–1.2 etc.)
  //   and normalize around a baseline of ~0.6.
  // - If the index is larger, treat it as a 0–200 style score where 100 ≈ baseline.
  // Then clamp to a reasonable band so we avoid crazy outliers.
  const scale = (idx?: number) => {
    if (idx == null) return 1;

    let s: number;
    if (idx <= 3) {
      // ICP-style relative index (e.g. 0.25, 0.6, 1.1) where
      // the World Bank global average is roughly ~0.6.
      const baseline = 0.6; // ~"typical" price level
      s = idx / baseline;   // 0.6 → 1.0, 0.3 → 0.5, 1.2 → 2.0, 1.5 → 2.5
    } else {
      // 0–200 style numeric index, 100 ≈ baseline
      s = idx / 100;
    }

    // Clamp to a sensible range so even the cheapest destinations
    // still have a non-zero cost, and the most expensive ones don't
    // blow up the scale completely.
    return Math.min(3, Math.max(0.4, s));
  };

  const colScale = scale(col);

  // Sector-specific scales fall back to COL if their own index is missing.
  const foodScale = scale(foodIdx ?? col);
  const housingScale = scale(housingIdx ?? col);
  const transportScale = scale(transportIdx ?? col);

  // Activities: use a generic COL-based scale.
  const activitiesScale = colScale;

  const foodUsd = BASE_FOOD_USD * foodScale;
  const transportUsd = BASE_TRANSPORT_USD * transportScale;
  const activitiesUsd = BASE_ACTIVITIES_USD * activitiesScale;
  const hotelUsd = BASE_HOTEL_USD * housingScale;

  // Derive a simple budget hostel estimate as a fraction of hotel cost.
  const hostelUsd = hotelUsd * 0.4;

  const result: DailySpend = {
    foodUsd: roundUsd(foodUsd),
    transportUsd: roundUsd(transportUsd),
    activitiesUsd: roundUsd(activitiesUsd),
    hotelUsd: roundUsd(hotelUsd),
    hostelUsd: roundUsd(hostelUsd),
    totalUsd: roundUsd(foodUsd + transportUsd + activitiesUsd + hotelUsd),
    basis: { col: col ?? undefined, food: foodIdx ?? undefined },
    notes: notes.length ? notes : undefined,
  };

  return result;
}

export async function buildCostIndex(): Promise<Map<string, DailySpend>> {
  const map = new Map<string, DailySpend>();

  for (const [iso2Raw, entry] of Object.entries(DAILY_COSTS)) {
    const iso2 = iso2Raw.toUpperCase();

    const foodUsd = roundUsd(entry.foodUsd);
    const transportUsd = roundUsd(entry.transportUsd);
    const activitiesUsd = roundUsd(entry.activitiesUsd);
    const hotelUsd = roundUsd(entry.hotelUsd);
    const hostelUsd = entry.hostelUsd != null
      ? roundUsd(entry.hostelUsd)
      : roundUsd(entry.hotelUsd * 0.4);

    const totalUsd = roundUsd(foodUsd + transportUsd + activitiesUsd + hotelUsd);

    map.set(iso2, {
      foodUsd,
      transportUsd,
      activitiesUsd,
      hotelUsd,
      hostelUsd,
      totalUsd,
      basis: {},
      notes: ["Direct daily cost seed"],
    });
  }

  return map;
}
/**
 * Convenience formatter the UI can use if desired.
 * Example: "$84" (no decimals).
 */
export function fmtUsd(n?: number): string {
  if (typeof n !== 'number' || !isFinite(n)) return '—';
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(n);
}
