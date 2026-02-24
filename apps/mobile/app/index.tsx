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
    setLoadingGoogle(true);

    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
    });

    setLoadingGoogle(false);

    if (error) {
      Alert.alert('Google Login Error', error.message);
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