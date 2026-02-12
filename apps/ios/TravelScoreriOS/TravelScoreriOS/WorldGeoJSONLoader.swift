//
//  WorldGeoJSONLoader.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/11/26.
//

import Foundation
import MapKit

class CountryPolygon: MKPolygon {
    var isoCode: String?
    var countryName: String?
}

struct WorldGeoJSONLoader {

    // 🔥 Cache polygons so we decode only once
    private static var cachedPolygons: [CountryPolygon]?

    static func loadPolygons() -> [CountryPolygon] {

        if let cached = cachedPolygons {
            return cached
        }

        guard let url = Bundle.main.url(forResource: "countries", withExtension: "geojson"),
              let data = try? Data(contentsOf: url) else {
            return []
        }

        let decoder = MKGeoJSONDecoder()
        var countryPolygons: [CountryPolygon] = []

        if let geoObjects = try? decoder.decode(data) {
            for object in geoObjects {
                if let feature = object as? MKGeoJSONFeature {

                    var iso: String?
                    var name: String?

                    if let propertiesData = feature.properties,
                       let jsonObject = try? JSONSerialization.jsonObject(with: propertiesData) as? [String: Any] {

                        name = jsonObject["name"] as? String

                        iso = (jsonObject["ISO3166-1-Alpha-2"] as? String)
                            ?? (jsonObject["ISO_A2"] as? String)
                    }

                    for geometry in feature.geometry {

                        if let polygon = geometry as? MKPolygon {
                            let countryPolygon = CountryPolygon(points: polygon.points(), count: polygon.pointCount)
                            countryPolygon.isoCode = iso
                            countryPolygon.countryName = name
                            countryPolygons.append(countryPolygon)
                        }

                        else if let multiPolygon = geometry as? MKMultiPolygon {
                            for polygon in multiPolygon.polygons {
                                let countryPolygon = CountryPolygon(points: polygon.points(), count: polygon.pointCount)
                                countryPolygon.isoCode = iso
                                countryPolygon.countryName = name
                                countryPolygons.append(countryPolygon)
                            }
                        }
                    }
                }
            }
        }

        cachedPolygons = countryPolygons
        return countryPolygons
    }
}
