import {
  View,
  Text,
  StyleSheet,
  Image,
  useColorScheme,
} from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { lightColors, darkColors } from '../../theme/colors';

export default function ProfileScreen() {
  const { id } = useLocalSearchParams();
  const scheme = useColorScheme();
  const colors = scheme === 'dark' ? darkColors : lightColors;

  const [profile, setProfile] = useState<any>(null);

  useEffect(() => {
    async function fetchProfile() {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', id)
        .single();

      if (!error) {
        setProfile(data);
      } else {
        console.error(error);
      }
    }

    if (id) {
      fetchProfile();
    }
  }, [id]);

  if (!profile) {
    return (
      <View style={[styles.container, { backgroundColor: colors.background }]}>
        <Text style={{ color: colors.textMuted }}>Loading...</Text>
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {profile.avatar_url ? (
        <Image source={{ uri: profile.avatar_url }} style={styles.avatar} />
      ) : (
        <View style={styles.avatar} />
      )}

      <Text style={[styles.name, { color: colors.textPrimary }]}>
        {profile.full_name}
      </Text>

      <Text style={[styles.username, { color: colors.textMuted }]}>
        @{profile.username}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    paddingTop: 100,
  },
  avatar: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: '#444',
    marginBottom: 20,
  },
  name: {
    fontSize: 24,
    fontWeight: '700',
  },
  username: {
    fontSize: 16,
    marginTop: 6,
  },
});