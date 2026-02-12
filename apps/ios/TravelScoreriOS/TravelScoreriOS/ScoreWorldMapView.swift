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
            
            if let iso = selectedCountryISO,
               let country = countries.first(where: { $0.iso2.uppercased() == iso.uppercased() }) {
                
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

// MARK: - UIKit Map Wrapper

struct ScoreWorldMapRepresentable: UIViewRepresentable {
    
    let countries: [Country]
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
        for overlay in uiView.overlays {
            guard let polygon = overlay as? CountryPolygon,
                  let renderer = uiView.renderer(for: overlay) as? MKPolygonRenderer else { continue }
            
            let iso = polygon.isoCode
            let isSelected = iso == selectedCountryISO
            
            if let iso,
               let country = countries.first(where: { $0.iso2.uppercased() == iso.uppercased() }) {
                renderer.fillColor = UIColor(
                    ScoreColor.background(for: country.score)
                ).withAlphaComponent(0.6)
            } else {
                renderer.fillColor = UIColor.systemGray.withAlphaComponent(0.15)
            }
            
            renderer.strokeColor = isSelected
                ? UIColor.systemYellow
                : UIColor.black.withAlphaComponent(0.2)
            
            renderer.lineWidth = isSelected ? 2.5 : 0.5
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectedCountryISO: $selectedCountryISO)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        
        @Binding var selectedCountryISO: String?
        weak var mapView: MKMapView?
        
        init(selectedCountryISO: Binding<String?>) {
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
                   path.contains(point),
                   let iso = polygon.isoCode {
                    
                    selectedCountryISO = iso
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
            renderer.strokeColor = UIColor.black.withAlphaComponent(0.2)
            renderer.lineWidth = 0.5
            renderer.fillColor = UIColor.systemGray.withAlphaComponent(0.15)
            
            return renderer
        }
    }
}
