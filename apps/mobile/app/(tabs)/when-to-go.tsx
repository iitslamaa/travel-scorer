import React, { useState, useMemo } from "react";
import { ScrollView, View, Text, StyleSheet, ActivityIndicator } from "react-native";
import MonthSelector from "../../components/whenToGo/MonthSelector";
import SummaryPills from "../../components/whenToGo/SummaryPills";
import SeasonSection from "../../components/whenToGo/SeasonSection";
import { useCountries } from "../../hooks/useCountries";
import { getWhenToGoBuckets } from "../../utils/whenToGoLogic";

export default function WhenToGoScreen() {
  const [selectedMonth, setSelectedMonth] = useState(1); // 0 = Jan

  const { countries, loading } = useCountries();

  const { peak, shoulder } = useMemo(() => {
    return getWhenToGoBuckets(countries, selectedMonth);
  }, [countries, selectedMonth]);

  const monthLabels = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  ];

  if (loading) {
    return (
      <View style={[styles.container, styles.center]}>
        <ActivityIndicator />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.header}>When to Go</Text>
      <Text style={styles.subtitle}>
        Select a month to explore where it’s peak or shoulder season.
      </Text>

      <MonthSelector
        selected={selectedMonth}
        onSelect={setSelectedMonth}
      />

      <View style={styles.summaryRow}>
        <View>
          <Text style={styles.muted}>Selected month</Text>
          <Text style={styles.month}>
            {monthLabels[selectedMonth]}
          </Text>
        </View>

        <SummaryPills
          peak={peak.length}
          shoulder={shoulder.length}
        />
      </View>

      <SeasonSection
        title="Peak season"
        description="Best weather and overall conditions — usually the busiest and priciest."
        countries={peak}
      />

      <SeasonSection
        title="Shoulder season"
        description="Still good conditions, often fewer crowds and better value."
        countries={shoulder}
      />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
  },
  center: {
    justifyContent: "center",
    alignItems: "center",
  },
  header: {
    fontSize: 28,
    fontWeight: "800",
  },
  subtitle: {
    opacity: 0.6,
    marginVertical: 8,
  },
  summaryRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginTop: 12,
    marginBottom: 8,
  },
  muted: {
    opacity: 0.6,
    marginBottom: 4,
  },
  month: {
    fontSize: 18,
    fontWeight: "700",
  },
});