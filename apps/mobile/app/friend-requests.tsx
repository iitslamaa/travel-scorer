import { View, Text, StyleSheet, Pressable, useColorScheme } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { lightColors, darkColors } from '../theme/colors';

export default function FriendRequestsScreen() {
  const router = useRouter();
  const scheme = useColorScheme();
  const colors = scheme === 'dark' ? darkColors : lightColors;

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <Pressable onPress={() => router.back()} style={styles.backButton}>
        <Ionicons name="arrow-back" size={24} color={colors.textPrimary} />
      </Pressable>

      <Text style={[styles.title, { color: colors.textPrimary }]}>
        Friend Requests
      </Text>

      <View style={styles.emptyState}>
        <Ionicons
          name="person-add-outline"
          size={60}
          color={colors.textMuted}
        />
        <Text style={[styles.emptyTitle, { color: colors.textPrimary }]}>
          No friend requests
        </Text>
        <Text style={[styles.emptySubtitle, { color: colors.textMuted }]}>
          When someone sends you a friend request, it’ll show up here.
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 60,
    paddingHorizontal: 20,
  },
  backButton: {
    marginBottom: 20,
  },
  title: {
    fontSize: 34,
    fontWeight: '700',
  },
  emptyState: {
    marginTop: 140,
    alignItems: 'center',
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginTop: 20,
  },
  emptySubtitle: {
    fontSize: 15,
    marginTop: 8,
    textAlign: 'center',
    paddingHorizontal: 30,
  },
});