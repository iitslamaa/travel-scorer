import { View, Text, Pressable, StyleSheet, useColorScheme } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import AuthGate from '../../components/AuthGate';

export default function MoreScreen() {
  const router = useRouter();
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';

  const backgroundColor = isDark ? '#000000' : '#FFFFFF';
  const textColor = isDark ? '#FFFFFF' : '#111827';
  const borderColor = isDark ? '#1F2937' : '#E5E7EB';

  return (
    <AuthGate>
      <View style={[styles.container, { backgroundColor }]}>
        <Text style={[styles.header, { color: textColor }]}>More</Text>

        <Pressable
          style={[styles.row, { borderBottomColor: borderColor }]}
          onPress={() => router.push('/lists')}
        >
          <View style={styles.rowLeft}>
            <Ionicons name="list" size={18} color={textColor} />
            <Text style={[styles.rowText, { color: textColor }]}>Lists</Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color={textColor} />
        </Pressable>

        <Pressable
          style={[styles.row, { borderBottomColor: borderColor }]}
          onPress={() => router.push('/legal')}
        >
          <View style={styles.rowLeft}>
            <Ionicons name="document-text-outline" size={18} color={textColor} />
            <Text style={[styles.rowText, { color: textColor }]}>Legal</Text>
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
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 16,
    borderBottomWidth: 1,
  },
  rowLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  rowText: {
    fontSize: 16,
    fontWeight: '500',
  },
});