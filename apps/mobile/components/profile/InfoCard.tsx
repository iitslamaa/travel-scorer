import React from 'react';
import { View, Text, StyleSheet, useColorScheme } from 'react-native';

type Props = {
  title: string;
  value: React.ReactNode;
  hideValuePadding?: boolean;
};

export default function InfoCard({ title, value, hideValuePadding }: Props) {
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';

  return (
    <View style={[styles.card, isDark ? styles.cardDark : styles.cardLight]}>
      <Text
        style={[
          styles.title,
          isDark ? styles.titleDark : styles.titleLight,
        ]}
      >
        {title}
      </Text>

      {!!value && (
        <Text
          style={[
            styles.value,
            isDark ? styles.valueDark : styles.valueLight,
            hideValuePadding && { marginTop: 0 },
          ]}
        >
          {value}
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 28,
    paddingVertical: 24,
    paddingHorizontal: 22,
    marginBottom: 22,
  },

  cardDark: {
    backgroundColor: '#111111',
  },

  cardLight: {
    backgroundColor: '#FFFFFF',
  },

  title: {
    fontSize: 15,
    fontWeight: '600',
    letterSpacing: 0.3,
  },

  titleDark: {
    color: '#A1A1AA',
  },

  titleLight: {
    color: '#6B7280',
  },

  value: {
    marginTop: 10,
    fontSize: 18,
    fontWeight: '600',
  },

  valueDark: {
    color: '#FFFFFF',
  },

  valueLight: {
    color: '#111827',
  },
});