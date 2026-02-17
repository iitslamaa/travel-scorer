import { View, Text, StyleSheet } from 'react-native';
import { Stack } from 'expo-router';

export default function ProfileSettingsScreen() {
  return (
    <>
      <Stack.Screen options={{ title: 'Profile Settings' }} />

      <View style={styles.container}>
        <Text style={styles.title}>Profile Settings</Text>
        <Text>Languages</Text>
        <Text>Travel Mode</Text>
        <Text>Travel Style</Text>
        <Text>Next Destination</Text>
      </View>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: '800',
    marginBottom: 20,
  },
});