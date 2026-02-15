//
//  CountryTravelSafeHelpers.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/15/26.
//

import Foundation

enum CountryTravelSafeHelpers {

    static func headline(for country: Country) -> String {
        guard let score = country.travelSafeScore else {
            return "Safety information is limited"
        }

        switch score {
        case 80...100:
            return "Generally very safe ✅"
        case 60..<80:
            return "Mostly safe with normal caution"
        case 40..<60:
            return "Mixed safety; stay aware"
        default:
            return "Higher risk; plan carefully"
        }
    }

    static func body(for country: Country) -> String {
        guard let score = country.travelSafeScore else {
            return "Based on TravelSafe global crime and safety data. Check local guidance and recent news for context."
        }

        switch score {
        case 80...100:
            return "TravelSafe suggests relatively low crime and good safety conditions, though normal precautions still apply."
        case 60..<80:
            return "Conditions are generally safe, but you should stay alert to petty crime and follow common-sense precautions."
        case 40..<60:
            return "Safety conditions vary a lot by neighborhood; research your areas and follow local advice."
        default:
            return "TravelSafe reports elevated risk. If you go, plan carefully, avoid high-risk areas, and follow official guidance."
        }
    }
}
