import React from 'react';
import { View, Text, StyleSheet, useColorScheme } from 'react-native';

type Props = {
  title: string;
  value: string;
  hideValuePadding?: boolean;
};

export default function InfoCard({ title, value, hideValuePadding }: Props) {
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';

  return (
    <View style={[styles.card, isDark && styles.cardDark]}>
      <Text style={[styles.title, isDark && styles.titleDark]}>
        {title}
      </Text>
      <Text
        style={[
          styles.value,
          isDark && styles.valueDark,
          hideValuePadding && { marginTop: 0 },
        ]}
      >
        {value}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    padding: 16,
    marginBottom: 14,
  },
  cardDark: {
    backgroundColor: '#0F172A',
  },
  title: {
    fontSize: 17,
    fontWeight: '700',
    color: '#111827',
  },
  value: {
    marginTop: 8,
    fontSize: 16,
    color: '#111827',
  },
  titleDark: {
    color: '#F9FAFB',
  },
  valueDark: {
    color: '#CBD5E1',
  },
});