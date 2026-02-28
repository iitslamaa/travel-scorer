//
//  WorldGeoJSONLoader.swift
//


import Foundation
import MapKit

class CountryPolygon: MKMultiPolygon {
    var isoCode: String?
    var countryName: String?
}

struct WorldGeoJSONLoader {

    // Full-detail cache
    private static var cachedPolygons: [CountryPolygon]?

    // Simplified (LOD) cache for world/low-zoom rendering
    private static var cachedSimplifiedPolygons: [CountryPolygon]?

    // RN parity: ISO3 -> ISO2 map (optional file: iso3_to_iso2.json)
    private static var iso3ToIso2: [String: String] = {
        guard
            let url = Bundle.main.url(forResource: "iso3_to_iso2", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else {
            return [:]
        }
        return json.reduce(into: [String: String]()) { result, pair in
            result[pair.key.uppercased()] = pair.value.uppercased()
        }
    }()

    private static func normalizeIso(_ value: String?) -> String? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
              raw != "-99"
        else { return nil }

        if raw == "UK" { return "GB" }
        if raw.count == 2 { return raw }
        return nil
    }

    // MARK: - Simplification (Basic LOD)

    private static func simplifiedPolygon(from polygon: MKPolygon) -> MKPolygon {
        let count = polygon.pointCount

        // For small polygons, do not simplify
        if count < 200 {
            return polygon
        }

        let points = polygon.points()
        var coords: [CLLocationCoordinate2D] = []
        coords.reserveCapacity(count)

        for i in 0..<count {
            let coord = points[i].coordinate
            coords.append(coord)
        }

        // Downsample aggressively for very large coastlines
        let strideAmount: Int
        if count > 8000 {
            strideAmount = 12
        } else if count > 4000 {
            strideAmount = 8
        } else if count > 2000 {
            strideAmount = 5
        } else {
            strideAmount = 3
        }

        var simplified: [CLLocationCoordinate2D] = []
        simplified.reserveCapacity(coords.count / strideAmount + 1)

        for i in stride(from: 0, to: coords.count, by: strideAmount) {
            simplified.append(coords[i])
        }

        // Ensure ring closes properly
        if let first = simplified.first,
           let last = simplified.last,
           first.latitude != last.latitude || first.longitude != last.longitude {
            simplified.append(first)
        }

        return MKPolygon(coordinates: simplified, count: simplified.count)
    }

    private static func simplifiedCountryPolygon(from country: CountryPolygon) -> CountryPolygon {
        let simplifiedPolygons = country.polygons.map { simplifiedPolygon(from: $0) }
        let newCountry = CountryPolygon(simplifiedPolygons)
        newCountry.isoCode = country.isoCode
        newCountry.countryName = country.countryName
        return newCountry
    }

    static func loadPolygons(selectedIso: String? = nil) -> [CountryPolygon] {

        // Always use FULL dataset (no simplified switching)
        if let cached = cachedPolygons {
            return cached
        }

        let fileName = "travelaf.world.full"

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "geo.json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ Failed to load \(fileName).geo.json")
            return []
        }

        let decoder = MKGeoJSONDecoder()
        guard let geoObjects = try? decoder.decode(data) else {
            print("❌ GeoJSON decode failed for \(fileName)")
            return []
        }

        var countryPolygonsByISO: [String: [MKPolygon]] = [:]
        var countryNamesByISO: [String: String] = [:]

        for object in geoObjects {
            guard let feature = object as? MKGeoJSONFeature else { continue }

            var iso: String?
            var name: String?

            if let propertiesData = feature.properties,
               let jsonObject = try? JSONSerialization.jsonObject(with: propertiesData) as? [String: Any] {

                name =
                    (jsonObject["name"] as? String)
                    ?? (jsonObject["ADMIN"] as? String)
                    ?? (jsonObject["NAME"] as? String)

                // RN-style layered ISO resolution
                let nameOverrides: [String: String] = [
                    "TAIWAN": "TW",
                    "FRENCH GUIANA": "GF",
                    "MARTINIQUE": "MQ",
                    "GUADELOUPE": "GP",
                    "RÉUNION": "RE",
                    "REUNION": "RE",
                    "MAYOTTE": "YT"
                ]

                let featureName = name?.uppercased()
                let isoA2 = jsonObject["ISO_A2"] as? String
                let isoA2EH = jsonObject["ISO_A2_EH"] as? String
                let postal = jsonObject["POSTAL"] as? String
                let isoA3EH = jsonObject["ISO_A3_EH"] as? String
                let isoA3 = jsonObject["ISO_A3"] as? String
                let shapeGroup = jsonObject["shapeGroup"] as? String

                let rawIso =
                    nameOverrides[featureName ?? ""]
                    ?? normalizeIso(isoA2)
                    ?? normalizeIso(isoA2EH)
                    ?? (postal?.count == 2 ? normalizeIso(postal) : nil)
                    ?? (isoA3EH?.count == 3 ? normalizeIso(String(isoA3EH!.prefix(2))) : nil)
                    ?? (isoA3?.count == 3 ? normalizeIso(String(isoA3!.prefix(2))) : nil)
                    ?? (shapeGroup != nil ? iso3ToIso2[shapeGroup!.uppercased()] : nil)

                iso = normalizeIso(rawIso)
            }

            guard let isoCode = iso else { continue }

            if countryNamesByISO[isoCode] == nil {
                countryNamesByISO[isoCode] = name
            }

            for geometry in feature.geometry {

                // Keep ALL rings (Polygon + MultiPolygon)
                if let polygon = geometry as? MKPolygon {
                    countryPolygonsByISO[isoCode, default: []].append(polygon)
                }
                else if let multiPolygon = geometry as? MKMultiPolygon {
                    for polygon in multiPolygon.polygons {
                        countryPolygonsByISO[isoCode, default: []].append(polygon)
                    }
                }
            }
        }

        var finalPolygons: [CountryPolygon] = []

        for (isoCode, polygons) in countryPolygonsByISO {

            // Skip Antarctica
            if isoCode == "AQ" { continue }

            guard !polygons.isEmpty else { continue }

            let countryPolygon = CountryPolygon(polygons)
            countryPolygon.isoCode = isoCode
            countryPolygon.countryName = countryNamesByISO[isoCode]

            finalPolygons.append(countryPolygon)
        }

        cachedPolygons = finalPolygons

        // Build simplified dataset once
        cachedSimplifiedPolygons = finalPolygons.map {
            simplifiedCountryPolygon(from: $0)
        }

        print("🌎 Loaded FULL dataset overlay count:", finalPolygons.count)

        return finalPolygons
    }

    static func loadSimplifiedPolygons() -> [CountryPolygon] {
        if let cached = cachedSimplifiedPolygons {
            return cached
        }

        // Ensure full dataset is loaded first
        let full = loadPolygons()
        cachedSimplifiedPolygons = full.map {
            simplifiedCountryPolygon(from: $0)
        }

        return cachedSimplifiedPolygons ?? []
    }
}
