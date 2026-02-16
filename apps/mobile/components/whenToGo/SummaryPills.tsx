import React from "react";
import { View, Text, StyleSheet } from "react-native";

export default function SummaryPills({ peak, shoulder }: { peak: number; shoulder: number }) {
  return (
    <View style={styles.container}>
      <View style={[styles.pill, { backgroundColor: "#DDF5E6" }]}>
        <Text>Peak: {peak}</Text>
      </View>

      <View style={[styles.pill, { backgroundColor: "#F8F1C6" }]}>
        <Text>Shoulder: {shoulder}</Text>
      </View>

      <View style={[styles.pill, { backgroundColor: "#ECECEC" }]}>
        <Text>Total: {peak + shoulder}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: "flex-end",
    marginVertical: 12,
  },
  pill: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 999,
    marginVertical: 4,
  },
});