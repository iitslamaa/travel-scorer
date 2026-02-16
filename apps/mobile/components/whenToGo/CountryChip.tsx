import React from "react";
import { View, Text, StyleSheet } from "react-native";
import { getScoreColor } from "../../utils/seasonColor";

type Props = {
  name: string;
  region: string;
  score: number;
};

export default function CountryChip({ name, region, score }: Props) {
  const colors = getScoreColor(score);

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <Text style={styles.name}>{name}</Text>
      <Text style={styles.region}>{region}</Text>
      <Text style={[styles.score, { color: colors.text }]}>{score}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 999,
    margin: 4,
  },
  name: {
    fontWeight: "600",
    marginRight: 6,
  },
  region: {
    opacity: 0.5,
    marginRight: 6,
    fontSize: 12,
  },
  score: {
    fontWeight: "700",
  },
});