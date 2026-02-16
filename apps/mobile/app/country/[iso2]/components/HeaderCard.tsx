import { View, Text, StyleSheet, useColorScheme } from 'react-native';
import { lightColors, darkColors } from '../../../../theme/colors';

type Props = {
  name: string;
  subregion?: string;
  region?: string;
  score: number;
  flagEmoji?: string;
};

function getScoreColors(score: number, theme: typeof lightColors) {
  if (score >= 80) {
    return {
      bg: theme.greenBg,
      border: theme.greenBorder,
      text: theme.greenText,
    };
  }
  if (score >= 50) {
    return {
      bg: theme.yellowBg,
      border: theme.yellowBorder,
      text: theme.yellowText,
    };
  }
  return {
    bg: theme.redBg,
    border: theme.redBorder,
    text: theme.redText,
  };
}

export default function HeaderCard({
  name,
  subregion,
  region,
  score,
  flagEmoji,
}: Props) {
  const scheme = useColorScheme();
  const theme = scheme === 'dark' ? darkColors : lightColors;

  const locationLine =
    subregion && region ? `${subregion}, ${region}` : (region ?? subregion ?? '');

  const colors = getScoreColors(score, theme);

  return (
    <View style={[styles.card, { backgroundColor: theme.card }]}>
      <View style={styles.left}>
        {!!flagEmoji && <Text style={styles.flag}>{flagEmoji}</Text>}
        <Text style={[styles.title, { color: theme.textPrimary }]}>
          {name}
        </Text>
        {!!locationLine && (
          <Text style={[styles.subtitle, { color: theme.textSecondary }]}>
            {locationLine}
          </Text>
        )}
      </View>

      <View
        style={[
          styles.scorePill,
          {
            backgroundColor: colors.bg,
            borderColor: colors.border,
          },
        ]}
      >
        <Text style={[styles.scoreText, { color: colors.text }]}>
          {Math.round(score)}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 22,
    paddingVertical: 16,
    paddingHorizontal: 18,
    marginBottom: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',

    shadowColor: '#000',
    shadowOpacity: 0.02,
    shadowRadius: 6,
    elevation: 1,
  },

  left: { flex: 1 },

  flag: {
    fontSize: 34,
    marginBottom: 4,
  },

  title: {
    fontSize: 24,
    fontWeight: '800',
    marginBottom: 4,
  },

  subtitle: {
    fontSize: 16,
    fontWeight: '600',
  },

  scorePill: {
    borderWidth: 1.5,
    paddingHorizontal: 18,
    paddingVertical: 8,
    borderRadius: 999,
    minWidth: 64,
    alignItems: 'center',
  },

  scoreText: {
    fontSize: 18,
    fontWeight: '800',
  },
});