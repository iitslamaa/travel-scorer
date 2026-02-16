import React from "react";
import { ScrollView, TouchableOpacity, Text, StyleSheet, View } from "react-native";

const months = [
  "JAN","FEB","MAR","APR","MAY","JUN",
  "JUL","AUG","SEP","OCT","NOV","DEC"
];

type Props = {
  selected: number;
  onSelect: (index: number) => void;
};

export default function MonthSelector({ selected, onSelect }: Props) {
  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false}>
      <View style={styles.row}>
        {months.map((m, i) => {
          const isSelected = i === selected;
          return (
            <TouchableOpacity
              key={m}
              style={[
                styles.pill,
                isSelected && styles.selected
              ]}
              onPress={() => onSelect(i)}
            >
              <Text style={[
                styles.text,
                isSelected && styles.selectedText
              ]}>
                {m}
              </Text>
              <Text style={[
                styles.sub,
                isSelected && styles.selectedText
              ]}>
                {String(i+1).padStart(2,"0")}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
  },
  pill: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: "#E5E5EA",
    alignItems: "center",
    justifyContent: "center",
    marginRight: 8,
  },
  selected: {
    backgroundColor: "#000",
  },
  text: {
    fontWeight: "600",
  },
  sub: {
    fontSize: 12,
  },
  selectedText: {
    color: "#FFF",
  },
});