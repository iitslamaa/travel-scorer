import React, { useMemo } from 'react';
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

export function WorldMap() {
  const { features } = useGeoJson();

  const polygons = useMemo(() => {
    return features.flatMap((feature: any, featureIndex: number) => {
      const iso = feature.properties?.ISO_A2 ?? feature.properties?.iso_a2 ?? 'NO_ISO';
      const rings = extractPolygons(feature);

      return rings.map((coords, ringIndex) => ({
        key: `${iso}-${featureIndex}-${ringIndex}`,
        iso,
        coords,
      }));
    });
  }, [features]);

  return (
    <View style={{ flex: 1 }}>
      <MapView
        provider={PROVIDER_GOOGLE}
        style={{ flex: 1 }}
        initialRegion={{
          latitude: 20,
          longitude: 0,
          latitudeDelta: 60,
          longitudeDelta: 60,
        }}
      >
        {polygons.map(({ key, iso, coords }) => (
          <CountryPolygon
            key={key}
            iso={iso}
            coordinates={coords}
            overlay={buildCountryOverlay({ iso })}
            onPress={(iso) => {
              console.log('Pressed:', iso);
            }}
          />
        ))}
      </MapView>
    </View>
  );
}