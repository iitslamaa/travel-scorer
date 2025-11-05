import type { CountryFacts, Weights } from './types';

export const DEFAULT_WEIGHTS: Weights = {
  advisorySafety: 0.30,
  travelSafe: 0.15,
  soloFemale: 0.10,
  redditComposite: 0.20,
  seasonality: 0.05,
  visaEase: 0.05,
  affordability: 0.05,
  directFlight: 0.05,
  infrastructure: 0.05,
};

// Helper functions
const clamp = (x: number, lo = 0, hi = 100) => Math.max(lo, Math.min(hi, x));
const advisoryToPct = (lvl?: 1 | 2 | 3 | 4) => (!lvl ? 50 : clamp(((5 - lvl) / 4) * 100));
const shrinkReddit = (score: number | undefined, n: number | undefined) => {
  const s = score ?? 50;
  const k = (n ?? 0) >= 300 ? 1 : 0.7;
  return Math.round(k * s + (1 - k) * 50);
};

// Compute final weighted score
export function computeScoreFromFacts(
  f: CountryFacts,
  w: Weights = DEFAULT_WEIGHTS
): number {
  const advisory = advisoryToPct(f.advisoryLevel);
  const ts = f.travelSafeOverall ?? 50;
  const sfti = f.soloFemaleIndex ?? 50;
  const reddit = shrinkReddit(f.redditComposite, f.redditN);
  const season = f.seasonality ?? 50;
  const visa = f.visaEase ?? 50;
  const afford = f.affordability ?? 50;
  const flight = f.directFlight ?? 50;
  const infra = f.infrastructure ?? 50;

  const totalW =
    w.advisorySafety + w.travelSafe + w.soloFemale + w.redditComposite +
    w.seasonality + w.visaEase + w.affordability + w.directFlight + w.infrastructure || 1;

  const weighted =
    advisory * w.advisorySafety +
    ts * w.travelSafe +
    sfti * w.soloFemale +
    reddit * w.redditComposite +
    season * w.seasonality +
    visa * w.visaEase +
    afford * w.affordability +
    flight * w.directFlight +
    infra * w.infrastructure;

  return Math.round(weighted / totalW);
}