import { View, Text, Pressable, StyleSheet, Alert } from 'react-native';
import AuthGate from '../components/AuthGate';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { useRouter } from 'expo-router';
import { useState } from 'react';

export default function OnboardingScreen() {
  const { session, refreshProfile, isGuest } = useAuth();
  const router = useRouter();
  const [saving, setSaving] = useState(false);

  const completeOnboarding = async () => {
    if (isGuest) {
      Alert.alert('Guest Mode', 'Please log in to complete onboarding.');
      return;
    }
    const userId = session?.user?.id;
    if (!userId) return;

    setSaving(true);

    const { error } = await supabase
      .from('profiles')
      .update({ onboarding_completed: true })
      .eq('id', userId);

    setSaving(false);

    if (error) {
      Alert.alert('Error', error.message);
      return;
    }

    await refreshProfile();
    router.replace('/home');
  };

  return (
    <AuthGate>
      <View style={styles.container}>
        <Text style={styles.title}>Finish Setup</Text>
        <Text style={styles.subtitle}>
          This is the onboarding gate (mirrors iOS). We’ll replace this with the real flow.
        </Text>

        <Pressable style={styles.button} onPress={completeOnboarding}>
          <Text style={styles.buttonText}>{saving ? 'Saving...' : 'Complete Onboarding (dev)'}</Text>
        </Pressable>
      </View>
    </AuthGate>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', padding: 24 },
  title: { fontSize: 28, fontWeight: '600', marginBottom: 12, textAlign: 'center' },
  subtitle: { textAlign: 'center', marginBottom: 24, opacity: 0.7 },
  button: { backgroundColor: 'black', padding: 14, borderRadius: 8, alignItems: 'center' },
  buttonText: { color: 'white', fontWeight: '600' },
});