import { View, Text, StyleSheet, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Country } from '../types/Country';

type Props = {
  country: Country;
  onPress: () => void;
  isBucketed: boolean;
  onToggleBucket: () => void;
  isVisited: boolean;
  onToggleVisited: () => void;
};

function getScoreColor(score: number) {
  if (score >= 80) return '#4CAF50';
  if (score >= 60) return '#FBC02D';
  return '#E57373';
}

function isoToFlag(iso2: string) {
  return iso2
    .toUpperCase()
    .replace(/./g, char =>
      String.fromCodePoint(127397 + char.charCodeAt(0))
    );
}

export default function CountryRow({
  country,
  onPress,
  isBucketed,
  onToggleBucket,
  isVisited,
  onToggleVisited,
}: Props) {
  const score = country.facts?.scoreTotal ?? 0;
  const advisoryLevel = country.facts?.advisoryLevel;
  const color = getScoreColor(score);

  return (
    <Pressable onPress={onPress} style={styles.container}>
      <View style={styles.left}>
        <Text style={styles.flag}>{isoToFlag(country.iso2)}</Text>

        <View>
          <Text style={styles.name}>{country.name}</Text>
          {advisoryLevel !== undefined && (
            <Text style={styles.level}>Level {advisoryLevel}</Text>
          )}
        </View>
      </View>

      <View style={styles.rightSection}>
        <View style={[styles.scorePill, { backgroundColor: `${color}20` }]}> 
          <Text style={[styles.scoreText, { color }]}>{score}</Text>
        </View>

        {/* Bucket Toggle */}
        <Pressable
          onPress={(e) => {
            e.stopPropagation();
            onToggleBucket();
          }}
          hitSlop={10}
          style={styles.iconButton}
        >
          <Ionicons
            name={isBucketed ? 'bookmark' : 'bookmark-outline'}
            size={22}
            color={isBucketed ? '#111827' : '#C7C7CC'}
          />
        </Pressable>

        {/* Visited Toggle */}
        <Pressable
          onPress={(e) => {
            e.stopPropagation();
            onToggleVisited();
          }}
          hitSlop={10}
          style={styles.iconButton}
        >
          <Ionicons
            name={isVisited ? 'checkmark-circle' : 'checkmark-circle-outline'}
            size={22}
            color={isVisited ? '#4CAF50' : '#C7C7CC'}
          />
        </Pressable>

        <Text style={styles.chevron}>›</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 18,
    borderBottomWidth: 1,
    borderColor: '#F0F0F0',
  },
  left: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  rightSection: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  flag: {
    fontSize: 28,
    marginRight: 14,
  },
  name: {
    fontSize: 16,
    fontWeight: '600',
  },
  level: {
    fontSize: 13,
    color: '#8E8E93',
    marginTop: 2,
  },
  scorePill: {
    borderRadius: 20,
    paddingHorizontal: 14,
    paddingVertical: 6,
    marginRight: 10,
  },
  scoreText: {
    fontWeight: '600',
    fontSize: 14,
  },
  iconButton: {
    marginRight: 10,
  },
  chevron: {
    fontSize: 20,
    color: '#C7C7CC',
  },
});