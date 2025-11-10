import SwiftUI

struct CountriesView: View {
    @StateObject private var store = CountryStore()

    var body: some View {
        NavigationStack {
            List(store.filtered) { c in
                NavigationLink {
                    CountryDetailView(country: c, store: store)
                } label: {
                    CountryRow(country: c, isFavorite: store.isFavorite(c))
                }
            }
            .navigationTitle("Travelability")
            .searchable(text: $store.query, prompt: "Search countries")
        }
    }
}