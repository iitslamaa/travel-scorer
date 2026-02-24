import {
  View,
  Text,
  StyleSheet,
  Image,
  Pressable,
  ScrollView,
  useColorScheme,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useNavigation } from '@react-navigation/native';
import { useEffect } from 'react';
import { Ionicons } from '@expo/vector-icons';
import CountryFlag from 'react-native-country-flag';
import { lightColors, darkColors } from '../../theme/colors';
import { useProfileById } from '../../hooks/useProfileById';
import { useFriendshipStatus } from '../../hooks/useFriendshipStatus';
import { useFriendCount } from '../../hooks/useFriendCount';
import { useUserCounts } from '../../hooks/useUserCounts';
import { useCountries } from '../../hooks/useCountries';

export default function FriendProfileScreen() {
  const router = useRouter();
  const navigation = useNavigation();

  useEffect(() => {
    navigation.setOptions({
      title: 'Profile',
    });
  }, [navigation]);
  const { id } = useLocalSearchParams();
  const scheme = useColorScheme();
  const colors = scheme === 'dark' ? darkColors : lightColors;

  const { profile, loading } = useProfileById(id);
  const { isFriend } = useFriendshipStatus(id);
  const { count: friendCount } = useFriendCount(id);
  const { traveledCount } = useUserCounts(id);

  const { countries } = useCountries();

  const nextDestinationIso =
    typeof profile?.next_destination === 'string'
      ? profile.next_destination
      : null;

  const nextDestinationCountry = countries?.find(
    c => c.iso2 === nextDestinationIso
  );

  if (loading || !profile) {
    return (
      <View style={[styles.container, { backgroundColor: colors.background }]}>
        <Text style={{ color: colors.textMuted }}>Loading...</Text>
      </View>
    );
  }



  const languagesText =
    Array.isArray(profile.languages) && profile.languages.length > 0
      ? profile.languages
          .map((l: any) => (typeof l === 'string' ? l : l?.name))
          .filter(Boolean)
          .join(' · ')
      : '—';

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {/* Top back */}
      <Pressable onPress={() => router.back()} style={styles.backBtn}>
        <Ionicons name="arrow-back" size={22} color={colors.textPrimary} />
      </Pressable>

      <ScrollView contentContainerStyle={{ paddingBottom: 40 }}>
        <Text style={[styles.title, { color: colors.textPrimary }]}>
          Profile
        </Text>

        {/* Header block */}
        <View style={styles.headerRow}>
          <View style={styles.avatarWrap}>
            {profile.avatar_url ? (
              <Image source={{ uri: profile.avatar_url }} style={styles.avatar} />
            ) : (
              <View style={[styles.avatar, { backgroundColor: '#444' }]} />
            )}
          </View>

          <View style={{ flex: 1, marginLeft: 18 }}>
            <Text style={[styles.name, { color: colors.textPrimary }]}>
              {profile.full_name}
            </Text>
            <Text style={[styles.username, { color: colors.textMuted }]}>
              @{profile.username}
            </Text>

            {Array.isArray(profile.lived_countries) &&
              profile.lived_countries.length > 0 && (
                <View style={styles.homeRow}>
                  {profile.lived_countries.map((iso: string) => (
                    <CountryFlag
                      key={iso}
                      isoCode={iso}
                      size={24}
                      style={{ marginRight: 8 }}
                    />
                  ))}
                </View>
              )}

            {/* Friend button */}
            <Pressable
              style={[
                styles.friendBtn,
                {
                  borderColor: colors.primary,
                },
              ]}
            >
              <Ionicons
                name={isFriend ? 'checkmark' : 'person-add-outline'}
                size={18}
                color={colors.primary}
              />
              <Text style={[styles.friendBtnText, { color: colors.primary }]}>
                {friendCount} Friend{friendCount === 1 ? '' : 's'}
              </Text>
            </Pressable>
          </View>
        </View>

        {/* Cards - (we’ll fill these from profile fields next) */}
        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Text style={[styles.cardTitle, { color: colors.textPrimary }]}>
            Languages
          </Text>
          <Text style={[styles.cardValue, { color: colors.textMuted }]}> 
            {languagesText}
          </Text>
        </View>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Text style={[styles.cardTitle, { color: colors.textPrimary }]}>
            Travel Mode: Solo or Group?
          </Text>
          <Text style={[styles.cardValue, { color: colors.textMuted }]}>
            {profile.travel_mode ?? '—'}
          </Text>
        </View>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Text style={[styles.cardTitle, { color: colors.textPrimary }]}>
            Travel Style: Budget, Comfortable, or In Between?
          </Text>
          <Text style={[styles.cardValue, { color: colors.textMuted }]}>
            {profile.travel_style ?? '—'}
          </Text>
        </View>

        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <Text style={[styles.cardTitle, { color: colors.textPrimary }]}>
            Next Destination
          </Text>
          {nextDestinationCountry ? (
            <View style={styles.inlineRow}>
              <CountryFlag
                isoCode={nextDestinationCountry.iso2}
                size={18}
                style={{ marginRight: 6 }}
              />
              <Text style={[styles.cardValue, { color: colors.textMuted, marginTop: 0 }]}>
                {nextDestinationCountry.name}
              </Text>
            </View>
          ) : (
            <Text style={[styles.cardValue, { color: colors.textMuted }]}>—</Text>
          )}
        </View>

        <Pressable style={[styles.linkRow, { backgroundColor: colors.card }]}>
          <Ionicons name="chevron-forward" size={18} color={colors.primary} />
          <Text style={[styles.linkText, { color: colors.primary }]}>
            Countries Traveled:
          </Text>
          <Text style={{ color: '#d2a21b', marginLeft: 8, fontWeight: '700' }}>
            {traveledCount}
          </Text>
        </Pressable>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 60, paddingHorizontal: 20 },
  backBtn: { marginBottom: 14 },
  title: { fontSize: 30, fontWeight: '700', letterSpacing: -0.5, marginBottom: 20 },
  headerRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 22 },
  avatarWrap: { width: 150, height: 150, borderRadius: 75, overflow: 'hidden' },
  avatar: { width: 150, height: 150, borderRadius: 75 },
  name: { fontSize: 28, fontWeight: '800', marginTop: 6 },
  username: { fontSize: 18, marginTop: 4 },
  homeRow: {
    flexDirection: 'row',
    marginTop: 10,
    alignItems: 'center',
  },
  inlineRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
  friendBtn: {
    marginTop: 14,
    alignSelf: 'flex-start',
    paddingVertical: 12,
    paddingHorizontal: 18,
    borderRadius: 26,
    borderWidth: 2,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  friendBtnText: { fontSize: 16, fontWeight: '700' },
  card: { borderRadius: 24, padding: 18, marginTop: 16 },
  cardTitle: { fontSize: 18, fontWeight: '800' },
  cardValue: { fontSize: 16, marginTop: 8 },
  linkRow: {
    marginTop: 18,
    borderRadius: 24,
    paddingVertical: 18,
    paddingHorizontal: 18,
    flexDirection: 'row',
    alignItems: 'center',
  },
  linkText: { fontSize: 18, fontWeight: '800', marginLeft: 10 },
});