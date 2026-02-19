

import { View, Text, Pressable, StyleSheet, useColorScheme } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import AuthGate from '../components/AuthGate';

export default function ListsScreen() {
  const router = useRouter();
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';

  const backgroundColor = isDark ? '#000000' : '#FFFFFF';
  const textColor = isDark ? '#FFFFFF' : '#111827';
  const borderColor = isDark ? '#1F2937' : '#E5E7EB';
  const subTextColor = isDark ? '#9CA3AF' : '#6B7280';

  return (
    <AuthGate>
      <View style={[styles.container, { backgroundColor }]}>
        <Text style={[styles.header, { color: textColor }]}>Lists</Text>

        <Pressable
          style={[styles.card, { borderColor }]}
          onPress={() => router.push('/lists/bucket')}
        >
          <View style={styles.cardLeft}>
            <Ionicons name="bookmark-outline" size={20} color={textColor} />
            <View>
              <Text style={[styles.cardTitle, { color: textColor }]}>
                Bucket List
              </Text>
              <Text style={[styles.cardSubtitle, { color: subTextColor }]}>
                Countries you want to visit
              </Text>
            </View>
          </View>
          <Ionicons name="chevron-forward" size={18} color={textColor} />
        </Pressable>

        <Pressable
          style={[styles.card, { borderColor }]}
          onPress={() => router.push('/lists/visited')}
        >
          <View style={styles.cardLeft}>
            <Ionicons name="checkmark-circle-outline" size={20} color={textColor} />
            <View>
              <Text style={[styles.cardTitle, { color: textColor }]}>
                Visited
              </Text>
              <Text style={[styles.cardSubtitle, { color: subTextColor }]}>
                Countries you've been to
              </Text>
            </View>
          </View>
          <Ionicons name="chevron-forward" size={18} color={textColor} />
        </Pressable>
      </View>
    </AuthGate>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 40,
  },
  header: {
    fontSize: 24,
    fontWeight: '600',
    marginBottom: 24,
  },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 18,
    borderWidth: 1,
    borderRadius: 14,
    marginBottom: 16,
  },
  cardLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '600',
  },
  cardSubtitle: {
    fontSize: 13,
    marginTop: 2,
  },
});