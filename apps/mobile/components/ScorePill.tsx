import React from "react";
import { View, Text, StyleSheet } from "react-native";

function getScoreColors(score: number) {
  if (score >= 80) {
    return { bg: "#EAFBF1", border: "#6EE7B7", text: "#065F46" };
  }
  if (score >= 50) {
    return { bg: "#FFF7E6", border: "#FBBF24", text: "#92400E" };
  }
  return { bg: "#FEECEC", border: "#F87171", text: "#7F1D1D" };
}

type Props = {
  score: number;
  size?: "sm" | "md" | "lg";
};

export default function ScorePill({ score, size = "md" }: Props) {
  const colors = getScoreColors(score);

  const sizeStyles =
    size === "sm"
      ? { width: 44, height: 44 }
      : size === "lg"
      ? { width: 64, height: 64 }
      : { width: 54, height: 54 };

  return (
    <View
      style={[
        styles.pill,
        sizeStyles,
        {
          backgroundColor: colors.bg,
          borderColor: colors.border,
        },
      ]}
    >
      <Text style={[styles.text, { color: colors.text }]}>{score}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    borderWidth: 2,
    borderRadius: 999,
    alignItems: "center",
    justifyContent: "center",
  },
  text: {
    fontWeight: "800",
    fontSize: 18,
  },
});