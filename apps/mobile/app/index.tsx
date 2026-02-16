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

export default function LandingScreen() {
  const router = useRouter();
  const { session, isGuest, continueAsGuest } = useAuth();

  const [loadingGoogle, setLoadingGoogle] = useState(false);
  const [introFinished, setIntroFinished] = useState(false);

  const introOpacity = useRef(new Animated.Value(1)).current;
  const loopOpacity = useRef(new Animated.Value(0)).current;
  const buttonsOpacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (session || isGuest) {
      router.replace('/home');
    }
  }, [session, isGuest]);

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

  const handleIntroFinish = () => {
    if (introFinished) return;
    setIntroFinished(true);

    Animated.parallel([
      Animated.timing(introOpacity, {
        toValue: 0,
        duration: 500,
        useNativeDriver: true,
      }),
      Animated.timing(loopOpacity, {
        toValue: 1,
        duration: 500,
        useNativeDriver: true,
      }),
    ]).start(() => {
      // Fade in buttons 0.5s after loop becomes visible
      setTimeout(() => {
        Animated.timing(buttonsOpacity, {
          toValue: 1,
          duration: 600,
          useNativeDriver: true,
        }).start();
      }, 500);
    });
  };

  return (
    <View style={styles.container}>
      {/* LOOP VIDEO (always mounted, starts hidden) */}
      <Animated.View style={[StyleSheet.absoluteFill, { opacity: loopOpacity }]}>
        <Video
          source={require('../assets/auth_loop.mp4')}
          style={StyleSheet.absoluteFill}
          resizeMode={ResizeMode.COVER}
          shouldPlay
          isLooping
          isMuted
        />
      </Animated.View>

      {/* INTRO VIDEO (fades out instead of unmounting) */}
      <Animated.View style={[StyleSheet.absoluteFill, { opacity: introOpacity }]}>
        <Video
          source={require('../assets/intro.mp4')}
          style={StyleSheet.absoluteFill}
          resizeMode={ResizeMode.COVER}
          shouldPlay
          isLooping={false}
          isMuted
          onPlaybackStatusUpdate={(status) => {
            if (status.isLoaded && status.didJustFinish) {
              handleIntroFinish();
            }
          }}
        />
      </Animated.View>

      {/* Overlay */}
      <View style={styles.overlay} />

      {/* Auth Buttons */}
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

          <Pressable
            style={styles.guestButton}
            onPress={continueAsGuest}
          >
            <Text style={styles.guestText}>
              Continue as Guest
            </Text>
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
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.4)',
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