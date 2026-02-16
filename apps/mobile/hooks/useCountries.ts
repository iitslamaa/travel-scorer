import { useEffect, useState } from 'react';
import { Country } from '../types/Country';

export function useCountries() {
  const [countries, setCountries] = useState<Country[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchCountries = async () => {
      try {
        const res = await fetch(
          'https://travel-scorer.vercel.app/api/countries'
        );

        const data = await res.json();

        console.log('Countries fetch:', data);

        setCountries(data);
      } catch (error) {
        console.log('Countries fetch error:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchCountries();
  }, []);

  return { countries, loading };
}