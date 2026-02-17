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
        <Ionicons
          name="chevron-forward"
          size={18}
          color={isDark ? '#93C5FD' : '#2563EB'}
        />
        <Text style={[styles.label, isDark && styles.labelDark]}>
          {label}
        </Text>
      </View>

      <Text style={[styles.value, isDark && styles.valueDark]}>
        {value}
      </Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  row: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    padding: 16,
    marginBottom: 14,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  rowDark: {
    backgroundColor: '#0F172A',
  },
  left: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  label: {
    marginLeft: 8,
    fontSize: 17,
    fontWeight: '700',
    color: '#2563EB',
  },
  labelDark: {
    color: '#93C5FD',
  },
  value: {
    fontSize: 17,
    fontWeight: '800',
    color: '#F59E0B',
  },
  valueDark: {
    color: '#FBBF24',
  },
});