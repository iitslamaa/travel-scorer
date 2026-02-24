import React from 'react';
import { View, StyleSheet, useColorScheme } from 'react-native';
import { Stack, useSegments } from 'expo-router';
import { Video, ResizeMode } from 'expo-av';
import { AuthProvider } from '../context/AuthContext';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { useTheme } from '../hooks/useTheme';

function RootLayoutInner() {
  const segments = useSegments();
  const scheme = useColorScheme();
  const colors = useTheme();

  const isAuthRoute =
    segments.length === 0 ||
    segments[0] === 'login' ||
    segments[0] === 'verify';

  return (
    <SafeAreaView style={[styles.root, { backgroundColor: colors.background }]} edges={['top', 'left', 'right']}>
      <StatusBar
        style={scheme === 'dark' ? 'light' : 'dark'}
        backgroundColor={colors.background}
      />

      {isAuthRoute ? (
        <View pointerEvents="none" style={StyleSheet.absoluteFill}>
          <Video
            source={require('../assets/auth_loop.mp4')}
            style={StyleSheet.absoluteFill}
            resizeMode={ResizeMode.COVER}
            shouldPlay
            isLooping
            isMuted
          />
          <View style={styles.overlay} />
        </View>
      ) : null}

      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: colors.background },
        }}
      />
    </SafeAreaView>
  );
}

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <RootLayoutInner />
      </AuthProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
});