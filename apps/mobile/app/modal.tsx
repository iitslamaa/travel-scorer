// apps/mobile/App.tsx
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SafeAreaView, FlatList, Text, TouchableOpacity, View } from 'react-native';
import * as React from 'react';

// Example shape: you’ll import from your real shared package
// import { countries } from '@travel-af/data';
const countries = [
  { iso2: 'JP', name: 'Japan', score: 86 },
  { iso2: 'FR', name: 'France', score: 78 },
  { iso2: 'US', name: 'United States', score: 70 },
];

type RootStackParamList = {
  Home: undefined;
  Country: { iso2: string; name: string; score: number };
};

const Stack = createNativeStackNavigator<RootStackParamList>();

function HomeScreen({ navigation }: any) {
  return (
    <SafeAreaView style={{ flex: 1 }}>
      <FlatList
        data={countries}
        keyExtractor={(item) => item.iso2}
        contentContainerStyle={{ padding: 16, gap: 12 }}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={{
              padding: 16,
              borderRadius: 16,
              backgroundColor: '#F3F1EC',
              borderWidth: 1,
              borderColor: '#E2DED6',
            }}
            onPress={() => navigation.navigate('Country', item)}
          >
            <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
              <Text style={{ fontSize: 18, fontWeight: '600' }}>{item.name}</Text>
              <Text style={{ fontSize: 16 }}>Score: {item.score}</Text>
            </View>
          </TouchableOpacity>
        )}
      />
    </SafeAreaView>
  );
}

function CountryScreen({ route }: any) {
  const { iso2, name, score } = route.params;
  return (
    <SafeAreaView style={{ flex: 1, padding: 16 }}>
      <Text style={{ fontSize: 24, fontWeight: '700' }}>{name}</Text>
      <Text style={{ fontSize: 16, marginTop: 8 }}>ISO2: {iso2}</Text>
      <Text style={{ fontSize: 16, marginTop: 8 }}>Travelability score: {score}</Text>
      <View style={{ marginTop: 16 }}>
        <Text style={{ fontSize: 16 }}>
          {/* Later: show per-category breakdown and last updated. */}
          This is where we’ll render category bars and a written explanation.
        </Text>
      </View>
    </SafeAreaView>
  );
}

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Travel AF' }} />
        <Stack.Screen name="Country" component={CountryScreen} options={{ title: 'Details' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}