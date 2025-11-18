import SwiftUI

struct CountryDetailView: View {
    let country: Country
    @ObservedObject var store: CountryStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(country.name).font(.largeTitle).bold()

                GaugeView(progress: Double(country.score) / 100.0)
                    .frame(width: 160, height: 160)

                VStack(spacing: 10) {
                    CategoryBar(title: "Safety", value: country.categories.safety)
                    CategoryBar(title: "Affordability", value: country.categories.affordability)
                    CategoryBar(title: "Seasonality", value: country.categories.seasonality)
                }

                Text("Last updated: \(country.lastUpdated)")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
        }
        .toolbar {
            Button {
                store.toggleFavorite(country)
            } label: {
                Image(systemName: store.isFavorite(country) ? "heart.fill" : "heart")
            }
        }
    }
}

struct GaugeView: View {
    var progress: Double // 0...1
    var body: some View {
        ZStack {
            Circle().stroke(lineWidth: 14).opacity(0.15)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            Text("\(Int(progress * 100))")
                .font(.title).bold()
        }
    }
}

struct CategoryBar: View {
    let title: String
    let value: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(title); Spacer(); Text("\(value)") }
            GeometryReader { geo in
                let w = geo.size.width
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(width: max(4, (CGFloat(value)/100.0) * w))
                        , alignment: .leading
                    )
            }.frame(height: 12)
        }
    }
}