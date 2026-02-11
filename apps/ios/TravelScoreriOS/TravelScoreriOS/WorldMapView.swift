//
//  WorldMapView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/11/26.
//

import Foundation
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

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 140, longitudeDelta: 360)
        )

        mapView.setRegion(region, animated: false)

        let polygons = WorldGeoJSONLoader.loadPolygons()
        mapView.addOverlays(polygons)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.highlightedCountryCodes = highlightedCountryCodes
        uiView.setNeedsDisplay()
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
            guard let polygon = overlay as? MKPolygon else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolygonRenderer(polygon: polygon)

            renderer.strokeColor = UIColor.clear

            // Basic highlight logic placeholder
            renderer.fillColor = UIColor.systemGray.withAlphaComponent(0.2)

            return renderer
        }
    }
}
