import { View, ActivityIndicator } from 'react-native';
import { useEffect } from 'react';
import { useRouter, usePathname } from 'expo-router';
import { useAuth } from '../context/AuthContext';

export default function AuthGate({ children }: { children: React.ReactNode }) {
  const { session, loading, isGuest, profile, profileLoading } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  // Not logged in and not guest -> must be on landing/login flow
  useEffect(() => {
    if (!loading && !session && !isGuest) {
      if (pathname !== '/' && pathname !== '/login' && pathname !== '/verify') {
        router.replace('/');
      }
    }
  }, [loading, session, isGuest, pathname]);

  // Logged in -> enforce onboarding gate (guest bypasses)
  useEffect(() => {
    if (loading || profileLoading) return;
    if (!session || isGuest) return;

    const onboarded = profile?.onboarding_completed === true;

    if (!onboarded && pathname !== '/onboarding') {
      router.replace('/onboarding');
      return;
    }

    if (onboarded && pathname === '/onboarding') {
      router.replace('/home');
    }
  }, [loading, profileLoading, session, isGuest, profile, pathname]);

  if (loading || (session && !isGuest && profileLoading)) {
    return (
      <View style={{ flex: 1, justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  // If we’re not allowed, we render nothing while router redirects.
  if (!session && !isGuest) return null;

  return <>{children}</>;
}