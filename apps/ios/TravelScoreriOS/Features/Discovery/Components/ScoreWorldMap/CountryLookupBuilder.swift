
//
//  CountryLookupBuilder.swift
//  TravelScoreriOS
//

import Foundation

enum CountryLookupBuilder {
    
    static func build(from countries: [Country]) -> [String: Country] {
        
        var lookup: [String: Country] = [:]
        
        for country in countries {
            lookup[country.iso2.uppercased()] = country
            lookup[country.name] = country
        }
        
        normalizeTerritories(into: &lookup)
        
        return lookup
    }
    
    // MARK: - Territory Normalization
    
    private static func normalizeTerritories(into lookup: inout [String: Country]) {
        
        let franceTerritories = ["GF","GP","MQ","RE","YT","PM","NC","PF","WF"]
        let netherlandsTerritories = ["AW","CW","SX","BQ"]
        
        if let france = lookup["FR"] {
            for iso in franceTerritories {
                lookup[iso] = france
            }
        }
        
        if let netherlands = lookup["NL"] {
            for iso in netherlandsTerritories {
                lookup[iso] = netherlands
            }
        }
    }
}
