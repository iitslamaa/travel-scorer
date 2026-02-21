"use client";

import { useEffect, useState } from "react";
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
            style={{
              color: "#CBD5E1",
              weight: 1,
              fillColor: "#E2E8F0",
              fillOpacity: 0.4,
            } as any}
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