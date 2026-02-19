import { useCallback, useMemo, useState } from 'react';
import { useCountries } from './useCountries';

export type Country = {
  code: string;
  name: string;
  flagEmoji?: string;
  score?: number;
};

export function useVisitedList() {
  const [visitedCodes, setVisitedCodes] = useState<string[]>([]);
  const { countries } = useCountries();

  const isVisited = useCallback(
    (code: string) => visitedCodes.includes(code),
    [visitedCodes]
  );

  const toggleVisited = useCallback((country: Country) => {
    setVisitedCodes((prev) => {
      if (prev.includes(country.code)) {
        return prev.filter((c) => c !== country.code);
      }
      return [...prev, country.code];
    });

    // 🔜 TODO: Persist to Supabase user profile (traveledCountries field)
  }, []);

  const visitedCountries = useMemo(() => {
    return countries
      .filter((country) => visitedCodes.includes(country.iso2))
      .map((country) => ({
        code: country.iso2,
        name: country.name,
        flagEmoji: country.flagEmoji,
        score: country.facts?.scoreTotal,
      }));
  }, [countries, visitedCodes]);

  return {
    visitedCodes,
    visitedCountries,
    isVisited,
    toggleVisited,
  };
}