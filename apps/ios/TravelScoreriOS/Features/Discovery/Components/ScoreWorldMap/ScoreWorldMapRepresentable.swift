//
//  ScoreWorldMapRepresentable.swift
//  TravelScoreriOS
//

import SwiftUI
import MapKit

struct ScoreWorldMapRepresentable: UIViewRepresentable {
    
    private let instanceId = UUID()
    private static var cachedPolygons: [MKOverlay]?
    
    let countries: [Country]
    let highlightedISOs: [String]
    @Binding var selectedCountryISO: String?
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        let config = MKStandardMapConfiguration(elevationStyle: .flat)
        mapView.preferredConfiguration = config
        
        mapView.mapType = .mutedStandard
        mapView.showsBuildings = false
        mapView.pointOfInterestFilter = .excludingAll
        
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
        
        loadPolygons(into: mapView)
        
        context.coordinator.mapView = mapView
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(ScoreWorldMapCoordinator.handleTap(_:))
        )
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.updateHighlights(highlightedISOs)
        
        guard let iso = selectedCountryISO?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        else { return }
        
        if context.coordinator.lastZoomedISO == iso { return }
        
        context.coordinator.zoomToCountry(iso: iso)
    }
    
    static func dismantleUIView(_ uiView: MKMapView, coordinator: ScoreWorldMapCoordinator) {
        uiView.delegate = nil
        uiView.removeOverlays(uiView.overlays)
        uiView.gestureRecognizers?.forEach { uiView.removeGestureRecognizer($0) }
    }
    
    func makeCoordinator() -> ScoreWorldMapCoordinator {
        ScoreWorldMapCoordinator(
            countries: countries,
            highlightedISOs: highlightedISOs,
            selectedCountryISO: $selectedCountryISO
        )
    }
}

// MARK: - Private Helpers

private extension ScoreWorldMapRepresentable {
    
    func loadPolygons(into mapView: MKMapView) {
        
        if let polygons = Self.cachedPolygons {
            mapView.addOverlays(polygons)
            DispatchQueue.main.async { isLoading = false }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let polygons = WorldGeoJSONLoader.loadPolygons()
            
            DispatchQueue.main.async {
                Self.cachedPolygons = polygons
                mapView.addOverlays(polygons)
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
    }
}
