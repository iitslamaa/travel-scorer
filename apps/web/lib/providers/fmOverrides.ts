


/**
 * Manual overrides for mismatched Frequent Miler country names.
 * Keys must be normalized (lowercase, accents stripped, punctuation removed)
 * using the same normName() logic from frequentmiler.ts.
 */
export const FM_NAME_OVERRIDES: Record<string, string> = {
  "czech republic": "czechia",
  "south korea": "korea, republic of",
  "north korea": "korea, democratic people's republic of",
  "cape verde": "cabo verde",
  "swaziland": "eswatini",
  "burma": "myanmar",
  "myanmar burma": "myanmar",
  "vatican city": "holy see",
  "moldova": "moldova, republic of",
  "russia": "russian federation",
  "laos": "lao people's democratic republic",
  "united states": "united states of america",
  "usa": "united states of america",
  "u.s.a": "united states of america",
  "tanzania": "tanzania, united republic of",
  "congo drc": "congo, the democratic republic of the",
  "congo brazzaville": "congo",
  "united kingdom": "united kingdom of great britain and northern ireland",
  "uk": "united kingdom of great britain and northern ireland",
  "gambia": "gambia, the",
  "bahamas": "bahamas, the",
  "bolivia": "bolivia, plurinational state of",
  "iran": "iran, islamic republic of",
  "syria": "syrian arab republic",
  "venezuela": "venezuela, bolivarian republic of",
  "north macedonia": "macedonia, the former yugoslav republic of",
  "brunei": "brunei darussalam",
  "palestine": "palestine, state of",
  "cote d'ivoire": "côte d’ivoire",
  "ivory coast": "côte d’ivoire",
  "hong kong": "china, hong kong sar",
  "macau": "china, macao sar",
  "timor leste": "timor-leste",
  "eswatini": "eswatini",
};

import {
  COUNTRY_SEASONALITY_DEFINITIONS,
  type CountrySeasonalityDefinition,
} from '../../../../packages/data/src/countrySeasonality';

export type SeasonalityOverride = CountrySeasonalityDefinition;

export const FM_SEASONALITY_OVERRIDES: Record<string, SeasonalityOverride> =
  COUNTRY_SEASONALITY_DEFINITIONS;