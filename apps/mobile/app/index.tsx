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

WebBrowser.maybeCompleteAuthSession();

export default function LandingScreen() {
  const router = useRouter();
  const {
    session,
    isGuest,
    continueAsGuest,
    hasSeenIntro,
    setHasSeenIntro,
  } = useAuth();

  const [loadingGoogle, setLoadingGoogle] = useState(false);

  const introOpacity = useRef(new Animated.Value(1)).current;
  const buttonsOpacity = useRef(new Animated.Value(0)).current;

  // Navigation guard
  useEffect(() => {
    if (session || isGuest) {
      router.replace('/home');
    }
  }, [session, isGuest, router]);

  // If intro already seen, immediately show buttons
  useEffect(() => {
    if (hasSeenIntro) {
      introOpacity.setValue(0);
      buttonsOpacity.setValue(1);
    }
  }, [hasSeenIntro]);

  const handleGoogleLogin = async () => {
    console.log('Google button pressed');

    try {
      setLoadingGoogle(true);

      const redirectTo = Linking.createURL('auth/callback');
      console.log('redirectTo:', redirectTo);

      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo,
          skipBrowserRedirect: true,
        },
      });

      if (error) {
        Alert.alert('Google Login Error', error.message);
        return;
      }

      const authUrl = data?.url;
      if (!authUrl) {
        Alert.alert('Google Login Error', 'No auth URL returned.');
        return;
      }

      const result = await WebBrowser.openAuthSessionAsync(authUrl, redirectTo);
      console.log('OAuth result:', result);

      // If we successfully returned to the app, Supabase (implicit flow)
      // sends tokens in the URL fragment (#access_token=...)
      if (result.type === 'success' && result.url) {
        const hash = result.url.split('#')[1];

        if (!hash) {
          Alert.alert('Google Login Error', 'Missing auth tokens in redirect URL.');
          return;
        }

        const params = new URLSearchParams(hash);
        const access_token = params.get('access_token');
        const refresh_token = params.get('refresh_token');

        if (!access_token || !refresh_token) {
          Alert.alert('Google Login Error', 'Missing access or refresh token.');
          return;
        }

        const { error: sessionError } = await supabase.auth.setSession({
          access_token,
          refresh_token,
        });

        if (sessionError) {
          Alert.alert('Google Login Error', sessionError.message);
          return;
        }
      }

    } catch (e: any) {
      Alert.alert('Google Login Error', e?.message ?? 'Unknown error');
    } finally {
      setLoadingGoogle(false);
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