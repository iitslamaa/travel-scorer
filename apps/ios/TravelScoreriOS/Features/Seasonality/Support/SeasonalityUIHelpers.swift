//
//  SeasonalityUIHelpers.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 12/2/25.
//

import Foundation
import SwiftUI

struct MonthMeta: Identifiable {
    let id: Int        // 1...12
    let label: String  // "January"
    let short: String  // "Jan"
}

let allMonthsMeta: [MonthMeta] = [
    .init(id: 1,  label: "January",   short: "Jan"),
    .init(id: 2,  label: "February",  short: "Feb"),
    .init(id: 3,  label: "March",     short: "Mar"),
    .init(id: 4,  label: "April",     short: "Apr"),
    .init(id: 5,  label: "May",       short: "May"),
    .init(id: 6,  label: "June",      short: "Jun"),
    .init(id: 7,  label: "July",      short: "Jul"),
    .init(id: 8,  label: "August",    short: "Aug"),
    .init(id: 9,  label: "September", short: "Sep"),
    .init(id: 10, label: "October",   short: "Oct"),
    .init(id: 11, label: "November",  short: "Nov"),
    .init(id: 12, label: "December",  short: "Dec")
]

func scoreTone(_ value: Double?) -> Color {
    guard let value else { return Color(.systemGray5) }
    switch value {
    case 80...:
        return Color(.systemGreen)
    case 60...:
        return Color(.systemYellow)
    case 0...:
        return Color(.systemRed)
    default:
        return Color(.black)
    }
}

func scoreBackground(_ value: Double?) -> Color {
    guard let value else { return Color(.systemGray6) }
    switch value {
    case 80...:
        return Color(.systemGreen).opacity(0.15)
    case 60...:
        return Color(.systemYellow).opacity(0.15)
    case 0...:
        return Color(.systemRed).opacity(0.15)
    default:
        return Color.black
    }
}
