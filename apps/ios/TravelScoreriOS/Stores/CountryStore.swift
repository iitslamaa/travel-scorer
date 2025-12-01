import Foundation
import Combine

final class CountryStore: ObservableObject {
    @Published private(set) var all: [Country] = []
    @Published var query: String = ""
    @Published var favorites: Set<String> = []   // iso2 set

    private let favsKey = "favorites.iso2.set"

    var filtered: [Country] {
        guard !query.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    init() {
        loadCountries()
        loadFavorites()
    }

    func toggleFavorite(_ country: Country) {
        if favorites.contains(country.iso2) { favorites.remove(country.iso2) }
        else { favorites.insert(country.iso2) }
        saveFavorites()
    }

    func isFavorite(_ country: Country) -> Bool { favorites.contains(country.iso2) }

    private func loadCountries() {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Country].self, from: data)
        else { return }
        self.all = decoded.sorted { $0.name < $1.name }
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favsKey),
              let set = try? JSONDecoder().decode(Set<String>.self, from: data) else { return }
        favorites = set
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: favsKey)
        }
    }
}