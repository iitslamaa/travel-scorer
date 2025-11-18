/* eslint-disable @typescript-eslint/no-explicit-any */

// apps/web/components/map/WorldMap.tsx
"use client";

import "leaflet/dist/leaflet.css";
import { MapContainer, TileLayer, CircleMarker, Tooltip } from "react-leaflet";
const LeafletMapContainer = MapContainer as any;
const LeafletTileLayer = TileLayer as any;
const LeafletCircleMarker = CircleMarker as any;
const LeafletTooltip = Tooltip as any;
import type { Airport } from "../../../../packages/data/src";

interface WorldMapProps {
  airports: Airport[];
}

export default function WorldMap({ airports }: WorldMapProps) {
  return (
    <div className="h-[480px] w-full overflow-hidden rounded-2xl border border-neutral-200 bg-white shadow-sm">
      <LeafletMapContainer
        center={[20, 0]} // roughly “world view”
        zoom={2}
        style={{ height: "100%", width: "100%" }}
        scrollWheelZoom={true}
      >
        <LeafletTileLayer
          attribution='&copy; OpenStreetMap contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {airports.map((airport) => (
          <LeafletCircleMarker
            key={airport.iata}
            center={[airport.lat, airport.lon]}
            radius={6}
            stroke={false}
            fillOpacity={0.9}
          >
            <LeafletTooltip direction="top" offset={[0, -4]} opacity={1}>
              <div className="text-xs">
                <div className="font-semibold">{airport.iata}</div>
                <div>{airport.cityName}</div>
              </div>
            </LeafletTooltip>
          </LeafletCircleMarker>
        ))}
      </LeafletMapContainer>
    </div>
  );
}