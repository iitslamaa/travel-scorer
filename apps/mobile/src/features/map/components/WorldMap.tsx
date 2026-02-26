import React, { useEffect, useMemo, useRef, useState } from 'react';
import { View, Platform } from 'react-native';
import type { LatLng } from 'react-native-maps';

let MapView: any;
let PROVIDER_GOOGLE: any;

if (Platform.OS !== 'web') {
  const maps = require('react-native-maps');
  MapView = maps.default;
  PROVIDER_GOOGLE = maps.PROVIDER_GOOGLE;
}

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
    const outerRing = geometry.coordinates?.[0];
    return outerRing ? [convertPolygon(outerRing)] : [];
  }

  if (geometry.type === 'MultiPolygon') {
    return geometry.coordinates
      .map((polygon: number[][][]) => polygon?.[0])
      .filter(Boolean)
      .map((outerRing: number[][]) => convertPolygon(outerRing));
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
  const { fullFeatures, simplifiedFeatures } = useGeoJson();

  const DATASET_ALIAS_MAP: Record<string, string> = {
    GB: 'UK',
    XK: 'RS',
    AQ: undefined as any,
  };

  const normalizeIso = (value?: string | null) => {
    if (!value) return undefined;
    const upper = value.toUpperCase();
    const base = upper.length === 3 ? upper.slice(0, 2) : upper;

    if (DATASET_ALIAS_MAP.hasOwnProperty(base)) {
      return DATASET_ALIAS_MAP[base];
    }

    return base;
  };

  const sourceFeatures = selectedIso ? fullFeatures : simplifiedFeatures;

  const mapRef = useRef<MapView | null>(null);
  const [isMapReady, setIsMapReady] = useState(false);

  const polygons = useMemo(() => {
    return sourceFeatures.flatMap((feature: any, featureIndex: number) => {
      const rawIso =
        feature.properties?.['ISO3166-1-Alpha-2'] ??
        feature.properties?.ISO_A2 ??
        feature.properties?.iso_a2;

      if (
        typeof rawIso !== 'string' ||
        rawIso.length !== 2 ||
        rawIso === '-99'
      ) {
        return [];
      }

      const iso = rawIso.toUpperCase();

      if (iso === 'AQ') return [];

      const rings = extractPolygons(feature);

      return rings.map((coords, ringIndex) => ({
        key: `${iso}-${featureIndex}-${ringIndex}`,
        iso,
        coords,
      }));
    });
  }, [sourceFeatures]);

  const datasetIsoSet = useMemo(() => {
    return new Set(polygons.map((p) => p.iso));
  }, [polygons]);

  const polygonsForFit = useMemo(() => {
    if (!countries || countries.length === 0) return [];

    const normalized = countries
      .map((c) => normalizeIso(c))
      .filter((c): c is string => !!c)
      .filter((c) => datasetIsoSet.has(c));

    return polygons.filter((p) => normalized.includes(p.iso));
  }, [countries, polygons, datasetIsoSet]);

  useEffect(() => {
    if (!isMapReady) return;
    if (!selectedIso) return;

    const selected = polygons.filter(
      (p) => p.iso === normalizeIso(selectedIso)
    );

    if (selected.length === 0) return;

    let minLat = Infinity;
    let maxLat = -Infinity;
    let minLng = Infinity;
    let maxLng = -Infinity;

    for (const ring of selected) {
      for (const point of ring.coords) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }

    const centerLat = (minLat + maxLat) / 2;
    const centerLng = (minLng + maxLng) / 2;

    const latitudeDelta = Math.max((maxLat - minLat) * 1.3, 2);
    const longitudeDelta = Math.max((maxLng - minLng) * 1.3, 2);

    setTimeout(() => {
      mapRef.current?.animateToRegion(
        {
          latitude: centerLat,
          longitude: centerLng,
          latitudeDelta,
          longitudeDelta,
        },
        500
      );
    }, 0);
  }, [selectedIso, isMapReady, polygonsForFit]);

  if (!MapView) {
    return <View style={{ flex: 1 }} />;
  }

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
        {selectedIso
          ? polygons
              .filter((p) => p.iso === normalizeIso(selectedIso))
              .map((item) => {
                const { key, iso, coords } = item;
                return (
                  <CountryPolygon
                    key={key}
                    iso={iso}
                    coordinates={coords}
                    overlay={buildCountryOverlay({
                      iso,
                      selectedIso: normalizeIso(selectedIso),
                      highlightedIsos: countries
                        .map((c) => normalizeIso(c))
                        .filter((c): c is string => !!c)
                        .filter((c) => datasetIsoSet.has(c)),
                    })}
                    onPress={(iso) => {
                      onSelect?.(iso);
                    }}
                  />
                );
              })
          : polygons.map((item) => {
              const { key, iso, coords } = item;
              return (
                <CountryPolygon
                  key={key}
                  iso={iso}
                  coordinates={coords}
                  overlay={buildCountryOverlay({
                    iso,
                    selectedIso: undefined,
                    highlightedIsos: countries
                      .map((c) => normalizeIso(c))
                      .filter((c): c is string => !!c)
                      .filter((c) => datasetIsoSet.has(c)),
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