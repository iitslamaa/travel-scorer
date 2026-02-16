import { View, FlatList, ActivityIndicator } from 'react-native';
import AuthGate from '../../components/AuthGate';
import { useCountries } from '../../hooks/useCountries';
import CountryRow from '../../components/CountryRow';

export default function DiscoveryScreen() {
  const { countries, loading } = useCountries();

  return (
    <AuthGate>
      <View style={{ flex: 1, padding: 16 }}>
        {loading ? (
          <ActivityIndicator style={{ marginTop: 40 }} />
        ) : (
          <FlatList
            data={countries}
            keyExtractor={(item) => item.iso2}
            renderItem={({ item }) => (
              <CountryRow country={item} />
            )}
          />
        )}
      </View>
    </AuthGate>
  );
}