import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  useColorScheme,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

type Props = {
  label: string;
  value: string;
  onPress?: () => void;
};

export default function DisclosureRow({ label, value, onPress }: Props) {
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';

  return (
    <TouchableOpacity
      style={[styles.row, isDark && styles.rowDark]}
      onPress={onPress}
      activeOpacity={0.8}
    >
      <View style={styles.left}>
        <Text style={[styles.label, isDark && styles.labelDark]}>
          {label}
        </Text>

        {!!value && (
          <Text style={[styles.value, isDark && styles.valueDark]}>
            {value}
          </Text>
        )}
      </View>

      <Ionicons
        name="chevron-forward"
        size={20}
        color={isDark ? '#64748B' : '#9CA3AF'}
      />
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  row: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    paddingVertical: 20,
    paddingHorizontal: 20,
    marginBottom: 18,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },

  rowDark: {
    backgroundColor: '#0F172A',
  },

  left: {
    flex: 1,
  },

  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#6B7280',
    letterSpacing: 0.3,
  },

  labelDark: {
    color: '#94A3B8',
  },

  value: {
    marginTop: 6,
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
  },

  valueDark: {
    color: '#F9FAFB',
  },
});