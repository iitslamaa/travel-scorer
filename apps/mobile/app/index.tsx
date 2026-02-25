import { useEffect } from 'react';
import { useRouter, useRootNavigationState } from 'expo-router';
import { useAuth } from '../context/AuthContext';

export default function RootIndex() {
  const router = useRouter();
  const rootNavigationState = useRootNavigationState();
  const { session, loading } = useAuth();

  useEffect(() => {
    // Wait until the root navigator is mounted
    if (!rootNavigationState?.key) return;

    // Wait until auth has finished booting
    if (loading) return;

    if (session) {
      router.replace('/(tabs)');
    } else {
      router.replace('/login');
    }
  }, [session, loading, rootNavigationState]);

  return null;
}
