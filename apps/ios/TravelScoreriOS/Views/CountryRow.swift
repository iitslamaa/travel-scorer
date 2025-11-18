import SwiftUI

struct CountryRow: View {
    let country: Country
    let isFavorite: Bool

    var flagURL: URL? {
        // FlagCDN 48px PNG; iso2 lowercase
        URL(string: "https://flagcdn.com/w40/\(country.iso2.lowercased()).png")
    }

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: flagURL) { img in
                img.resizable().scaledToFit()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 40, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 3))

            VStack(alignment: .leading, spacing: 2) {
                Text(country.name).font(.headline)
                Text("Score \(country.score)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if isFavorite {
                Image(systemName: "heart.fill").foregroundStyle(.pink)
            }
        }
        .padding(.vertical, 4)
    }
}