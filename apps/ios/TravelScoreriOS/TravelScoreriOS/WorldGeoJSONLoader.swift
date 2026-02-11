//
//  WorldGeoJSONLoader.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/11/26.
//

import Foundation
import MapKit

struct WorldGeoJSONLoader {

    static func loadPolygons() -> [MKPolygon] {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "geojson"),
              let data = try? Data(contentsOf: url) else {
            return []
        }

        var polygons: [MKPolygon] = []

        let decoder = MKGeoJSONDecoder()

        if let geoObjects = try? decoder.decode(data) {
            for object in geoObjects {
                if let feature = object as? MKGeoJSONFeature {
                    for geometry in feature.geometry {
                        if let polygon = geometry as? MKPolygon {
                            polygons.append(polygon)
                        }
                    }
                }
            }
        }

        return polygons
    }
}
