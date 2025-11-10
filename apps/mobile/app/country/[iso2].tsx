import { Stack, useLocalSearchParams } from 'expo-router';
import { useEffect, useMemo, useState } from 'react';
import { ActivityIndicator, SafeAreaView, Text, View } from 'react-native';
import { getCountryByIso2, type CountryRow } from '@travel-af/data';
import { CountryDetails } from '@travel-af/ui';

const BASE = process.env.EXPO_PUBLIC_WEB_BASE_URL ?? '';

function isNonEmpty(s?: string | null) {
  return typeof s === 'string' && s.trim().length > 0;
}

export default function CountryScreen() {
  const { iso2 } = useLocalSearchParams<{ iso2: string }>();
  const code = typeof iso2 === 'string' ? iso2.toUpperCase() : '';

  // Base row from local SSOT snapshot
  const base = useMemo(() => (code ? getCountryByIso2(code) : undefined), [code]);

  // Rich row fetched from your web API
  const [rich, setRich] = useState<CountryRow | undefined>(undefined);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      if (!BASE || !code) {
        setRich(undefined);
        return;
      }
      try {
        setLoading(true);

        // Normalize the base URL without trailing slash (avoid regex issues)
        const baseNormalized = BASE.endsWith('/') ? BASE.slice(0, -1) : BASE;
        const url = `${baseNormalized}/api/country/${code}`;

        const res = await fetch(url);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();

        // Merge API data with base row; support a few alias keys
        const merged: CountryRow = {
          iso2: code,
          name: isNonEmpty(data.name) ? data.name : base?.name ?? code,
          score: typeof data.score === 'number' ? data.score : base?.score ?? 0,
          n: typeof data.n === 'number' ? data.n : base?.n,
          updatedAt: data.updatedAt ?? base?.updatedAt,
          facts: data.facts ?? data.categories ?? base?.facts,
          advisory: data.advisory,
          explanation: data.explanation ?? data.summary,
        };

        if (!cancelled) setRich(merged);
      } catch (_e) {
        // Network or API error — fall back to base
        if (!cancelled) setRich(undefined);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    load();
    return () => {
      cancelled = true;
    };
  }, [BASE, code, base?.name, base?.score, base?.n, base?.updatedAt, base?.facts]);

  const countryToShow: CountryRow | undefined = rich ?? base;

  if (!countryToShow) {
    return (
      <SafeAreaView style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: 16 }}>
        <Text style={{ fontSize: 16 }}>Country not found.</Text>
      </SafeAreaView>
    );
  }

  return (
    <>
      <Stack.Screen
        options={{
          title: countryToShow.name,
          headerRight: () =>
            loading ? (
              <View style={{ paddingRight: 12 }}>
                <ActivityIndicator />
              </View>
            ) : null
        }}
      />
      <SafeAreaView style={{ flex: 1 }}>
        <CountryDetails country={countryToShow} />
      </SafeAreaView>
    </>
  );
}