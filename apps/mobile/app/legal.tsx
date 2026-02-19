

import { ScrollView, View, Text, StyleSheet, useColorScheme } from 'react-native';
import AuthGate from '../components/AuthGate';

export default function LegalScreen() {
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';

  const backgroundColor = isDark ? '#000000' : '#FFFFFF';
  const titleColor = isDark ? '#FFFFFF' : '#111827';
  const bodyColor = isDark ? '#D1D5DB' : '#374151';

  return (
    <AuthGate>
      <ScrollView
        style={{ backgroundColor }}
        contentContainerStyle={styles.content}
      >
        <View style={styles.section}>
          <Text style={[styles.title, { color: titleColor }]}>Legal & Disclaimers</Text>
        </View>

        <View style={styles.section}>
          <Text style={[styles.heading, { color: titleColor }]}>General Information</Text>
          <Text style={[styles.body, { color: bodyColor }]}>
            Travel Adventure Finder provides informational travel insights only. All scores, advisories, and recommendations are intended for general guidance and educational purposes. Seasonality insights are based on historical climate averages and typical travel patterns.
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={[styles.heading, { color: titleColor }]}>Advisories & Safety Scores</Text>
          <Text style={[styles.body, { color: bodyColor }]}>
            Safety advisories and scores are derived from publicly available sources and third-party data. Conditions may change rapidly, and Travel Adventure Finder does not guarantee accuracy, completeness, or timeliness.
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={[styles.heading, { color: titleColor }]}>No Professional Advice</Text>
          <Text style={[styles.body, { color: bodyColor }]}>
            Travel Adventure Finder does not provide legal, medical, or governmental advice. Users should verify information with official sources before making travel decisions.
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={[styles.heading, { color: titleColor }]}>Limitation of Liability</Text>
          <Text style={[styles.body, { color: bodyColor }]}>
            Travel Adventure Finder is not responsible for decisions made based on information presented in the app. Use of this app is at your own discretion.
          </Text>
        </View>

        <View style={{ height: 24 }} />
      </ScrollView>
    </AuthGate>
  );
}

const styles = StyleSheet.create({
  content: {
    paddingHorizontal: 20,
    paddingTop: 24,
    paddingBottom: 40,
  },
  section: {
    marginBottom: 16,
  },
  title: {
    fontSize: 22,
    fontWeight: '600',
  },
  heading: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 6,
  },
  body: {
    fontSize: 14,
    lineHeight: 20,
  },
});