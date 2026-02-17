import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Image,
  useColorScheme,
} from 'react-native';

type Props = {
  name: string;
  handle: string;
  avatarUrl?: string;
  flags?: string[];
};

export default function HeaderCard({
  name,
  handle,
  avatarUrl,
  flags = [],
}: Props) {
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';

  return (
    <View style={[styles.card, isDark && styles.cardDark]}>
      <View style={styles.row}>
        <View style={styles.avatarWrapper}>
          {avatarUrl ? (
            <Image source={{ uri: avatarUrl }} style={styles.avatar} />
          ) : (
            <View style={[styles.avatarFallback, isDark && styles.avatarFallbackDark]} />
          )}
        </View>

        <View style={styles.meta}>
          <Text style={[styles.name, isDark && styles.textDark]}>
            {name}
          </Text>

          <Text style={[styles.handle, isDark && styles.subTextDark]}>
            {handle}
          </Text>

          <View style={styles.flagsRow}>
            {flags.map((f) => (
              <Text key={f} style={styles.flag}>
                {f}
              </Text>
            ))}
          </View>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    padding: 18,
    marginBottom: 18,
  },
  cardDark: {
    backgroundColor: '#0F172A',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatarWrapper: {
    marginRight: 16,
  },
  avatar: {
    width: 92,
    height: 92,
    borderRadius: 46,
  },
  avatarFallback: {
    width: 92,
    height: 92,
    borderRadius: 46,
    backgroundColor: '#E5E7EB',
  },
  avatarFallbackDark: {
    backgroundColor: '#334155',
  },
  meta: {
    flex: 1,
  },
  name: {
    fontSize: 24,
    fontWeight: '800',
    color: '#111827',
  },
  handle: {
    marginTop: 4,
    fontSize: 16,
    color: '#6B7280',
  },
  flagsRow: {
    marginTop: 8,
    flexDirection: 'row',
  },
  flag: {
    fontSize: 18,
    marginRight: 8,
  },
  textDark: {
    color: '#F9FAFB',
  },
  subTextDark: {
    color: '#94A3B8',
  },
});