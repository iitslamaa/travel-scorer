// packages/data/src/seasonality.ts

export type MonthNumber =
  | 1 | 2 | 3 | 4 | 5 | 6
  | 7 | 8 | 9 | 10 | 11 | 12;

export type SeasonType = 'peak' | 'shoulder' | 'off';

export interface CountrySeasonality {
  isoCode: string; // 'EG', 'TH'
  name: string;    // 'Egypt', 'Thailand'
  region: string;  // 'North Africa', 'Southeast Asia', etc.
  months: Record<MonthNumber, SeasonType>;
}

// You’ll replace this with real data later
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

export const SEASONALITY_DATA: CountrySeasonality[] = [
  {
    isoCode: 'EG',
    name: 'Egypt',
    region: 'North Africa',
    months: {
      1: 'peak',
      2: 'peak',
      3: 'shoulder',
      4: 'shoulder',
      5: 'off',
      6: 'off',
      7: 'off',
      8: 'off',
      9: 'shoulder',
      10: 'peak',
      11: 'peak',
      12: 'peak',
    },
  },
  {
    isoCode: 'TH',
    name: 'Thailand',
    region: 'Southeast Asia',
    months: {
      1: 'peak',
      2: 'peak',
      3: 'peak',
      4: 'shoulder',
      5: 'off',
      6: 'off',
      7: 'off',
      8: 'off',
      9: 'shoulder',
      10: 'peak',
      11: 'peak',
      12: 'peak',
    },
  },
  {
    isoCode: 'OM',
    name: 'Oman',
    region: 'Gulf',
    months: {
      1: 'peak',
      2: 'peak',
      3: 'peak',
      4: 'shoulder',
      5: 'off',
      6: 'off',
      7: 'off',
      8: 'off',
      9: 'off',
      10: 'shoulder',
      11: 'peak',
      12: 'peak',
    },
  },
];

export function getCountriesForMonth(month: MonthNumber) {
  const peak = SEASONALITY_DATA.filter((c) => c.months[month] === 'peak');
  const shoulder = SEASONALITY_DATA.filter((c) => c.months[month] === 'shoulder');
  return { peak, shoulder };
}