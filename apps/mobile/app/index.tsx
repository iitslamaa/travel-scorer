import { Link } from 'expo-router';
import { useMemo, useState, useCallback } from 'react';
import { FlatList, RefreshControl, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { countries as allCountries, searchCountries } from '@travel-af/data';

export default function HomeScreen() {
  const [query, setQuery] = useState('');
  const [refreshing, setRefreshing] = useState(false);

  const data = useMemo(() => {
    const list = query ? searchCountries(query) : allCountries;
    // Sort by highest score first for a pleasant default
    return [...list].sort((a, b) => b.score - a.score);
  }, [query]);

  const onRefresh = useCallback(() => {
    // If your dataset is static, this just shows the pull-to-refresh UX.
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 400);
  }, []);

  return (
    <View style={{ flex: 1 }}>
      <View style={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 6 }}>
        <TextInput
          value={query}
          onChangeText={setQuery}
          placeholder="Search country or ISO code…"
          style={{
            backgroundColor: '#FFF',
            borderColor: '#E2DED6',
            borderWidth: 1,
            borderRadius: 12,
            paddingHorizontal: 14,
            paddingVertical: 10,
            fontSize: 16
          }}
          autoCapitalize="none"
          autoCorrect={false}
          clearButtonMode="while-editing"
        />
      </View>

      <FlatList
        data={data}
        keyExtractor={(item) => item.iso2}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        contentContainerStyle={{ padding: 16, gap: 12 }}
        ListEmptyComponent={
          <Text style={{ padding: 16, fontSize: 16 }}>
            {query ? `No results for “${query}”.` : 'No countries available.'}
          </Text>
        }
        renderItem={({ item }) => (
          <Link href={{ pathname: '/country/[iso2]', params: { iso2: item.iso2 } }} asChild>
            <TouchableOpacity
              style={{
                padding: 16,
                borderRadius: 16,
                backgroundColor: '#F3F1EC',
                borderWidth: 1,
                borderColor: '#E2DED6'
              }}
            >
              <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
                <Text style={{ fontSize: 18, fontWeight: '600' }}>{item.name}</Text>
                <Text style={{ fontSize: 16 }}>Score: {item.score}</Text>
              </View>
              {item.n ? (
                <Text style={{ marginTop: 6, fontSize: 13, opacity: 0.7 }}>
                  n={item.n}{item.updatedAt ? ` · updated ${item.updatedAt}` : ''}
                </Text>
              ) : null}
            </TouchableOpacity>
          </Link>
        )}
      />
    </View>
  );
}