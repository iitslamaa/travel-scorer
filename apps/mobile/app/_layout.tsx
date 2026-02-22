import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Stack, useSegments } from 'expo-router';
import { Video, ResizeMode } from 'expo-av';
import { AuthProvider } from '../context/AuthContext';

function RootLayoutInner() {
  const segments = useSegments();

  const isAuthRoute =
    segments.length === 0 ||
    segments[0] === 'login' ||
    segments[0] === 'verify';

  return (
    <View style={styles.root}>
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
          contentStyle: { backgroundColor: 'transparent' },
        }}
      />
    </View>
  );
}

export default function RootLayout() {
  return (
    <AuthProvider>
      <RootLayoutInner />
    </AuthProvider>
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