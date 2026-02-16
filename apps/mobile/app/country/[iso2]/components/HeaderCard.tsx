import { View, Text, StyleSheet, useColorScheme } from 'react-native';
import { lightColors, darkColors } from '../../../../theme/colors';
import ScorePill from '../../../../components/ScorePill';

type Props = {
  name: string;
  subregion?: string;
  region?: string;
  score: number;
  flagEmoji?: string;
};

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

      <ScorePill score={Math.round(score)} size="lg" />
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
});