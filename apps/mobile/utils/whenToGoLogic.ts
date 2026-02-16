import { Country } from '../types/Country';

export type WhenToGoItem = {
  iso2: string;
  name: string;
  region: string;
  score: number;
};

function normalizeMonth(m: number) {
  // API uses 1-12
  return m - 1; // convert to 0-11
}

function getShoulderMonths(bestMonths: number[]) {
  const shoulders = new Set<number>();

  bestMonths.forEach(m => {
    const zero = normalizeMonth(m);

    const before = (zero - 1 + 12) % 12;
    const after = (zero + 1) % 12;

    shoulders.add(before);
    shoulders.add(after);
  });

  return shoulders;
}

export function getWhenToGoBuckets(
  countries: Country[],
  selectedMonth0: number
) {
  const peak: WhenToGoItem[] = [];
  const shoulder: WhenToGoItem[] = [];

  countries.forEach(c => {
    const bestMonths: number[] =
      c.facts?.fmSeasonalityBestMonths ?? [];

    if (!bestMonths.length) return;

    const normalizedBest = bestMonths.map(normalizeMonth);
    const shoulderMonths = getShoulderMonths(bestMonths);

    const isPeak = normalizedBest.includes(selectedMonth0);
    const isShoulder =
      shoulderMonths.has(selectedMonth0) &&
      !isPeak;

    if (isPeak) {
      peak.push({
        iso2: c.iso2,
        name: c.name,
        region: c.region ?? '',
        score: c.facts?.scoreTotal ?? 0,
      });
    } else if (isShoulder) {
      shoulder.push({
        iso2: c.iso2,
        name: c.name,
        region: c.region ?? '',
        score: c.facts?.scoreTotal ?? 0,
      });
    }
  });

  // Sort by real scoreTotal descending
  peak.sort((a, b) => b.score - a.score);
  shoulder.sort((a, b) => b.score - a.score);

  return { peak, shoulder };
}