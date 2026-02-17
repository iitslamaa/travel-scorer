import {
  ScrollView,
  View,
  Text,
  StyleSheet,
  Pressable,
  useColorScheme,
} from 'react-native';
import { useRouter } from 'expo-router';
import { lightColors, darkColors } from '../theme/colors';

export default function ProfileSettingsScreen() {
  const router = useRouter();
  const scheme = useColorScheme();
  const colors = scheme === 'dark' ? darkColors : lightColors;

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: colors.background }}
      contentContainerStyle={{ paddingBottom: 120 }}
    >
      <View style={styles.container}>
        <Text style={[styles.title, { color: colors.text }]}>
          Profile Settings
        </Text>

        <View
          style={[
            styles.card,
            { backgroundColor: colors.card, borderColor: colors.border },
          ]}
        >
          <Pressable style={styles.row}>
            <Text style={[styles.label, { color: colors.text }]}>
              Change profile photo
            </Text>
          </Pressable>

          <Pressable style={styles.row}>
            <Text style={[styles.label, { color: colors.text }]}>Edit name</Text>
          </Pressable>

          <Pressable style={styles.row}>
            <Text style={[styles.label, { color: colors.text }]}>
              Edit username
            </Text>
          </Pressable>
        </View>

        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.textSecondary }]}>
            Travel Preferences
          </Text>

          <View
            style={[
              styles.card,
              { backgroundColor: colors.card, borderColor: colors.border },
            ]}
          >
            <Pressable style={styles.row}>
              <Text style={[styles.label, { color: colors.text }]}>
                Travel mode
              </Text>
            </Pressable>

            <Pressable style={styles.row}>
              <Text style={[styles.label, { color: colors.text }]}>
                Travel style
              </Text>
            </Pressable>
          </View>
        </View>

        <View
          style={[
            styles.card,
            { backgroundColor: colors.card, borderColor: colors.border },
          ]}
        >
          <Pressable style={styles.row}>
            <Text style={styles.signOut}>Sign Out</Text>
          </Pressable>

          <Pressable style={styles.row}>
            <Text style={styles.delete}>Delete Account</Text>
          </Pressable>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 20,
    paddingTop: 24,
  },
  title: {
    fontSize: 34,
    fontWeight: '700',
    marginBottom: 28,
  },
  section: {
    marginTop: 28,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 12,
  },
  card: {
    borderRadius: 22,
    paddingHorizontal: 20,
    paddingVertical: 6,
    borderWidth: 1,
    marginBottom: 24,
  },
  row: {
    paddingVertical: 18,
  },
  label: {
    fontSize: 16,
    fontWeight: '500',
  },
  signOut: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FF5A5F',
  },
  delete: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FF3B30',
  },
});