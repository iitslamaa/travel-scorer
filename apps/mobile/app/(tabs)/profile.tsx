import React from 'react';
import {
  ScrollView,
  StyleSheet,
  View,
  Text,
  Pressable,
  useColorScheme,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useAuth } from '../../context/AuthContext';

import HeaderCard from '../../components/profile/HeaderCard';
import InfoCard from '../../components/profile/InfoCard';
import DisclosureRow from '../../components/profile/DisclosureRow';

export default function ProfileScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { session, profile, exitGuest } = useAuth();
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';

  const backgroundColor = isDark ? '#0F0F10' : '#F7F7F8';
  const titleColor = isDark ? '#FFFFFF' : '#111827';
  const subtitleColor = isDark ? '#A1A1AA' : '#6B7280';
  const iconColor = isDark ? '#FFFFFF' : '#111827';

  const user = session?.user ?? null;

  if (!user) {
    return (
      <View
        style={[
          styles.container,
          {
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            backgroundColor,
          },
        ]}
      >
        <Text style={[styles.title, { color: titleColor }]}> 
          Login to customize your profile
        </Text>

        <Text style={[styles.subtitle, { color: subtitleColor }]}> 
          Sign in to set your languages, travel style, and destinations.
        </Text>

        <Pressable
          style={styles.loginButton}
          onPress={() => {
            exitGuest();
            router.replace('/');
          }}
        >
          <Text style={styles.loginButtonText}>Go to Login →</Text>
        </Pressable>
      </View>
    );
  }

  const languages =
    Array.isArray(profile?.languages)
      ? profile.languages.join(' · ')
      : '—';

  const travelMode =
    Array.isArray(profile?.travel_mode) && profile.travel_mode.length
      ? profile.travel_mode[0].charAt(0).toUpperCase() +
        profile.travel_mode[0].slice(1)
      : '—';

  const travelStyle =
    Array.isArray(profile?.travel_style) && profile.travel_style.length
      ? profile.travel_style[0].charAt(0).toUpperCase() +
        profile.travel_style[0].slice(1)
      : '—';

  const nextDestination =
    typeof profile?.next_destination === 'string'
      ? profile.next_destination
      : '—';

  const displayName =
    profile?.full_name ??
    profile?.username ??
    'Your Profile';

  return (
    <ScrollView
      style={{ backgroundColor }}
      contentContainerStyle={[
        styles.container,
        { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 80 },
      ]}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.topRow}>
        <Text style={[styles.title, { color: titleColor }]}>
          {displayName}
        </Text>

        <Pressable
          onPress={() => router.push('/profile-settings')}
          style={styles.settingsIcon}
        >
          <Ionicons
            name="settings-outline"
            size={20}
            color={iconColor}
          />
        </Pressable>
      </View>

      <HeaderCard
        name={displayName}
        handle={profile?.username ? `@${profile.username}` : ''}
        avatarUrl={profile?.avatar_url ?? undefined}
        flags={profile?.lived_countries ?? []}
      />

      <View style={styles.section}>
        <InfoCard title="Languages" value={languages} />

        <InfoCard
          title="Travel Mode"
          value={travelMode}
        />

        <InfoCard
          title="Travel Style"
          value={travelStyle}
        />

        <InfoCard
          title="Next Destination"
          value={nextDestination}
        />

        <DisclosureRow
          label="Countries Traveled"
          value={
            Array.isArray((profile as any)?.countries_traveled)
              ? String((profile as any).countries_traveled.length)
              : '0'
          }
          // onPress={() => router.push('/countries-traveled')}
        />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 22,
  },

  topRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },

  settingsIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },

  title: {
    fontSize: 30,
    fontWeight: '700',
    letterSpacing: -0.5,
  },

  subtitle: {
    marginTop: 12,
    fontSize: 15,
    textAlign: 'center',
    paddingHorizontal: 24,
  },

  loginButton: {
    marginTop: 24,
  },

  loginButtonText: {
    fontSize: 17,
    fontWeight: '600',
    color: '#3B82F6',
  },

  section: {
    marginTop: 18,
    gap: 18,
  },
});