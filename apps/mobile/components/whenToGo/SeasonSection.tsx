import React, { useState } from "react";
import { View, Text, StyleSheet } from "react-native";
import CountryChip from "./CountryChip";
import CountryDetailPreviewDrawer from "./CountryDetailPreviewDrawer";

type Country = {
  name: string;
  region: string;
  score: number;
  iso2: string;
  flagEmoji?: string;
  facts?: any;
};

export default function SeasonSection({
  title,
  description,
  countries,
  selectedMonth,
}: {
  title: string;
  description: string;
  countries: Country[];
  selectedMonth: number;
}) {
  const [selectedCountry, setSelectedCountry] = useState<Country | null>(null);
  const [drawerVisible, setDrawerVisible] = useState(false);

  const handleOpen = (country: Country) => {
    setSelectedCountry(country);
    setDrawerVisible(true);
  };

  const handleClose = () => {
    setDrawerVisible(false);
    setSelectedCountry(null);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.description}>{description}</Text>

      <View style={styles.chips}>
        {countries.map((c) => (
          <CountryChip
            key={c.iso2}
            {...c}
            onPress={() => handleOpen(c)}
          />
        ))}
      </View>

      <CountryDetailPreviewDrawer
        visible={drawerVisible}
        onClose={handleClose}
        country={selectedCountry}
        selectedMonth={selectedMonth}
      />
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