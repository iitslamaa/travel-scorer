import { View, Text, ScrollView } from 'react-native';
import type { CountryRow } from '@travel-af/data';

function formatDate(iso?: string) {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}
function flagEmoji(iso2: string) {
  return iso2.slice(0,2).toUpperCase().replace(/./g, c => String.fromCodePoint(127397 + c.charCodeAt(0)));
}

function Bar({ value }: { value: number }) {
  const v = Math.max(0, Math.min(100, value));
  return (
    <View style={{ height: 10, borderRadius: 6, backgroundColor: 'rgba(0,0,0,0.12)' }}>
      <View style={{ height: 10, borderRadius: 6, width: `${v}%` }} />
    </View>
  );
}

function toDisplayKey(k: string) {
  return k
    .replace(/([A-Z])/g, ' $1')
    .replace(/_/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/^./, (c) => c.toUpperCase());
}

export function CountryDetails({ country }: { country: CountryRow }) {
  const categories: Array<{ key: string; value: number }> = [];
  if (country.facts) {
    for (const [k, v] of Object.entries(country.facts)) {
      if (typeof v === 'number' && k !== 'redditN' && k !== 'scoreTotal') {
        categories.push({ key: k, value: v });
      }
    }
  }
  categories.sort((a, b) => b.value - a.value);

  return (
    <ScrollView contentContainerStyle={{ padding: 16 }}>
      {/* Header */}
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
        <Text style={{ fontSize: 32 }}>{flagEmoji(country.iso2)}</Text>
        <Text style={{ fontSize: 28, fontWeight: '800' }}>{country.name}</Text>
      </View>

      {/* Score badge */}
      <View
        style={{
          alignSelf: 'flex-start',
          marginTop: 8,
          paddingHorizontal: 10,
          paddingVertical: 6,
          borderRadius: 999,
          backgroundColor: '#EFEAE6',
          borderWidth: 1,
          borderColor: '#E2DED6'
        }}
      >
        <Text style={{ fontSize: 14, fontWeight: '700' }}>Score {country.score}</Text>
      </View>

      {/* Meta */}
      <Text style={{ fontSize: 16, marginTop: 10 }}>ISO2: {country.iso2}</Text>
      {country.n ? <Text style={{ fontSize: 14, marginTop: 6, opacity: 0.7 }}>n={country.n}</Text> : null}
      {country.updatedAt ? (
        <Text style={{ fontSize: 14, marginTop: 2, opacity: 0.7 }}>
          Updated: {formatDate(country.updatedAt)}
        </Text>
      ) : null}

      {/* Categories */}
      {categories.length > 0 && (
        <View style={{ marginTop: 18 }}>
          <Text style={{ fontSize: 18, fontWeight: '700', marginBottom: 8 }}>Categories</Text>
          <View style={{ gap: 12 }}>
            {categories.map(({ key, value }) => (
              <View key={key}>
                <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 }}>
                  <Text style={{ fontSize: 14 }}>{toDisplayKey(key)}</Text>
                  <Text style={{ fontSize: 14 }}>{Math.round(value)}</Text>
                </View>
                <Bar value={value} />
              </View>
            ))}
          </View>
        </View>
      )}

      {/* Advisory */}
      {(country.advisory?.headline || country.advisory?.level) && (
        <View style={{ marginTop: 18 }}>
          <Text style={{ fontSize: 18, fontWeight: '700', marginBottom: 6 }}>Travel Advisory</Text>
          {country.advisory?.headline ? <Text style={{ fontSize: 16 }}>{country.advisory.headline}</Text> : null}
          {country.advisory?.level ? (
            <Text style={{ fontSize: 14, opacity: 0.8, marginTop: 4 }}>{country.advisory.level}</Text>
          ) : null}
          {country.advisory?.updatedAt ? (
            <Text style={{ fontSize: 12, opacity: 0.6, marginTop: 2 }}>
              Updated: {formatDate(country.advisory.updatedAt)}
            </Text>
          ) : null}
        </View>
      )}

      {/* Explanation */}
      {country.explanation ? (
        <View style={{ marginTop: 18 }}>
          <Text style={{ fontSize: 18, fontWeight: '700', marginBottom: 6 }}>Why this score</Text>
          <Text style={{ fontSize: 16, lineHeight: 22 }}>{country.explanation}</Text>
        </View>
      ) : null}

      <View style={{ height: 24 }} />
    </ScrollView>
  );
}