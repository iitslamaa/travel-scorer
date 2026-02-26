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

    // Cache polygons so we decode only once
    private static var cachedPolygons: [CountryPolygon]?

    static func loadPolygons() -> [CountryPolygon] {

        // Return cached version if available
        if let cached = cachedPolygons {
            return cached
        }

        guard let url = Bundle.main.url(forResource: "countries", withExtension: "geojson"),
              let data = try? Data(contentsOf: url) else {
            return []
        }

        let decoder = MKGeoJSONDecoder()
        var countryPolygonsByISO: [String: [MKPolygon]] = [:]
        var countryNamesByISO: [String: String] = [:]

        guard let geoObjects = try? decoder.decode(data) else {
            return []
        }

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

                let isoA2 =
                    (jsonObject["ISO3166-1-Alpha-2"] as? String)
                    ?? (jsonObject["ISO_A2"] as? String)
                    ?? (jsonObject["iso_a2"] as? String)

                let isoA3 =
                    (jsonObject["ISO_A3"] as? String)
                    ?? (jsonObject["ADM0_A3"] as? String)
                    ?? (jsonObject["iso_a3"] as? String)

                // Canonical ISO handling (Option B: no heuristics, no derived ISO)
                if let iso2 = isoA2?.trimmingCharacters(in: .whitespacesAndNewlines),
                   iso2.count == 2,
                   iso2 != "-99" {
                    iso = iso2.uppercased()
                } else {
                    // Skip features without a valid ISO_A2
                    iso = nil
                }

                if let countryName = name?.uppercased(), countryName.contains("FRANCE") {
                    print("🇫🇷 [GeoJSON] France feature detected name=\(countryName) iso=\(iso ?? "nil") rawISO_A2=\(isoA2 ?? "nil") rawISO_A3=\(isoA3 ?? "nil")")
                }
            }

            guard let isoCode = iso else { continue }

            if countryNamesByISO[isoCode] == nil {
                countryNamesByISO[isoCode] = name
            }

            for geometry in feature.geometry {

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

        print("🧾 GeoJSON ISO codes:", countryPolygonsByISO.keys.sorted())
        var finalPolygons: [CountryPolygon] = []

        for (isoCode, polygons) in countryPolygonsByISO {

            // Skip Antarctica (massive world-span geometry)
            if isoCode == "AQ" { continue }

            guard !polygons.isEmpty else { continue }

            let countryPolygon = CountryPolygon(polygons)
            countryPolygon.isoCode = isoCode
            countryPolygon.countryName = countryNamesByISO[isoCode]

            finalPolygons.append(countryPolygon)
        }

        print("🌎 Final country overlay count:", finalPolygons.count)

        cachedPolygons = finalPolygons
        return finalPolygons
    }
}
