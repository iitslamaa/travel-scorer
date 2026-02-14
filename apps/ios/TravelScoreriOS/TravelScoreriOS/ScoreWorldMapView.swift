//
//  ScoreWorldMapView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/11/26.
//

import Foundation
import SwiftUI
import MapKit

struct ScoreWorldMapView: View {
    
    let countries: [Country]
    @State private var selectedCountryISO: String? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            ScoreWorldMapRepresentable(
                countries: countries,
                selectedCountryISO: $selectedCountryISO
            )
            .edgesIgnoringSafeArea(.all)
            
            if let iso = selectedCountryISO {
                let matchedCountry =
                    countries.first { $0.iso2.uppercased() == iso.uppercased() }
                    ?? countries.first { $0.name == iso }

                if let country = matchedCountry {
                    ScoreCountryDrawerView(
                        country: country,
                        onDismiss: { selectedCountryISO = nil }
                    )
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: selectedCountryISO)
                }
            }
        }
    }
}

// MARK: - UIKit Map Wrapper

struct ScoreWorldMapRepresentable: UIViewRepresentable {
    
    private static var cachedPolygons: [MKOverlay]?
    
    let countries: [Country]
    @Binding var selectedCountryISO: String?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        let config = MKStandardMapConfiguration(elevationStyle: .flat)
        mapView.showsBuildings = false
        mapView.pointOfInterestFilter = .excludingAll
        mapView.preferredConfiguration = config
        
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
        
        if ScoreWorldMapRepresentable.cachedPolygons == nil {
            ScoreWorldMapRepresentable.cachedPolygons = WorldGeoJSONLoader.loadPolygons()
        }

        if let polygons = ScoreWorldMapRepresentable.cachedPolygons {
            mapView.addOverlays(polygons)
        }
        
        context.coordinator.mapView = mapView
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.selectedCountryISO = selectedCountryISO
        
        for overlay in uiView.overlays {
            if let renderer = uiView.renderer(for: overlay) as? MKPolygonRenderer {
                renderer.setNeedsDisplay()
            }
        }
    }
    
    static func dismantleUIView(_ uiView: MKMapView, coordinator: Coordinator) {
        uiView.delegate = nil
        uiView.removeOverlays(uiView.overlays)
        uiView.gestureRecognizers?.forEach { uiView.removeGestureRecognizer($0) }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            countries: countries,
            selectedCountryISO: $selectedCountryISO
        )
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        
        let countryLookup: [String: Country]
        @Binding var selectedCountryISO: String?
        weak var mapView: MKMapView?
        
        init(
            countries: [Country],
            selectedCountryISO: Binding<String?>
        ) {
            var lookup: [String: Country] = [:]
            for country in countries {
                lookup[country.iso2.uppercased()] = country
                lookup[country.name] = country
            }
            self.countryLookup = lookup
            self._selectedCountryISO = selectedCountryISO
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView else { return }
            
            let tapPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            let mapPoint = MKMapPoint(coordinate)
            
            for overlay in mapView.overlays {
                guard let polygon = overlay as? CountryPolygon,
                      let renderer = mapView.renderer(for: overlay) as? MKPolygonRenderer else { continue }
                
                renderer.createPath()
                let point = renderer.point(for: mapPoint)
                
                if let path = renderer.path,
                   path.contains(point) {

                    let identifier: String? = {
                        if let iso = polygon.isoCode, iso != "-99" {
                            return iso
                        }
                        return polygon.countryName
                    }()

                    selectedCountryISO = identifier
                    break
                }
            }
        }
        
        func mapView(_ mapView: MKMapView,
                     rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polygon = overlay as? CountryPolygon else {
                return MKOverlayRenderer(overlay: overlay)
            }
            
            let renderer = MKPolygonRenderer(polygon: polygon)
            
            renderer.lineJoin = .round
            renderer.lineCap = .round
            
            renderer.strokeColor = UIColor.black.withAlphaComponent(0.2)
            renderer.lineWidth = 0.5
            
            renderer.fillColor = fillColor(for: polygon)
            
            return renderer
        }
        
        private func fillColor(for polygon: CountryPolygon) -> UIColor {
            let identifier: String? = {
                if let iso = polygon.isoCode, iso != "-99" {
                    return iso.uppercased()
                }
                return polygon.countryName
            }()
            
            let isSelected = identifier == selectedCountryISO
            
            if let id = identifier,
               let country = countryLookup[id] {
                
                let baseColor = UIColor(
                    ScoreColor.background(for: country.score)
                )
                
                return isSelected
                    ? baseColor.withAlphaComponent(0.85)
                    : baseColor.withAlphaComponent(0.6)
            }
            
            return UIColor.systemGray.withAlphaComponent(0.15)
        }
    }
}
