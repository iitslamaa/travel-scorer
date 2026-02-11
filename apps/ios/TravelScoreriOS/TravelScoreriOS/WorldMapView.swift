//
//  WorldMapView.swift
//  TravelScoreriOS
//

import SwiftUI
import MapKit

struct WorldMapView: UIViewRepresentable {

    let highlightedCountryCodes: [String]
    @Binding var selectedCountryISO: String?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = .mutedStandard
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.delegate = context.coordinator

        mapView.setVisibleMapRect(
            MKMapRect.world,
            edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
            animated: false
        )

        let polygons = WorldGeoJSONLoader.loadPolygons()
        mapView.addOverlays(polygons)

        context.coordinator.mapView = mapView

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.highlightedCountryCodes = highlightedCountryCodes

        // Update fill + selection styling
        for overlay in uiView.overlays {
            guard let polygon = overlay as? CountryPolygon,
                  let renderer = uiView.renderer(for: overlay) as? MKPolygonRenderer else { continue }

            let isHighlighted = polygon.isoCode.map { highlightedCountryCodes.contains($0) } ?? false
            let isSelected = polygon.isoCode == selectedCountryISO

            renderer.fillColor = isHighlighted
                ? UIColor.systemYellow.withAlphaComponent(0.6)
                : UIColor.systemGray.withAlphaComponent(0.2)

            renderer.strokeColor = isSelected
                ? UIColor.systemYellow
                : UIColor.black.withAlphaComponent(0.2)

            renderer.lineWidth = isSelected ? 2.5 : 0.5
        }

        // Restore zoom-on-selection (for flag tap)
        if let iso = selectedCountryISO,
           context.coordinator.lastZoomedISO != iso {

            let matchingPolygons = uiView.overlays
                .compactMap { $0 as? CountryPolygon }
                .filter { $0.isoCode == iso }

            if !matchingPolygons.isEmpty {
                context.coordinator.lastZoomedISO = iso
                context.coordinator.zoomToCountry(polygons: matchingPolygons, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            highlightedCountryCodes: highlightedCountryCodes,
            selectedCountryISO: $selectedCountryISO
        )
    }

    class Coordinator: NSObject, MKMapViewDelegate {

        var highlightedCountryCodes: [String]
        @Binding var selectedCountryISO: String?
        weak var mapView: MKMapView?
        var lastZoomedISO: String?

        init(highlightedCountryCodes: [String],
             selectedCountryISO: Binding<String?>) {
            self.highlightedCountryCodes = highlightedCountryCodes
            self._selectedCountryISO = selectedCountryISO
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView else { return }

            let tapPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            let mapPoint = MKMapPoint(coordinate)

            for overlay in mapView.overlays {
                guard let polygon = overlay as? CountryPolygon else { continue }

                guard let renderer = mapView.renderer(for: overlay) as? MKPolygonRenderer else { continue }
                renderer.createPath()

                let point = renderer.point(for: mapPoint)

                if let path = renderer.path, path.contains(point),
                   let iso = polygon.isoCode {

                    selectedCountryISO = iso
                    lastZoomedISO = iso

                    let matching = mapView.overlays
                        .compactMap { $0 as? CountryPolygon }
                        .filter { $0.isoCode == iso }

                    zoomToCountry(polygons: matching, animated: true)
                    break
                }
            }
        }

        func zoomToCountry(polygons: [CountryPolygon], animated: Bool) {
            guard let mapView = mapView, !polygons.isEmpty else { return }

            var combinedRect = polygons.first!.boundingMapRect
            for polygon in polygons.dropFirst() {
                combinedRect = combinedRect.union(polygon.boundingMapRect)
            }

            // Bahamas-friendly framing (as before)
            let expansionFactor: Double = 0.15
            let expandedRect = combinedRect.insetBy(
                dx: -combinedRect.size.width * expansionFactor,
                dy: -combinedRect.size.height * expansionFactor
            )

            mapView.setVisibleMapRect(
                expandedRect,
                edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 110, right: 60),
                animated: animated
            )
        }

        func mapView(_ mapView: MKMapView,
                     rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

            guard let polygon = overlay as? CountryPolygon else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = UIColor.black.withAlphaComponent(0.2)
            renderer.lineWidth = 0.5

            if let iso = polygon.isoCode,
               highlightedCountryCodes.contains(iso) {
                renderer.fillColor = UIColor.systemYellow.withAlphaComponent(0.6)
            } else {
                renderer.fillColor = UIColor.systemGray.withAlphaComponent(0.2)
            }

            return renderer
        }
    }
}
