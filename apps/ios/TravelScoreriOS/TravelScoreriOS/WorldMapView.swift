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
        mapView.setRegion(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 140, longitudeDelta: 360)
            ),
            animated: false
        )
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // We'll add highlighting logic in next PR
    }
}
