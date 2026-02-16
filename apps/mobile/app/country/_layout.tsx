import { Stack } from 'expo-router';

export default function CountryLayout() {
  return (
    <Stack
      screenOptions={{
        headerTitleAlign: 'center',
        headerShadowVisible: false,
      }}
    />
  );
}