import React, { useMemo, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  LayoutAnimation,
  UIManager,
  Platform,
  useColorScheme,
} from 'react-native';
import CountryFlag from 'react-native-country-flag';
import { Ionicons } from '@expo/vector-icons';

if (Platform.OS === 'android') {
  UIManager.setLayoutAnimationEnabledExperimental?.(true);
}

type Props = {
  title: string;
  countries: string[];
};

export default function CollapsibleCountrySection({
  title,
  countries = [],
}: Props) {
  const [expanded, setExpanded] = useState(true);
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';

  const sortedCountries = useMemo(
    () =>
      Array.isArray(countries)
        ? [...countries].filter(Boolean).sort()
        : [],
    [countries]
  );

  const toggle = () => {
    LayoutAnimation.easeInEaseOut();
    setExpanded((prev) => !prev);
  };

  const backgroundColor = isDark ? '#18181B' : '#FFFFFF';
  const borderColor = isDark ? '#27272A' : '#E5E7EB';
  const titleColor = isDark ? '#FFFFFF' : '#111827';
  const mutedColor = isDark ? '#71717A' : '#9CA3AF';

  return (
    <View
      style={[
        styles.container,
        {
          backgroundColor,
          borderColor,
        },
      ]}
    >
      <Pressable style={styles.header} onPress={toggle}>
        <View style={styles.headerLeft}>
          <Ionicons
            name={expanded ? 'chevron-down' : 'chevron-forward'}
            size={18}
            color={titleColor}
          />
          <Text style={[styles.title, { color: titleColor }]}>
            {title}
          </Text>
        </View>

        <Text style={[styles.count, { color: mutedColor }]}>
          {sortedCountries.length}
        </Text>
      </Pressable>

      {expanded && (
        <View style={styles.content}>
          {sortedCountries.length === 0 ? (
            <Text style={[styles.emptyText, { color: mutedColor }]}>
              No countries yet
            </Text>
          ) : (
            <View style={styles.flagsRow}>
              {sortedCountries.map((code, index) => (
                <CountryFlag
                  key={`${code}-${index}`}
                  isoCode={code}
                  size={26}
                  style={styles.flag}
                />
              ))}
            </View>
          )}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginTop: 18,
    paddingVertical: 16,
    paddingHorizontal: 16,
    borderRadius: 20,
    borderWidth: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 6,
  },
  count: {
    fontSize: 14,
    fontWeight: '500',
  },
  content: {
    marginTop: 14,
  },
  flagsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  flag: {
    marginRight: 10,
    marginBottom: 10,
  },
  emptyText: {
    fontSize: 14,
  },
});