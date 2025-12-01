// packages/data/src/seasonality.ts

import {
  COUNTRY_SEASONALITY_DEFINITIONS,
  type CountrySeasonalityDefinition,
} from './countrySeasonality';

export type MonthNumber =
  | 1
  | 2
  | 3
  | 4
  | 5
  | 6
  | 7
  | 8
  | 9
  | 10
  | 11
  | 12;

export type SeasonBand = 'peak' | 'shoulder' | 'off';

export interface CountrySeasonality {
  isoCode: string;
  name: string; // temporary, we’ll override with real name in the web app
  months: Record<MonthNumber, SeasonBand>;
}

export const ALL_MONTHS: { value: MonthNumber; label: string; short: string }[] = [
  { value: 1, label: 'January', short: 'Jan' },
  { value: 2, label: 'February', short: 'Feb' },
  { value: 3, label: 'March', short: 'Mar' },
  { value: 4, label: 'April', short: 'Apr' },
  { value: 5, label: 'May', short: 'May' },
  { value: 6, label: 'June', short: 'Jun' },
  { value: 7, label: 'July', short: 'Jul' },
  { value: 8, label: 'August', short: 'Aug' },
  { value: 9, label: 'September', short: 'Sep' },
  { value: 10, label: 'October', short: 'Oct' },
  { value: 11, label: 'November', short: 'Nov' },
  { value: 12, label: 'December', short: 'Dec' },
];

function buildMonths(
  def: CountrySeasonalityDefinition
): Record<MonthNumber, SeasonBand> {
  const months: Record<MonthNumber, SeasonBand> = {
    1: 'off',
    2: 'off',
    3: 'off',
    4: 'off',
    5: 'off',
    6: 'off',
    7: 'off',
    8: 'off',
    9: 'off',
    10: 'off',
    11: 'off',
    12: 'off',
  };

  const toMonthArray = (arr?: number[]): MonthNumber[] =>
    (arr ?? []) as MonthNumber[];

  // best → peak
  for (const m of toMonthArray(def.best)) {
    months[m] = 'peak';
  }

  // shoulder → shoulder (don’t override peak)
  for (const m of toMonthArray(def.shoulder)) {
    if (months[m] !== 'peak') {
      months[m] = 'shoulder';
    }
  }

  // good → shoulder if still off
  for (const m of toMonthArray(def.good)) {
    if (months[m] === 'off') {
      months[m] = 'shoulder';
    }
  }

  // avoid: we just leave as "off" – not needed for this view

  return months;
}

export const SEASONALITY_DATA: CountrySeasonality[] = Object.entries(
  COUNTRY_SEASONALITY_DEFINITIONS
).map(([isoCode, def]) => {
  const definition = def as CountrySeasonalityDefinition;

  return {
    isoCode,
    // placeholder; web will join real name later
    name: isoCode,
    months: buildMonths(definition),
  };
});

export function getCountriesForMonth(month: MonthNumber) {
  const peak = SEASONALITY_DATA.filter((c) => c.months[month] === 'peak');
  const shoulder = SEASONALITY_DATA.filter((c) => c.months[month] === 'shoulder');

  return { peak, shoulder };
}