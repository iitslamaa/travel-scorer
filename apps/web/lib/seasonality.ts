import {
  getCountriesForMonth,
  type MonthNumber,
  type CountrySeasonality,
} from "../../../packages/data/src/seasonality";

/**
 * Shared seasonality computation.
 * This is the SAME logic used by the web SeasonalityExplorer,
 * now exposed for API + iOS consumption.
 */
export function computeSeasonality(month: number) {
  const m = month as MonthNumber;

  const { peak, shoulder } = getCountriesForMonth(m);

  return {
    month: m,
    peakCountries: peak.map((c: CountrySeasonality) => ({
      isoCode: c.isoCode,
      name: c.name,
    })),
    shoulderCountries: shoulder.map((c: CountrySeasonality) => ({
      isoCode: c.isoCode,
      name: c.name,
    })),
    notes: null,
  };
}
