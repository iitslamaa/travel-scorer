import { useEffect, useState } from 'react';
import { Country } from '../types/Country';

export function useCountries() {
  const [countries, setCountries] = useState<Country[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchCountries = async () => {
      try {
        console.log('Starting countries fetch...');

        const res = await fetch(
          'https://travel-scorer.vercel.app/api/countries',
          {
            headers: {
              Accept: 'application/json',
            },
          }
        );

        console.log('Fetch response status:', res.status);

        const text = await res.text();
        console.log('Raw response length:', text.length);

        const data = JSON.parse(text);

        console.log('Parsed countries count:', Array.isArray(data) ? data.length : 'not array');

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