//
//  WorldMapView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/11/26.
//

import SwiftUI
import MapKit

struct WorldMapView: UIViewRepresentable {

    let highlightedCountryCodes: [String]

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

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.highlightedCountryCodes = highlightedCountryCodes

        for overlay in uiView.overlays {
            if let renderer = uiView.renderer(for: overlay) as? MKPolygonRenderer,
               let polygon = overlay as? CountryPolygon,
               let iso = polygon.isoCode {

                if highlightedCountryCodes.contains(iso) {
                    renderer.fillColor = UIColor.systemYellow.withAlphaComponent(0.6)
                } else {
                    renderer.fillColor = UIColor.systemGray.withAlphaComponent(0.2)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(highlightedCountryCodes: highlightedCountryCodes)
    }

    class Coordinator: NSObject, MKMapViewDelegate {

        var highlightedCountryCodes: [String]

        init(highlightedCountryCodes: [String]) {
            self.highlightedCountryCodes = highlightedCountryCodes
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

            guard let polygon = overlay as? CountryPolygon else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = UIColor.clear

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
