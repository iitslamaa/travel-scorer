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
    console.log('[AUTHGATE] effect#1 check', {
      loading,
      hasSession: !!session,
      isGuest,
      pathname,
    });

    if (!loading && !session && !isGuest) {
      const isPublicRoute =
        pathname === '/' ||
        pathname === '/verify' ||
        pathname.startsWith('/login');

      if (!isPublicRoute) {
        console.log('[AUTHGATE] redirecting to / from', pathname);
        router.replace('/');
      }
    }
  }, [loading, session, isGuest, pathname]);

  // Logged in -> enforce onboarding gate (guest bypasses)
  useEffect(() => {
    console.log('[AUTHGATE] effect#2 check', {
      loading,
      profileLoading,
      hasSession: !!session,
      isGuest,
      pathname,
      onboarded: profile?.onboarding_completed,
    });

    if (loading || profileLoading) return;
    if (!session || isGuest) return;

    const onboarded = profile?.onboarding_completed === true;

    if (!onboarded && pathname !== '/onboarding') {
      console.log('[AUTHGATE] redirecting to /onboarding from', pathname);
      router.replace('/onboarding');
      return;
    }

    if (onboarded && pathname === '/onboarding') {
      console.log('[AUTHGATE] redirecting to /discovery from onboarding');
      router.replace('/discovery');
    }
  }, [loading, profileLoading, session, isGuest, profile, pathname]);

  if (loading || (session && !isGuest && profileLoading)) {
    return (
      <View style={{ flex: 1, justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  // Always render children once loading checks pass.
  // Redirect logic above handles protection.
  return <>{children}</>;
}