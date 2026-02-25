import {
  View,
  Text,
  StyleSheet,
  Pressable,
  KeyboardAvoidingView,
  Platform,
  Alert,
  Animated,
} from 'react-native';
import { useEffect, useState, useRef } from 'react';
import { useRouter } from 'expo-router';
import { supabase } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';
import { Video, ResizeMode } from 'expo-av';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Linking from 'expo-linking';
import * as WebBrowser from 'expo-web-browser';

export default function LandingScreen() {
  console.log('[LANDING] render', {
    hasSession: !!session,
    isGuest,
    loading,
    hasSeenIntro,
  });
  const router = useRouter();
  const {
    session,
    isGuest,
    loading,
    continueAsGuest,
    hasSeenIntro,
    setHasSeenIntro,
  } = useAuth();

  const [loadingGoogle, setLoadingGoogle] = useState(false);
  const loginInProgressRef = useRef(false);

  const introOpacity = useRef(new Animated.Value(1)).current;
  const buttonsOpacity = useRef(new Animated.Value(0)).current;

  // Navigation guard
  useEffect(() => {
    console.log('[LANDING] nav effect check', {
      loading,
      hasSession: !!session,
      isGuest,
    });

    if (loading) return;

    if (session || isGuest) {
      console.log('[LANDING] redirecting to /discovery');
      router.replace('/discovery');
    }
  }, [session, isGuest, loading]);

  // If intro already seen, immediately show buttons
  useEffect(() => {
    if (hasSeenIntro) {
      introOpacity.setValue(0);
      buttonsOpacity.setValue(1);
    }
  }, [hasSeenIntro]);

  // 🔥 Deep link debugging
  useEffect(() => {
    console.log('[LANDING] deepLink effect mounted');

    const handleUrl = async (event: { url: string }) => {
      console.log('🔥 DEEP LINK RECEIVED:', event.url);
      try {
        const currentSession = await supabase.auth.getSession();
        console.log('🔥 getSession() after deep link:', currentSession);
      } catch (err) {
        console.log('🔥 getSession() error after deep link:', err);
      }
    };

    const subscription = Linking.addEventListener('url', handleUrl);

    Linking.getInitialURL().then((url) => {
      console.log('🔥 INITIAL URL CHECK:', url);
      supabase.auth.getSession().then((s) => {
        console.log('🔥 getSession() on mount:', s);
      });
    });

    return () => {
      console.log('[LANDING] deepLink effect cleanup');
      subscription.remove();
    };
  }, []);

  const dumpStorage = async (label: string) => {
    try {
      const keys = await AsyncStorage.getAllKeys();
      console.log(`[storage.dump] ${label} keys(${keys.length}):`, keys);

      const interesting = keys.filter(k =>
        k.includes('supabase') ||
        k.includes('sb-') ||
        k.includes('pkce') ||
        k.includes('auth') ||
        k.includes('travelaf')
      );

      if (interesting.length) {
        const pairs = await AsyncStorage.multiGet(interesting);
        console.log(
          `[storage.dump] ${label} values:`,
          pairs.map(([k, v]) => [k, v ? `len=${v.length}` : null])
        );
      }
    } catch (e) {
      console.log('[storage.dump] error', e);
    }
  };

  const handleGoogleLogin = async () => {
    console.log('🟡 handleGoogleLogin invoked');
    const currentBefore = await supabase.auth.getSession();
    console.log('🟡 getSession BEFORE signIn:', currentBefore);

    if (loginInProgressRef.current) return;

    loginInProgressRef.current = true;

    try {
      console.log('--- GOOGLE LOGIN START ---');
      setLoadingGoogle(true);
      console.log('Loading state set to true');

      const redirectTo = Linking.createURL('auth/callback');
      console.log('redirectTo:', redirectTo);
      await dumpStorage('BEFORE signInWithOAuth');
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo,
        },
      });
      console.log('signInWithOAuth data:', data);
      console.log('signInWithOAuth error:', error);
      await dumpStorage('AFTER signInWithOAuth');

      if (error) {
        Alert.alert('Google Login Error', error.message);
        return;
      }

      if (data?.url) {
        await WebBrowser.openBrowserAsync(data.url);
        console.log('Browser opened, waiting for deep link...');
      } else {
        console.log('No OAuth URL returned');
      }
    } catch (e: any) {
      console.log('Google login exception:', e);
      Alert.alert('Google Login Error', e?.message ?? 'Unknown error');
    } finally {
      const currentAfter = await supabase.auth.getSession();
      console.log('🟡 getSession AFTER browser return:', currentAfter);
      console.log('--- GOOGLE LOGIN END ---');
      setLoadingGoogle(false);
      loginInProgressRef.current = false;
    }
  };

  const finishIntro = async () => {
    await AsyncStorage.setItem('hasSeenIntro', 'true');
    setHasSeenIntro(true);

    Animated.timing(introOpacity, {
      toValue: 0,
      duration: 400,
      useNativeDriver: true,
    }).start(() => {
      Animated.timing(buttonsOpacity, {
        toValue: 1,
        duration: 500,
        useNativeDriver: true,
      }).start();
    });
  };

  const shouldShowIntro = hasSeenIntro === false;

  return (
    <View style={styles.container}>
      {shouldShowIntro && (
        <Animated.View
          style={[StyleSheet.absoluteFill, { opacity: introOpacity }]}
        >
          <Video
            source={require('../assets/intro.mp4')}
            style={StyleSheet.absoluteFill}
            resizeMode={ResizeMode.COVER}
            shouldPlay
            isLooping={false}
            isMuted
            onPlaybackStatusUpdate={(status) => {
              if (status.isLoaded && status.didJustFinish) {
                finishIntro();
              }
            }}
          />
        </Animated.View>
      )}

      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={styles.content}
      >
        <Animated.View style={{ opacity: buttonsOpacity }}>
          <Pressable
            style={[styles.googleButton, loadingGoogle && { opacity: 0.6 }]}
            onPress={handleGoogleLogin}
            disabled={loadingGoogle}
          >
            <Text style={styles.googleText}>
              {loadingGoogle ? 'Connecting...' : 'Continue with Google'}
            </Text>
          </Pressable>

          <Pressable
            style={styles.emailButton}
            onPress={() => router.push('/login')}
          >
            <Text style={styles.emailText}>
              Continue with Email
            </Text>
          </Pressable>

          <Pressable style={styles.guestButton} onPress={continueAsGuest}>
            <Text style={styles.guestText}>Continue as Guest</Text>
          </Pressable>
        </Animated.View>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    padding: 24,
  },
  googleButton: {
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 16,
  },
  googleText: {
    fontWeight: '600',
    fontSize: 16,
  },
  emailButton: {
    backgroundColor: 'black',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 12,
  },
  emailText: {
    color: 'white',
    fontWeight: '600',
    fontSize: 16,
  },
  guestButton: {
    alignItems: 'center',
    marginTop: 8,
  },
  guestText: {
    color: 'white',
    fontSize: 14,
  },
});