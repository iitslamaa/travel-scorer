import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { View } from 'react-native';

export default function RootLayout() {
  return (
    <View style={{ flex: 1, backgroundColor: '#F3F1EC' }}>
      <StatusBar style="dark" />
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: '#F3F1EC' },
          headerTitleStyle: { fontWeight: '700' },
          contentStyle: { backgroundColor: '#F9F7F2' }
        }}
      >
        <Stack.Screen name="index" options={{ title: 'Travel AF' }} />
        <Stack.Screen name="country/[iso2]" options={{ title: 'Details' }} />
      </Stack>
    </View>
  );
}