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

    private static func isoFromCountryName(_ name: String) -> String? {
        let upper = name.uppercased()

        for code in Locale.isoRegionCodes {
            if let localized = Locale(identifier: "en_US")
                .localizedString(forRegionCode: code)?
                .uppercased(),
               localized == upper {
                return code
            }
        }
        return nil
    }

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

                // Normalize ISO (prefer ISO_A2, fallback to ISO_A3)
                if let iso2 = isoA2?.trimmingCharacters(in: .whitespacesAndNewlines),
                   iso2 != "-99",
                   iso2.count == 2 {
                    iso = iso2.uppercased()
                } else if let iso3 = isoA3?.trimmingCharacters(in: .whitespacesAndNewlines),
                          iso3 != "-99",
                          iso3.count == 3 {
                    // Fallback: convert ISO_A3 (e.g., FRA) to ISO2 (FR)
                    iso = String(iso3.prefix(2)).uppercased()
                } else if let countryName = name,
                          let derivedISO = isoFromCountryName(countryName) {

                    iso = derivedISO.uppercased()
                    print("🧠 Derived ISO from name:", countryName, "→", iso ?? "nil")

                } else {
                    iso = nil
                }

                if let countryName = name?.uppercased(), countryName.contains("FRANCE") {
                    print("🇫🇷 [GeoJSON] France feature detected name=\(countryName) iso=\(iso ?? "nil") rawISO_A2=\(isoA2 ?? "nil") rawISO_A3=\(isoA3 ?? "nil")")
                }

                // Explicit Taiwan fallback
                if let countryName = name?.lowercased(),
                   countryName.contains("taiwan") {
                    iso = "TW"
                    name = "Taiwan"
                }
            }

            guard let isoCode = iso else { continue }

            if countryNamesByISO[isoCode] == nil {
                countryNamesByISO[isoCode] = name
            }

            for geometry in feature.geometry {

                if let polygon = geometry as? MKPolygon {

                    if isoCode == "FR" {
                        splitFrancePolygon(
                            polygon,
                            countryPolygonsByISO: &countryPolygonsByISO,
                            countryNamesByISO: &countryNamesByISO
                        )
                    } else if isoCode == "NL" {
                        splitNetherlandsPolygon(
                            polygon,
                            countryPolygonsByISO: &countryPolygonsByISO,
                            countryNamesByISO: &countryNamesByISO
                        )
                    } else {
                        countryPolygonsByISO[isoCode, default: []].append(polygon)
                    }

                }
                else if let multiPolygon = geometry as? MKMultiPolygon {

                    for polygon in multiPolygon.polygons {

                        if isoCode == "FR" {
                            splitFrancePolygon(
                                polygon,
                                countryPolygonsByISO: &countryPolygonsByISO,
                                countryNamesByISO: &countryNamesByISO
                            )
                        } else if isoCode == "NL" {
                            splitNetherlandsPolygon(
                                polygon,
                                countryPolygonsByISO: &countryPolygonsByISO,
                                countryNamesByISO: &countryNamesByISO
                            )
                        } else {
                            countryPolygonsByISO[isoCode, default: []].append(polygon)
                        }

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

    private static func splitFrancePolygon(
        _ polygon: MKPolygon,
        countryPolygonsByISO: inout [String: [MKPolygon]],
        countryNamesByISO: inout [String: String]
    ) {

        let rect = polygon.boundingMapRect
        let center = MKMapPoint(x: rect.midX, y: rect.midY).coordinate

        let lat = center.latitude
        let lng = center.longitude

        // 🇪🇺 Mainland France
        if lat > 41 && lat < 52 && lng > -6 && lng < 10 {
            countryPolygonsByISO["FR", default: []].append(polygon)
            countryNamesByISO["FR"] = "France"
        }

        // 🇬🇫 French Guiana
        else if lat > 2 && lat < 7 && lng < -50 {
            countryPolygonsByISO["GF", default: []].append(polygon)
            countryNamesByISO["GF"] = "French Guiana"
        }

        // 🇬🇵 Guadeloupe
        else if lat > 15 && lat < 18 && lng < -60 {
            countryPolygonsByISO["GP", default: []].append(polygon)
            countryNamesByISO["GP"] = "Guadeloupe"
        }

        // 🇲🇶 Martinique
        else if lat > 14 && lat < 15.5 && lng < -60 {
            countryPolygonsByISO["MQ", default: []].append(polygon)
            countryNamesByISO["MQ"] = "Martinique"
        }

        // 🇷🇪 Réunion
        else if lat < -19 && lat > -23 && lng > 54 && lng < 56 {
            countryPolygonsByISO["RE", default: []].append(polygon)
            countryNamesByISO["RE"] = "Réunion"
        }

        // 🇾🇹 Mayotte
        else if lat < -11 && lat > -14 && lng > 44 && lng < 46 {
            countryPolygonsByISO["YT", default: []].append(polygon)
            countryNamesByISO["YT"] = "Mayotte"
        }

        // 🇵🇲 Saint Pierre & Miquelon
        else if lat > 45 && lng < -50 {
            countryPolygonsByISO["PM", default: []].append(polygon)
            countryNamesByISO["PM"] = "Saint Pierre and Miquelon"
        }

        // 🇳🇨 New Caledonia
        else if lat < -18 && lat > -25 && lng > 160 {
            countryPolygonsByISO["NC", default: []].append(polygon)
            countryNamesByISO["NC"] = "New Caledonia"
        }

        // 🇵🇫 French Polynesia
        else if lat < -5 && lat > -30 && lng < -120 {
            countryPolygonsByISO["PF", default: []].append(polygon)
            countryNamesByISO["PF"] = "French Polynesia"
        }

        // 🇼🇫 Wallis & Futuna
        else if lat < -10 && lng < -170 {
            countryPolygonsByISO["WF", default: []].append(polygon)
            countryNamesByISO["WF"] = "Wallis and Futuna"
        }

        else {
            print("⚠️ Unclassified France polygon lat:\(lat) lng:\(lng)")
        }
    }

    private static func splitNetherlandsPolygon(
        _ polygon: MKPolygon,
        countryPolygonsByISO: inout [String: [MKPolygon]],
        countryNamesByISO: inout [String: String]
    ) {

        let rect = polygon.boundingMapRect
        let center = MKMapPoint(x: rect.midX, y: rect.midY).coordinate

        let lat = center.latitude
        let lng = center.longitude

        // 🇳🇱 Mainland Netherlands (Europe)
        if lat > 50 && lat < 54 && lng > 3 && lng < 8 {
            countryPolygonsByISO["NL", default: []].append(polygon)
            countryNamesByISO["NL"] = "Netherlands"
        }

        // 🇦🇼 Aruba
        else if lat > 11 && lat < 13 && lng < -68 {
            countryPolygonsByISO["AW", default: []].append(polygon)
            countryNamesByISO["AW"] = "Aruba"
        }

        // 🇨🇼 Curaçao
        else if lat > 11 && lat < 13 && lng > -69 && lng < -67 {
            countryPolygonsByISO["CW", default: []].append(polygon)
            countryNamesByISO["CW"] = "Curaçao"
        }

        // 🇸🇽 Sint Maarten
        else if lat > 17 && lat < 19 && lng < -62 {
            countryPolygonsByISO["SX", default: []].append(polygon)
            countryNamesByISO["SX"] = "Sint Maarten"
        }

        // 🇧🇶 Caribbean Netherlands (Bonaire, Saba, Sint Eustatius)
        else if lat > 11 && lat < 18 && lng < -62 {
            countryPolygonsByISO["BQ", default: []].append(polygon)
            countryNamesByISO["BQ"] = "Caribbean Netherlands"
        }

        else {
            print("⚠️ Unclassified Netherlands polygon lat:\(lat) lng:\(lng)")
        }
    }
}
