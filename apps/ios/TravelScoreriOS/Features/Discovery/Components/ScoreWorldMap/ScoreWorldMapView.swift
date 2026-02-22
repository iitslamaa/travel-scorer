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
                    highlightedISOs: [],
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
    private let instanceId = UUID()
    
    private static var cachedPolygons: [MKOverlay]?
    
    let countries: [Country]
    let highlightedISOs: [String]
    @Binding var selectedCountryISO: String?
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        print("🧱 makeUIView — instance:", instanceId)
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
            DispatchQueue.main.async {
                isLoading = false
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                let polygons = WorldGeoJSONLoader.loadPolygons()
                DispatchQueue.main.async {
                    ScoreWorldMapRepresentable.cachedPolygons = polygons
                    mapView.addOverlays(polygons)
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
        print("🔄 updateUIView — instance:", instanceId)
        // 🔄 Keep coordinator highlights synced with SwiftUI updates
        context.coordinator.updateHighlights(highlightedISOs)

        let iso = selectedCountryISO?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard let iso else { return }

        // Prevent redundant zoom loops
        if context.coordinator.lastZoomedISO == iso {
            return
        }

        let targetNameLocal = Locale.current.localizedString(forRegionCode: iso)?.uppercased()
        let targetNameEN = Locale(identifier: "en_US").localizedString(forRegionCode: iso)?.uppercased()

        let matching = uiView.overlays
            .compactMap { $0 as? CountryPolygon }
            .filter {
                let geoISO = $0.isoCode?.uppercased()
                let geoName = $0.countryName?.uppercased()

                if let geoISO {
                    if geoISO == iso || geoISO.prefix(2) == iso {
                        return true
                    }
                }

                if let geoName {
                    if let targetNameLocal, geoName == targetNameLocal { return true }
                    if let targetNameEN, geoName == targetNameEN { return true }
                }

                return false
            }

        guard !matching.isEmpty else {
            print("❌ No polygons found for ISO:", iso)
            return
        }

        context.coordinator.zoomToCountry(polygons: matching)
    }
    
    static func dismantleUIView(_ uiView: MKMapView, coordinator: Coordinator) {
        print("🧹 dismantleUIView called — tearing down MKMapView")
        uiView.delegate = nil
        uiView.removeOverlays(uiView.overlays)
        uiView.gestureRecognizers?.forEach { uiView.removeGestureRecognizer($0) }
    }
    
    func makeCoordinator() -> Coordinator {
        print("🧭 makeCoordinator — instance:", instanceId)
        return Coordinator(
            countries: countries,
            highlightedISOs: highlightedISOs,
            selectedCountryISO: $selectedCountryISO
        )
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        private let coordinatorId = UUID()
        
        var highlightedISOs: [String]
        var highlightedTokens: Set<String>
        let countryLookup: [String: Country]
        @Binding var selectedCountryISO: String?
        weak var mapView: MKMapView?
        var lastZoomedISO: String?
        
        init(
            countries: [Country],
            highlightedISOs: [String],
            selectedCountryISO: Binding<String?>
        ) {
            print("🧠 Coordinator init — id:", coordinatorId)
            self.highlightedISOs = highlightedISOs.map { $0.uppercased() }

            var tokens = Set<String>()
            for iso in highlightedISOs {
                let up = iso.uppercased()
                tokens.insert(up)
                tokens.insert(String(up.prefix(2)))
                if let nameLocal = Locale.current.localizedString(forRegionCode: up)?.uppercased() {
                    tokens.insert(nameLocal)
                }
                if let nameEN = Locale(identifier: "en_US").localizedString(forRegionCode: up)?.uppercased() {
                    tokens.insert(nameEN)
                }
            }
            self.highlightedTokens = tokens

            var lookup: [String: Country] = [:]
            for country in countries {
                lookup[country.iso2.uppercased()] = country
                lookup[country.name] = country
            }

            // Normalize overseas territories to parent ISO for scoring
            let franceTerritories = ["GF","GP","MQ","RE","YT","PM","NC","PF","WF"]
            let netherlandsTerritories = ["AW","CW","SX","BQ"]

            for iso in franceTerritories {
                lookup[iso] = lookup["FR"]
            }

            for iso in netherlandsTerritories {
                lookup[iso] = lookup["NL"]
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

                    // Prevent feedback loop if value is identical
                    if selectedCountryISO != identifier {
                        selectedCountryISO = identifier
                    }
                    print("🟡 Selected ISO from tap:", identifier ?? "nil")

                    break
                }
            }
        }
        
        func updateHighlights(_ newISOs: [String]) {
            self.highlightedISOs = newISOs.map { $0.uppercased() }

            var tokens = Set<String>()
            for iso in self.highlightedISOs {
                let up = iso.uppercased()
                tokens.insert(up)
                tokens.insert(String(up.prefix(2)))

                if let nameLocal = Locale.current.localizedString(forRegionCode: up)?.uppercased() {
                    tokens.insert(nameLocal)
                }
                if let nameEN = Locale(identifier: "en_US").localizedString(forRegionCode: up)?.uppercased() {
                    tokens.insert(nameEN)
                }
            }

            self.highlightedTokens = tokens
        }
        
        func zoomToCountry(polygons: [CountryPolygon]) {
            guard let mapView = mapView, !polygons.isEmpty else { return }

            let iso = polygons.first?.isoCode?.uppercased()

            // Prevent redundant zoom loops
            if lastZoomedISO == iso {
                return
            }

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

            let centerMapPoint = MKMapPoint(
                x: combinedRect.midX,
                y: combinedRect.midY
            )

            let center = centerMapPoint.coordinate

            // Convert map rect size into coordinate deltas
            let metersPerPoint = MKMetersPerMapPointAtLatitude(center.latitude)

            let latMeters = combinedRect.size.height * metersPerPoint
            let lonMeters = combinedRect.size.width * metersPerPoint

            // Convert meters to degrees (approximate but stable)
            let latitudeDelta = latMeters / 111_000.0
            let longitudeDelta = lonMeters / (111_000.0 * cos(center.latitude * .pi / 180))

            var safeLatitudeDelta = max(latitudeDelta * 1.3, 2.0)
            var safeLongitudeDelta = max(longitudeDelta * 1.3, 2.0)

            // 🚨 Clamp to MapKit-safe limits to prevent invalid region crashes
            safeLatitudeDelta = min(safeLatitudeDelta, 170)
            safeLongitudeDelta = min(safeLongitudeDelta, 350)

            let span = MKCoordinateSpan(
                latitudeDelta: safeLatitudeDelta,
                longitudeDelta: safeLongitudeDelta
            )

            let region = MKCoordinateRegion(center: center, span: span)

            mapView.setRegion(region, animated: true)
        }
        
        func mapView(_ mapView: MKMapView,
                     rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

            guard let multi = overlay as? CountryPolygon else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKMultiPolygonRenderer(multiPolygon: multi)
            renderer.lineJoin = .round
            renderer.lineCap = .round

            let geoISO = multi.isoCode?.uppercased()
            let geoName = multi.countryName?.uppercased()
            let selected = selectedCountryISO?.uppercased()

            var selectedTokens = Set<String>()
            if let selected {
                selectedTokens.insert(selected)
                selectedTokens.insert(String(selected.prefix(2)))
                if let nameLocal = Locale.current.localizedString(forRegionCode: selected)?.uppercased() {
                    selectedTokens.insert(nameLocal)
                }
                if let nameEN = Locale(identifier: "en_US").localizedString(forRegionCode: selected)?.uppercased() {
                    selectedTokens.insert(nameEN)
                }
            }

            let identifier: String? = {
                if let iso = geoISO, iso != "-99" {
                    return iso
                }
                return geoName
            }()

            let isSelected =
                (geoISO != nil && selectedTokens.contains(geoISO!)) ||
                (geoISO != nil && selectedTokens.contains(String(geoISO!.prefix(2)))) ||
                (geoName != nil && selectedTokens.contains(geoName!))

            // 🔹 Highlight-only mode (e.g. Profile collapsible sections)
            // When no countries are provided, use highlightedTokens instead of score colors.
            if countryLookup.isEmpty {
                let isHighlighted =
                    (geoISO != nil && highlightedTokens.contains(geoISO!)) ||
                    (geoISO != nil && highlightedTokens.contains(String(geoISO!.prefix(2)))) ||
                    (geoName != nil && highlightedTokens.contains(geoName!))

                if isHighlighted {
                    renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.6)
                    renderer.strokeColor = UIColor.systemBlue
                    renderer.lineWidth = 1.5
                } else {
                    renderer.fillColor = UIColor.systemGray.withAlphaComponent(0.15)
                    renderer.strokeColor = UIColor.black.withAlphaComponent(0.2)
                    renderer.lineWidth = 0.5
                }

                return renderer
            }

            if let id = identifier,
               let country = countryLookup[id] {

                let baseColor = UIColor(ScoreColor.background(for: country.score))

                renderer.fillColor = isSelected
                    ? baseColor.withAlphaComponent(0.85)
                    : baseColor.withAlphaComponent(0.6)

            } else {
                renderer.fillColor = UIColor.systemGray.withAlphaComponent(0.15)
            }

            renderer.strokeColor = isSelected
                ? UIColor.systemOrange
                : UIColor.black.withAlphaComponent(0.2)

            renderer.lineWidth = isSelected ? 2.5 : 0.5

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
                
                let baseColor = UIColor(ScoreColor.background(for: country.score))
                return isSelected
                    ? baseColor.withAlphaComponent(0.85)
                    : baseColor.withAlphaComponent(0.6)
            }
            
            return UIColor.systemGray.withAlphaComponent(0.15)
        }
        deinit {
            print("💀 Coordinator DEINIT — id:", coordinatorId)
        }
    }
}
