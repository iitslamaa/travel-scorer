import { View, Text, StyleSheet } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useCountries } from '../../hooks/useCountries';

export default function CountryDetailScreen() {
  const { iso2 } = useLocalSearchParams();
  const { countries } = useCountries();

  const country = countries.find(c => c.iso2 === iso2);

  if (!country) return null;

  return (
    <View style={styles.container}>
      <Text style={styles.title}>{country.name}</Text>
      <Text style={styles.score}>
        Score: {country.facts?.scoreTotal}
      </Text>
      <Text style={styles.level}>
        Level {country.facts?.advisoryLevel}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24 },
  title: { fontSize: 28, fontWeight: '700', marginBottom: 12 },
  score: { fontSize: 18, marginBottom: 8 },
  level: { fontSize: 16, color: '#666' },
});