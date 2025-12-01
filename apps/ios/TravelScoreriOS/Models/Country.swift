import Foundation

struct Categories: Codable {
    let safety: Int
    let affordability: Int
    let seasonality: Int
}

struct Country: Codable, Identifiable, Hashable {
    var id: String { iso2 }           // Use 2-letter code as stable id
    let name: String
    let iso2: String
    let score: Int
    let categories: Categories
    let lastUpdated: String
}