import {
  ScrollView,
  useColorScheme,
} from 'react-native';
import { useLocalSearchParams, useNavigation } from 'expo-router';
import { useCountries } from '../../../hooks/useCountries';
import { useEffect, useMemo } from 'react';
import HeaderCard from './components/HeaderCard';
import AdvisoryCard from './components/AdvisoryCard';
import SeasonalityCard from './components/SeasonalityCard';
import VisaCard from './components/VisaCard';
import { lightColors, darkColors } from '../../../theme/colors';

export default function CountryDetailScreen() {
  const { iso2 } = useLocalSearchParams<{ iso2: string }>();
  const navigation = useNavigation();
  const { countries } = useCountries();

  const scheme = useColorScheme();
  const colors = scheme === 'dark' ? darkColors : lightColors;

  const country = useMemo(() => {
    return countries?.find?.(c => c.iso2 === iso2);
  }, [countries, iso2]);

  useEffect(() => {
    if (!country?.name) return;

    navigation.setOptions({
      title: country.name,
    });
  }, [navigation, country?.name]);

  if (!countries) return null;
  if (!country) return null;
  console.log('FLAG EMOJI:', (country as any).flagEmoji);

  const score = country.facts?.scoreTotal ?? 0;
  const advisoryLevel = country.facts?.advisoryLevel ?? '—';

  const advisoryScore =
    country.facts?.advisoryScore ??
    country.facts?.advisoryNormalized ??
    country.facts?.advisoryWeighted ??
    0;

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: colors.background }}
      contentContainerStyle={{ padding: 16 }}
    >
      <HeaderCard
        name={country.name}
        subregion={(country as any).subregion}
        region={country.region}
        score={score}
        flagEmoji={(country as any).flagEmoji}
      />

      <AdvisoryCard
        score={advisoryScore}
        level={advisoryLevel}
        summary={country.facts?.advisorySummary}
        url={country.facts?.advisoryUrl}
        updatedAtLabel={
          (country as any).advisory?.updatedAt
            ? `Last updated: ${(country as any).advisory.updatedAt}`
            : undefined
        }
        normalizedLabel={`Normalized: ${advisoryScore}`}
        weightOnlyLabel={'Weight: 10%'}
      />

      <SeasonalityCard
        score={country.facts?.seasonality ?? 0}
        bestMonths={country.facts?.fmSeasonalityBestMonths ?? []}
        description={country.facts?.fmSeasonalityNotes}
        normalizedLabel={`Normalized: ${country.facts?.seasonality ?? 0}`}
        weightOnlyLabel={'Weight: 5%'}
      />

      <VisaCard
        score={country.facts?.visaEase ?? 0}
        visaType={country.facts?.visaType}
        allowedDays={country.facts?.visaAllowedDays}
        notes={country.facts?.visaNotes}
        sourceUrl={country.facts?.visaSource}
        normalizedLabel={`Normalized: ${country.facts?.visaEase ?? 0}`}
        weightOnlyLabel={'Weight: 5%'}
      />
    </ScrollView>
  );
}