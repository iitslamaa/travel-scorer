"use client";

import { useEffect, useState, useMemo } from "react";
import "leaflet/dist/leaflet.css";
import dynamic from "next/dynamic";
import type { Airport } from "../../../../packages/data/src";

interface WorldMapProps {
  airports: Airport[];
}

const MapContainer = dynamic(
  () => import("react-leaflet").then((mod) => mod.MapContainer),
  { ssr: false }
) as any;

const TileLayer = dynamic(
  () => import("react-leaflet").then((mod) => mod.TileLayer),
  { ssr: false }
) as any;

const CircleMarker = dynamic(
  () => import("react-leaflet").then((mod) => mod.CircleMarker),
  { ssr: false }
) as any;

const Tooltip = dynamic(
  () => import("react-leaflet").then((mod) => mod.Tooltip),
  { ssr: false }
) as any;

const GeoJSON = dynamic(
  () => import("react-leaflet").then((mod) => mod.GeoJSON),
  { ssr: false }
) as any;

export default function WorldMap({ airports }: WorldMapProps) {
  const [geoData, setGeoData] = useState<any>(null);
  const [selectedIso, setSelectedIso] = useState<string | null>(null);

  useEffect(() => {
    fetch("/world.geo.json")
      .then((res) => res.json())
      .then((data) => setGeoData(data))
      .catch((err) => console.error("Failed to load geojson", err));
  }, []);

  return (
    <div className="h-[480px] w-full overflow-hidden rounded-2xl border border-neutral-200 bg-white shadow-sm">
      <MapContainer
        center={[20, 0] as [number, number]} // roughly “world view”
        zoom={2}
        style={{ height: "100%", width: "100%" }}
        scrollWheelZoom={true}
      >
        <TileLayer
          attribution='&copy; OpenStreetMap contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {geoData && (
          <GeoJSON
            data={geoData}
            style={(feature: any) => {
              const iso =
                feature?.properties?.ISO_A2 ??
                feature?.properties?.iso_a2 ??
                null;

              const isSelected = iso && iso === selectedIso;

              return {
                color: isSelected ? "#000000" : "#CBD5E1",
                weight: isSelected ? 2 : 1,
                fillColor: isSelected
                  ? "rgba(255, 215, 0, 0.6)"
                  : "#E2E8F0",
                fillOpacity: isSelected ? 0.6 : 0.4,
              };
            }}
            onEachFeature={(feature: any, layer: any) => {
              const iso =
                feature?.properties?.ISO_A2 ??
                feature?.properties?.iso_a2 ??
                null;

              if (iso) {
                layer.on({
                  click: () => {
                    setSelectedIso((prev) =>
                      prev === iso ? null : iso
                    );
                  },
                });
              }
            }}
          />
        )}

        {airports.map((airport) => (
          <CircleMarker
            key={airport.iata}
            center={[airport.lat, airport.lon]}
            radius={6}
            stroke={false}
            fillOpacity={0.9}
          >
            <Tooltip>
              <div className="text-xs">
                <div className="font-semibold">{airport.iata}</div>
                <div>{airport.cityName}</div>
              </div>
            </Tooltip>
          </CircleMarker>
        ))}
      </MapContainer>
    </div>
  );
}