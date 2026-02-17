import React from 'react';
import {
  ScrollView,
  StyleSheet,
  View,
  Text,
  useColorScheme,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useAuth } from '../../context/AuthContext';

import HeaderCard from '../../components/profile/HeaderCard';
import InfoCard from '../../components/profile/InfoCard';
import DisclosureRow from '../../components/profile/DisclosureRow';

export default function ProfileScreen() {
  const insets = useSafeAreaInsets();
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';
  const router = useRouter();
  const { session, profile, profileLoading, exitGuest } = useAuth();
  const user = session?.user ?? null;

  if (!user) {
    return (
      <View
        style={[
          styles.container,
          { flex: 1, justifyContent: 'center', alignItems: 'center' },
        ]}
      >
        <Text style={[styles.title, isDark && styles.titleDark]}>
          Login to customize your profile!
        </Text>

        <Text
          style={{
            marginTop: 12,
            fontSize: 16,
            color: isDark ? '#CBD5E1' : '#6B7280',
            textAlign: 'center',
            paddingHorizontal: 20,
          }}
        >
          Sign in to set your languages, travel style, and destinations.
        </Text>

        <View style={{ marginTop: 24 }}>
          <Text
            onPress={() => {
              exitGuest();
              router.replace('/');
            }}
            style={{
              fontSize: 18,
              fontWeight: '700',
              color: '#2563EB',
            }}
          >
            Go to Login →
          </Text>
        </View>
      </View>
    );
  }

  return (
    <ScrollView
      contentContainerStyle={[
        styles.container,
        { paddingTop: insets.top + 12, paddingBottom: insets.bottom + 28 },
      ]}
      showsVerticalScrollIndicator={false}
    >
      <Text style={[styles.title, isDark && styles.titleDark]}>
        {profile?.display_name ?? profile?.username ?? 'Your Profile'}
      </Text>

      <HeaderCard
        name={profile?.display_name ?? profile?.username ?? 'User'}
        handle={profile?.username ? `@${profile.username}` : ''}
        avatarUrl={profile?.avatar_url ?? undefined}
        flags={[]}
        onPressSettings={() => router.push('/profile-settings')}
      />

      <View style={styles.section}>
        <InfoCard
          title="Next Destination"
          value={profile?.next_destination ?? '—'}
        />

        <DisclosureRow
          label="Countries Traveled:"
          value="0"
          onPress={() => console.log('open countries')}
        />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 18,
  },
  title: {
    fontSize: 32,
    fontWeight: '800',
    marginBottom: 18,
    color: '#111827',
  },
  titleDark: {
    color: '#F9FAFB',
  },
  section: {
    marginTop: 14,
    gap: 14,
  },
});