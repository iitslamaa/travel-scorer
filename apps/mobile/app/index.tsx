import { View, Text, StyleSheet, Pressable } from 'react-native';
import { useEffect } from 'react';
import { useRouter } from 'expo-router';
import { useAuth } from '../context/AuthContext';

export default function LandingScreen() {
  const router = useRouter();
  const { session, isGuest, continueAsGuest } = useAuth();

  useEffect(() => {
    if (session || isGuest) {
      router.replace('/home');
    }
  }, [session, isGuest]);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>TravelScorer</Text>
      <Text>Cross-Platform Mobile App</Text>

      <Pressable
        style={styles.button}
        onPress={() => router.push('/login')}
      >
        <Text style={styles.buttonText}>Login</Text>
      </Pressable>

      <Pressable
        style={[styles.button, { backgroundColor: '#888' }]}
        onPress={continueAsGuest}
      >
        <Text style={styles.buttonText}>Continue as Guest</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  title: {
    fontSize: 28,
    fontWeight: '600',
    marginBottom: 8,
  },
  button: {
    marginTop: 16,
    backgroundColor: 'black',
    padding: 14,
    borderRadius: 8,
    alignItems: 'center',
    width: '100%',
  },
  buttonText: {
    color: 'white',
    fontWeight: '600',
  },
});