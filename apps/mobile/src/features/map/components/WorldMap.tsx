import React, { useEffect, useMemo, useRef, useState } from 'react';
import MapView, { PROVIDER_GOOGLE, LatLng } from 'react-native-maps';
import { View } from 'react-native';
import { useGeoJson } from '../hooks/useGeoJson';
import { CountryPolygon } from './CountryPolygon';

import { buildCountryOverlay } from '../utils/buildCountryOverlay';

function convertPolygon(coords: number[][]): LatLng[] {
  return coords.map(([lng, lat]) => ({
    latitude: lat,
    longitude: lng,
  }));
}

function extractPolygons(feature: any): LatLng[][] {
  const { geometry } = feature;

  if (!geometry) return [];

  if (geometry.type === 'Polygon') {
    // geometry.coordinates: number[][][]
    return geometry.coordinates.map((ring: number[][]) =>
      convertPolygon(ring)
    );
  }

  if (geometry.type === 'MultiPolygon') {
    // geometry.coordinates: number[][][][]
    return geometry.coordinates.flatMap((polygon: number[][][]) =>
      polygon.map((ring: number[][]) => convertPolygon(ring))
    );
  }

  return [];
}

 type WorldMapProps = {
  countries?: string[];
  selectedIso?: string | null;
  onSelect?: (iso: string) => void;
};

export function WorldMap({
  countries = [],
  selectedIso,
  onSelect,
}: WorldMapProps) {
  const { features } = useGeoJson();

  const mapRef = useRef<MapView | null>(null);
  const [isMapReady, setIsMapReady] = useState(false);

  const polygons = useMemo(() => {
    return features.flatMap((feature: any, featureIndex: number) => {
      const iso =
        feature.properties?.ISO_A2 ??
        feature.properties?.iso_a2 ??
        'NO_ISO';

      // 🚫 Completely skip Antarctica (huge polygon causes touch issues)
      if (iso === 'AQ') return [];

      const rings = extractPolygons(feature);

      return rings.map((coords, ringIndex) => ({
        key: `${iso}-${featureIndex}-${ringIndex}`,
        iso,
        coords,
      }));
    });
  }, [features]);

  const polygonsForFit = useMemo(() => {
    if (!countries || countries.length === 0) return [];

    const upper = countries.map((c) => c.toUpperCase());
    return polygons.filter((p) => upper.includes(p.iso));
  }, [countries, polygons]);

  useEffect(() => {
    console.log('Geo features:', features.length);
    console.log('Polygon rings:', polygons.length);

    if (!isMapReady) return;

    const target = polygonsForFit.length > 0 ? polygonsForFit : [];
    if (target.length === 0) return;

    const allCoords: LatLng[] = [];
    for (const ring of target) {
      allCoords.push(...ring.coords);
    }

    // Wait one tick to ensure layout is ready
    setTimeout(() => {
      mapRef.current?.fitToCoordinates(allCoords, {
        edgePadding: { top: 40, right: 40, bottom: 40, left: 40 },
        animated: false,
      });
    }, 0);
  }, [polygonsForFit, isMapReady]);

  useEffect(() => {
    if (!isMapReady) return;
    if (!selectedIso) return;

    const selected = polygonsForFit.filter(
      (p) => p.iso === selectedIso
    );

    if (selected.length === 0) return;

    const coords: LatLng[] = [];
    for (const ring of selected) {
      coords.push(...ring.coords);
    }

    setTimeout(() => {
      mapRef.current?.fitToCoordinates(coords, {
        edgePadding: { top: 80, right: 80, bottom: 80, left: 80 },
        animated: true,
      });
    }, 0);
  }, [selectedIso, isMapReady, polygonsForFit]);

  return (
    <View style={{ flex: 1 }}>
      <MapView
        provider={PROVIDER_GOOGLE}
        style={{ flex: 1 }}
        ref={(ref) => {
          mapRef.current = ref;
        }}
        onMapReady={() => setIsMapReady(true)}
        initialRegion={{
          latitude: 20,
          longitude: 0,
          latitudeDelta: 60,
          longitudeDelta: 60,
        }}
      >
        {polygonsForFit.map((item) => {
          const { key, iso, coords } = item;
          return (
            <CountryPolygon
              key={key}
              iso={iso}
              coordinates={coords}
              overlay={buildCountryOverlay({
                iso,
                selectedIso: selectedIso ?? undefined,
              })}
              onPress={(iso) => {
                onSelect?.(iso);
              }}
            />
          );
        })}
      </MapView>
    </View>
  );
}