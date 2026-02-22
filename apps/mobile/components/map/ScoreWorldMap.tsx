import React, { useMemo, useRef, useState } from "react";
import { View, StyleSheet, Dimensions, Animated, Pressable, Text } from "react-native";
import MapView, { Polygon } from "react-native-maps";
import { useRouter } from "expo-router";
import { useCountries } from "../../hooks/useCountries";
import worldGeo from "../../src/assets/geo/world.geo.json";

const mutedMapStyle = [
  { elementType: "geometry", stylers: [{ color: "#1d2c4d" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#8ec3b9" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#1a3646" }] },
  { featureType: "administrative", elementType: "geometry.stroke", stylers: [{ color: "#4b6878" }] },
  { featureType: "poi", stylers: [{ visibility: "off" }] },
  { featureType: "road", stylers: [{ visibility: "off" }] },
  { featureType: "transit", stylers: [{ visibility: "off" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#0e1626" }] },
];

const { width, height } = Dimensions.get("window");

function getScoreColor(score?: number) {
  if (score == null) return "rgba(180,180,180,0.15)";
  if (score >= 80) return "rgba(52,168,83,0.6)";
  if (score >= 60) return "rgba(251,188,5,0.6)";
  if (score >= 40) return "rgba(255,109,0,0.6)";
  return "rgba(234,67,53,0.6)";
}

export default function ScoreWorldMap() {
  const router = useRouter();
  const mapRef = useRef<MapView>(null);
  const { countries } = useCountries();

  const [selected, setSelected] = useState<any>(null);

  const scoreLookup = useMemo(() => {
    const map: Record<string, number> = {};
    countries.forEach((c) => {
      if (c.iso3) {
        map[String(c.iso3).toUpperCase()] = c.facts?.scoreTotal ?? 0;
      }
    });
    return map;
  }, [countries]);

  const scoreStats = useMemo(() => {
    const values = Object.values(scoreLookup);
    const nonZero = values.filter((v) => (v ?? 0) > 0).length;
    const max = values.length ? Math.max(...values) : 0;
    return { total: values.length, nonZero, max };
  }, [scoreLookup]);

  const handlePress = (feature: any) => {
    if (!feature) return;

    const iso = String(feature.properties?.iso_a3 ?? "").toUpperCase();
    const score = scoreLookup[iso];

    setSelected({
      name: feature.properties?.admin,
      iso2: countries.find(c => c.iso3?.toUpperCase() === iso)?.iso2 ?? iso,
      score,
    });

    const geometry = feature.geometry;
    if (!geometry) return;

    // Collect ALL outer-ring coordinates (Polygon + MultiPolygon safe)
    const rings =
      geometry.type === "Polygon"
        ? [geometry.coordinates[0]]
        : geometry.type === "MultiPolygon"
        ? geometry.coordinates.map((poly: any) => poly[0])
        : [];

    const allCoords = rings.flat().map(([lng, lat]: number[]) => ({
      latitude: lat,
      longitude: lng,
    }));

    if (!allCoords.length) return;

    // Compute bounding box
    let minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    allCoords.forEach(({ latitude, longitude }) => {
      minLat = Math.min(minLat, latitude);
      maxLat = Math.max(maxLat, latitude);
      minLng = Math.min(minLng, longitude);
      maxLng = Math.max(maxLng, longitude);
    });

    const centerLat = (minLat + maxLat) / 2;
    const centerLng = (minLng + maxLng) / 2;

    mapRef.current?.animateToRegion({
      latitude: centerLat,
      longitude: centerLng,
      latitudeDelta: Math.max(5, (maxLat - minLat) * 1.5),
      longitudeDelta: Math.max(5, (maxLng - minLng) * 1.5),
    });
  };

  return (
    <View style={styles.container}>
      <View style={styles.debugPill}>
        <Text style={styles.debugText}>
          Scores: {scoreStats.nonZero}/{scoreStats.total} non-zero (max {scoreStats.max})
        </Text>
      </View>
      <MapView
        ref={mapRef}
        style={StyleSheet.absoluteFill}
        initialRegion={{
          latitude: 20,
          longitude: 0,
          latitudeDelta: 60,
          longitudeDelta: 60,
        }}
        mapType="standard"
        provider={undefined}
        customMapStyle={mutedMapStyle}
      >
        {worldGeo.features.map((feature: any, index: number) => {
          const iso = String(feature.properties?.iso_a3 ?? "").toUpperCase();

          // Exclude Antarctica and invalid ISO entries (Natural Earth sometimes uses -99)
          if (!iso || iso === "ATA" || iso === "-99") return null;

          const score = scoreLookup[iso];
          const fillColor = getScoreColor(score);

          const geometry = feature.geometry;
          if (!geometry) return null;

          const polygons =
            geometry.type === "Polygon"
              ? [geometry.coordinates]
              : geometry.type === "MultiPolygon"
              ? geometry.coordinates
              : [];

          return polygons.map((poly: any, polyIndex: number) => {
            const coordinates = poly[0].map(([lng, lat]: number[]) => ({
              latitude: lat,
              longitude: lng,
            }));

            return (
              <Polygon
                key={`${iso}-${index}-${polyIndex}`}
                coordinates={coordinates}
                strokeColor="rgba(0,0,0,0.25)"
                strokeWidth={0.6}
                fillColor={fillColor}
                tappable
                onPress={() => handlePress(feature)}
              />
            );
          });
        })}
      </MapView>

      {selected && (
        <View style={styles.card}>
          <Text style={styles.title}>{selected.name}</Text>
          <Text style={styles.score}>Score: {selected.score ?? "N/A"}</Text>

          <Pressable
            style={styles.button}
            onPress={() => {
              router.push(`/country/${selected.iso2}`);
            }}
          >
            <Text style={{ color: "white" }}>View Full Country Page →</Text>
          </Pressable>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "black" },
  debugPill: {
    position: "absolute",
    top: 14,
    left: 14,
    zIndex: 999,
    backgroundColor: "rgba(0,0,0,0.65)",
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 14,
  },
  debugText: {
    color: "white",
    fontSize: 12,
    fontWeight: "600",
  },
  card: {
    position: "absolute",
    bottom: 40,
    left: 20,
    right: 20,
    backgroundColor: "#111",
    padding: 20,
    borderRadius: 20,
  },
  title: {
    color: "white",
    fontSize: 20,
    fontWeight: "600",
    marginBottom: 8,
  },
  score: {
    color: "#aaa",
    marginBottom: 12,
  },
  button: {
    backgroundColor: "#333",
    padding: 12,
    borderRadius: 12,
    alignItems: "center",
  },
});