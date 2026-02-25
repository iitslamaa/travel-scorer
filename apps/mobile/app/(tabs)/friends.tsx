import {
  View,
  Text,
  StyleSheet,
  Pressable,
  TextInput,
  FlatList,
  useColorScheme,
  Image,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useMemo, useState } from 'react';
import { Ionicons } from '@expo/vector-icons';
import AuthGate from '../../components/AuthGate';
import { lightColors, darkColors } from '../../theme/colors';
import { useFriends } from '../../hooks/useFriends';
import { useAuth } from '../../context/AuthContext';

export default function FriendsScreen() {
  const router = useRouter();
  const scheme = useColorScheme();
  const colors = scheme === 'dark' ? darkColors : lightColors;

  const { isGuest } = useAuth();

  const { friends, loading } = useFriends();

  const [searchQuery, setSearchQuery] = useState('');

  const filteredFriends = useMemo(() => {
    if (!searchQuery.trim()) return friends;

    const q = searchQuery.toLowerCase();

    return friends.filter((f: any) =>
      (f.full_name?.toLowerCase().includes(q) ?? false) ||
      (f.username?.toLowerCase().includes(q) ?? false)
    );
  }, [friends, searchQuery]);

  const renderItem = ({ item }: { item: any }) => (
    <Pressable
      onPress={() => router.push(`/profile/${item.id}`)}
      style={[styles.row, { borderBottomColor: colors.textSecondary }]}
    >
      {item.avatar_url ? (
        <Image source={{ uri: item.avatar_url }} style={styles.avatar} />
      ) : (
        <View style={styles.avatar} />
      )}

      <View style={{ flex: 1 }}>
        <Text style={[styles.name, { color: colors.textPrimary }]}>
          {item.full_name}
        </Text>
        <Text style={[styles.username, { color: colors.textMuted }]}>
          @{item.username}
        </Text>
      </View>

      <Ionicons
        name="chevron-forward"
        size={18}
        color={colors.textMuted}
      />
    </Pressable>
  );

  if (isGuest) {
    return (
      <View
        style={[
          styles.container,
          {
            backgroundColor: colors.background,
            justifyContent: 'center',
          },
        ]}
      >
        <Text
          style={{
            fontSize: 34,
            fontWeight: '700',
            color: colors.textPrimary,
          }}
        >
          Login to customize your friends
        </Text>

        <Text
          style={{
            marginTop: 16,
            fontSize: 16,
            color: colors.textMuted,
            lineHeight: 22,
            maxWidth: 320,
          }}
        >
          Sign in to add friends, send requests, and explore profiles.
        </Text>

        <Pressable
          onPress={() => router.push('/login')}
          style={{ marginTop: 24 }}
        >
          <Text
            style={{
              fontSize: 18,
              fontWeight: '600',
              color: '#3B82F6',
            }}
          >
            Go to Login →
          </Text>
        </Pressable>
      </View>
    );
  }

  return (
    <AuthGate>
      <View style={[styles.container, { backgroundColor: colors.background }]}>
        {loading && (
          <View
            style={{
              flex: 1,
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <ActivityIndicator size="large" color={colors.textPrimary} />
          </View>
        )}

        {!loading && (
          <>
        {/* Header */}
        <View style={styles.headerRow}>
          <Text style={[styles.title, { color: colors.textPrimary }]}>
            Lama’s Friends
          </Text>

          <Pressable
            onPress={() => router.push('/friend-requests')}
            style={[styles.requestButton, { backgroundColor: colors.card }]}
          >
            <Ionicons
              name="person-add-outline"
              size={20}
              color={colors.textPrimary}
            />
          </Pressable>
        </View>

        {/* Search */}
        <View style={[styles.searchBar, { backgroundColor: colors.card }]}>
          <Ionicons name="search" size={16} color={colors.textMuted} />
          <TextInput
            placeholder="Search by username"
            placeholderTextColor={colors.textMuted}
            style={[styles.searchInput, { color: colors.textPrimary }]}
            value={searchQuery}
            onChangeText={setSearchQuery}
          />
        </View>

        {/* Friends List Card */}
        <View style={[styles.card, { backgroundColor: colors.card }]}>
          <FlatList
            data={filteredFriends}
            renderItem={renderItem}
            keyExtractor={(item) => item.id}
            contentContainerStyle={{ paddingBottom: 40 }}
            ListEmptyComponent={
              !loading ? (
                <Text style={{ color: colors.textMuted, textAlign: 'center', paddingVertical: 20 }}>
                  No friends yet.
                </Text>
              ) : null
            }
          />
        </View>
          </>
        )}
      </View>
    </AuthGate>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 60,
    paddingBottom: 120,
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  title: {
    fontSize: 34,
    fontWeight: '700',
  },
  requestButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
  },
  searchBar: {
    marginTop: 20,
    borderRadius: 20,
    paddingHorizontal: 14,
    height: 44,
    flexDirection: 'row',
    alignItems: 'center',
  },
  searchInput: {
    marginLeft: 8,
    flex: 1,
  },
  card: {
    marginTop: 24,
    borderRadius: 28,
    paddingVertical: 10,
    paddingHorizontal: 10,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    paddingHorizontal: 10,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#444',
    marginRight: 14,
  },
  name: {
    fontSize: 16,
    fontWeight: '600',
  },
  username: {
    fontSize: 14,
    marginTop: 2,
  },
});