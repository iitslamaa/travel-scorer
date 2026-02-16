import React from "react";
import { View, Text, StyleSheet } from "react-native";
import CountryChip from "./CountryChip";

type Country = {
  name: string;
  region: string;
  score: number;
};

export default function SeasonSection({
  title,
  description,
  countries,
}: {
  title: string;
  description: string;
  countries: Country[];
}) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.description}>{description}</Text>

      <View style={styles.chips}>
        {countries.map((c, index) => (
          <CountryChip key={index} {...c} />
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginVertical: 16,
  },
  title: {
    fontSize: 18,
    fontWeight: "700",
  },
  description: {
    opacity: 0.6,
    marginBottom: 8,
  },
  chips: {
    flexDirection: "row",
    flexWrap: "wrap",
  },
});