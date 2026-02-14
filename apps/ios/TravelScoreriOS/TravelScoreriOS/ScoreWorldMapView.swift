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
    @State private var isLoadingMap: Bool = true
    @State private var shouldMountMap: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            if shouldMountMap {
                ScoreWorldMapRepresentable(
                    countries: countries,
                    selectedCountryISO: $selectedCountryISO,
                    isLoading: $isLoadingMap
                )
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(!isLoadingMap)
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
            
            if isLoadingMap {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()

                    VStack(spacing: 18) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.1)

                        Text("Preparing your world…")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .shadow(radius: 20)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: isLoadingMap)
            }
            
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
        .onAppear {
            DispatchQueue.main.async {
                shouldMountMap = true
            }
        }
    }
}

// MARK: - UIKit Map Wrapper

struct ScoreWorldMapRepresentable: UIViewRepresentable {
    
    private static var cachedPolygons: [MKOverlay]?
    
    let countries: [Country]
    @Binding var selectedCountryISO: String?
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let startTime = CFAbsoluteTimeGetCurrent()
        // print("🟢 Map makeUIView started")
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
        
        if let polygons = ScoreWorldMapRepresentable.cachedPolygons {
            mapView.addOverlays(polygons)
            isLoading = false
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                let polygons = WorldGeoJSONLoader.loadPolygons()

                DispatchQueue.main.async {
                    ScoreWorldMapRepresentable.cachedPolygons = polygons
                    mapView.addOverlays(polygons)

                    let totalTime = CFAbsoluteTimeGetCurrent() - startTime
                    // print("🟢 Map setup total time:", totalTime)

                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                }
            }
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
