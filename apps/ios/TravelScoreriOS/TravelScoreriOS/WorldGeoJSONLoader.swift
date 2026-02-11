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
}

struct WorldGeoJSONLoader {

    static func loadPolygons() -> [CountryPolygon] {

        guard let url = Bundle.main.url(forResource: "countries", withExtension: "geojson") else {
            return []
        }

        guard let data = try? Data(contentsOf: url) else {
            return []
        }

        let decoder = MKGeoJSONDecoder()
        var countryPolygons: [CountryPolygon] = []

        if let geoObjects = try? decoder.decode(data) {
            for object in geoObjects {
                if let feature = object as? MKGeoJSONFeature {

                    var iso: String? = nil

                    if let propertiesData = feature.properties,
                       let jsonObject = try? JSONSerialization.jsonObject(with: propertiesData) as? [String: Any] {

                        // Try Alpha-2 first
                        if let alpha2 = jsonObject["ISO3166-1-Alpha-2"] as? String {
                            iso = alpha2
                        }
                        // Fallback to ISO_A2 (for other datasets)
                        else if let isoA2 = jsonObject["ISO_A2"] as? String {
                            iso = isoA2
                        }
                    }

                    for geometry in feature.geometry {

                        if let polygon = geometry as? MKPolygon {
                            let countryPolygon = CountryPolygon(points: polygon.points(), count: polygon.pointCount)
                            countryPolygon.isoCode = iso
                            countryPolygons.append(countryPolygon)
                        }

                        else if let multiPolygon = geometry as? MKMultiPolygon {
                            for polygon in multiPolygon.polygons {
                                let countryPolygon = CountryPolygon(points: polygon.points(), count: polygon.pointCount)
                                countryPolygon.isoCode = iso
                                countryPolygons.append(countryPolygon)
                            }
                        }
                    }
                }
            }
        }

        return countryPolygons
    }
}
