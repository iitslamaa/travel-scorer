// packages/shared/src/score.ts
import type { CountryFacts, Weights } from './types';

export const DEFAULT_WEIGHTS: Weights = {
  safety: 0.25,
  affordability: 0.15,
  english: 0.10,
  seasonality: 0.10,
  visa: 0.10,
  flightTime: 0.10,
  transit: 0.10,
  womenSafety: 0.05,
  soloSafety: 0.05,
};

// ---- helpers ----
const clamp01 = (x: number) => Math.max(0, Math.min(1, x));
const pct = (x: number) => clamp01(x) * 100;

const safetyScore = (lvl?: 1 | 2 | 3 | 4) =>
  typeof lvl === 'number' ? pct((5 - lvl) / 4) : 50;

const visaScore = (v?: CountryFacts['visaEaseUS']) => {
  switch (v) {
    case 'visa-free': return 100;
    case 'evisa': return 70;
    case 'visa-required': return 30;
    default: return 50; // unknown
  }
};

const flightScore = (hours?: number) => {
  const h = Math.max(0, Math.min(hours ?? 12, 20)); // cap at 20h
  return pct(1 - h / 20);
};

const transitScore = (t?: CountryFacts['transit']) => {
  switch (t) {
    case 'great-pt': return 100;
    case 'mixed': return 60;
    case 'car-only': return 30;
    default: return 50;
  }
};

const seasonScore = (months: number[] | undefined, month: number) =>
  (months && months.includes(month)) ? 100 : 50;

// ---- main scorer ----
export function computeScoreFromFacts(
  f: CountryFacts,
  w: Weights,
  month: number
): number {
  const safety = safetyScore(f.advisoryLevel);
  const affordability = f.gdpPppPerCapita != null
    ? pct(1 / Math.max(1, f.gdpPppPerCapita / 20000)) // rough inverse curve
    : 50;
  const english = f.englishProficiency ?? 50;
  const seasonality = seasonScore(f.bestMonths, month);
  const visa = visaScore(f.visaEaseUS);
  const flightTime = flightScore(f.estFlightHrsFromNYC);
  const transit = transitScore(f.transit);
  const womenSafety = f.womenSafety ?? 50;
  const soloSafety = f.soloSafety ?? 50;

  const totalW = Object.values(w).reduce((a, b) => a + b, 0) || 1;

  const weighted =
    safety * w.safety +
    affordability * w.affordability +
    english * w.english +
    seasonality * w.seasonality +
    visa * w.visa +
    flightTime * w.flightTime +
    transit * w.transit +
    womenSafety * w.womenSafety +
    soloSafety * w.soloSafety;

  return Math.round(weighted / totalW);
}