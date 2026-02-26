//
//  ScoreWorldMapCoordinator.swift
//  TravelScoreriOS
//

import Foundation
import SwiftUI
import MapKit

final class ScoreWorldMapCoordinator: NSObject, MKMapViewDelegate {
    
    private let coordinatorId = UUID()
    
    // MARK: - State
    
    var highlightedISOs: [String]
    var highlightedTokens: Set<String>
    let countryLookup: [String: Country]
    
    @Binding var selectedCountryISO: String?
    weak var mapView: MKMapView?
    
    var lastZoomedISO: String?
    
    // MARK: - Init
    
    init(
        countries: [Country],
        highlightedISOs: [String],
        selectedCountryISO: Binding<String?>
    ) {
        self.highlightedISOs = highlightedISOs.map { $0.uppercased() }
        self.highlightedTokens = ScoreWorldMapRenderer.buildHighlightTokens(from: highlightedISOs)
        self.countryLookup = CountryLookupBuilder.build(from: countries)
        self._selectedCountryISO = selectedCountryISO
        
        super.init()
    }
    
    // MARK: - Tap Handling
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }
        
        let tapPoint = gesture.location(in: mapView)
        let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        let mapPoint = MKMapPoint(coordinate)
        
        for overlay in mapView.overlays {
            guard let polygon = overlay as? CountryPolygon,
                  let renderer = mapView.renderer(for: overlay) as? MKMultiPolygonRenderer else { continue }
            
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
                
                if selectedCountryISO != identifier {
                    selectedCountryISO = identifier
                }
                
                break
            }
        }
    }
    
    // MARK: - Highlight Updates
    
    func updateHighlights(_ newISOs: [String]) {
        self.highlightedISOs = newISOs.map { $0.uppercased() }
        self.highlightedTokens = ScoreWorldMapRenderer.buildHighlightTokens(from: newISOs)
    }
    
    // MARK: - Zoom
    
    func zoomToCountry(iso: String) {
        guard let mapView = mapView else { return }
        
        let matching = mapView.overlays
            .compactMap { $0 as? CountryPolygon }
            .filter { $0.isoCode?.uppercased() == iso }
        
        guard !matching.isEmpty else { return }
        
        zoomToCountry(polygons: matching)
    }
    
    private func zoomToCountry(polygons: [CountryPolygon]) {
        guard let mapView = mapView else { return }
        
        let iso = polygons.first?.isoCode?.uppercased()
        if lastZoomedISO == iso { return }
        lastZoomedISO = iso
        
        if iso == "US" || iso == "USA" {
            let center = CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35)
            let span = MKCoordinateSpan(latitudeDelta: 28.0, longitudeDelta: 60.0)
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
            return
        }
        
        var combinedRect = polygons.first!.boundingMapRect
        for polygon in polygons.dropFirst() {
            combinedRect = combinedRect.union(polygon.boundingMapRect)
        }

        let padding = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
        mapView.setVisibleMapRect(combinedRect, edgePadding: padding, animated: true)
    }
    
    // MARK: - Renderer
    
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        guard let polygon = overlay as? CountryPolygon else {
            return MKOverlayRenderer(overlay: overlay)
        }
        
        return ScoreWorldMapRenderer.makeRenderer(
            for: polygon,
            selectedISO: selectedCountryISO,
            highlightedTokens: highlightedTokens,
            countryLookup: countryLookup
        )
    }
}
