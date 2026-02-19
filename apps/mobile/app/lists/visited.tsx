import { View, Text, StyleSheet, useColorScheme, FlatList } from 'react-native';
import { useMemo } from 'react';
import AuthGate from '../../components/AuthGate';
import { useAuth } from '../../context/AuthContext';
import { useCountries } from '../../hooks/useCountries';

function getScoreColor(score: number) {
  if (score >= 80) return '#4CAF50';
  if (score >= 60) return '#FBC02D';
  return '#E57373';
}

export default function VisitedListScreen() {
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';

  const backgroundColor = isDark ? '#000000' : '#FFFFFF';
  const textColor = isDark ? '#FFFFFF' : '#111827';
  const subTextColor = isDark ? '#9CA3AF' : '#6B7280';
  const borderColor = isDark ? '#1F2937' : '#E5E7EB';

  const { visitedIsoCodes } = useAuth();
  const { countries } = useCountries();

  const visitedCountries = useMemo(() => {
    return countries
      .filter((country) => visitedIsoCodes.includes(country.iso2))
      .map((country) => ({
        code: country.iso2,
        name: country.name,
        flagEmoji: country.flagEmoji,
        score: country.facts?.scoreTotal,
      }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }, [countries, visitedIsoCodes]);

  return (
    <AuthGate>
      <View style={[styles.container, { backgroundColor }]}>
        <Text style={[styles.header, { color: textColor }]}>✅ Visited</Text>

        {visitedCountries.length === 0 ? (
          <Text style={{ color: subTextColor }}>
            No visited countries yet. Tap the check icon on a country to add it here.
          </Text>
        ) : (
          <FlatList
            data={visitedCountries}
            keyExtractor={(item) => item.code}
            ItemSeparatorComponent={() => (
              <View style={[styles.separator, { backgroundColor: borderColor }]} />
            )}
            renderItem={({ item }) => {
              const score = item.score ?? 0;
              const color = getScoreColor(score);

              return (
                <View style={styles.row}>
                  <Text style={[styles.countryName, { color: textColor }]}>
                    {item.flagEmoji ?? ''} {item.name}
                  </Text>

                  <View style={[styles.scorePill, { backgroundColor: `${color}20` }]}>
                    <Text style={[styles.scoreText, { color }]}>{score}</Text>
                  </View>
                </View>
              );
            }}
          />
        )}
      </View>
    </AuthGate>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 40,
  },
  header: {
    fontSize: 24,
    fontWeight: '600',
    marginBottom: 24,
  },
  row: {
    paddingVertical: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  countryName: {
    fontSize: 16,
    fontWeight: '500',
  },
  scorePill: {
    borderRadius: 20,
    paddingHorizontal: 14,
    paddingVertical: 6,
  },
  scoreText: {
    fontWeight: '600',
    fontSize: 14,
  },
  separator: {
    height: 1,
  },
});