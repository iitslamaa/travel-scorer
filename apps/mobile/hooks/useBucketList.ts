import { useCallback, useMemo, useState } from 'react';
import { useCountries } from './useCountries';

export type Country = {
  code: string;
  name: string;
  flagEmoji?: string;
  score?: number;
};

export function useBucketList() {
  const [bucketCodes, setBucketCodes] = useState<string[]>([]);
  const { countries } = useCountries();

  const isBucketed = useCallback(
    (code: string) => bucketCodes.includes(code),
    [bucketCodes]
  );

  const toggleBucket = useCallback((country: Country) => {
    setBucketCodes((prev) => {
      if (prev.includes(country.code)) {
        return prev.filter((c) => c !== country.code);
      }
      return [...prev, country.code];
    });

    // 🔜 TODO: Persist to Supabase user profile (bucketList field)
  }, []);

  const bucketCountries = useMemo(() => {
    return countries
      .filter((country) => bucketCodes.includes(country.iso2))
      .map((country) => ({
        code: country.iso2,
        name: country.name,
        flagEmoji: country.flagEmoji,
        score: country.facts?.scoreTotal,
      }));
  }, [countries, bucketCodes]);

  return {
    bucketCodes,
    bucketCountries,
    isBucketed,
    toggleBucket,
  };
}