//
//  ProfileSettingsBackgroundSection.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/14/26.
//

import Foundation
import SwiftUI

struct ProfileSettingsBackgroundSection: View {

    let homeCountries: Set<String>
    let currentCountry: String?
    let nextDestination: String?
    let favoriteCountries: [String]

    @Binding var showHomePicker: Bool
    @Binding var showNextDestinationPicker: Bool
    @Binding var showCurrentCountryPicker: Bool
    @Binding var showFavoriteCountriesPicker: Bool

    var body: some View {
        SectionCard(title: "Your background") {

            // My Flags
            Button {
                showHomePicker = true
            } label: {
                HStack(spacing: 8) {

                    Text("My flags:")
                        .font(.subheadline)
                        .fontWeight(.regular)

                    if !homeCountries.isEmpty {
                        ForEach(homeCountries.sorted(), id: \.self) { code in
                            Text(flag(for: code))
                        }
                    } else {
                        Text("None")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }

            Divider()

            // Current Country
            Button {
                showCurrentCountryPicker = true
            } label: {
                HStack(spacing: 8) {

                    Text("Current country:")
                        .font(.subheadline)
                        .fontWeight(.regular)

                    if let currentCountry, !currentCountry.isEmpty {
                        let upper = currentCountry.uppercased()
                        let name = countryName(for: upper)
                        let emoji = flag(for: upper)

                        HStack(spacing: 4) {
                            Text(emoji)
                            Text(name)
                        }
                    } else {
                        Text("None")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }

            // Next Destination
            Button {
                showNextDestinationPicker = true
            } label: {
                HStack(spacing: 8) {

                    Text("Next destination:")
                        .font(.subheadline)
                        .fontWeight(.regular)

                    if let nextDestination, !nextDestination.isEmpty {
                        let upper = nextDestination.uppercased()
                        let name = countryName(for: upper)
                        let emoji = flag(for: upper)

                        HStack(spacing: 4) {
                            Text(emoji)
                            Text(name)
                        }
                    } else {
                        Text("None")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }

            Divider()

            // Favorite Countries
            Button {
                showFavoriteCountriesPicker = true
            } label: {
                HStack(spacing: 8) {

                    Text("Favorite countries:")
                        .font(.subheadline)
                        .fontWeight(.regular)

                    if favoriteCountries.isEmpty {
                        Text("None")
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 6) {
                            ForEach(favoriteCountries, id: \.self) { code in
                                Text(flag(for: code))
                            }
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    private func flag(for code: String) -> String {
        guard code.count == 2 else { return code }
        let base: UInt32 = 127397
        return code.unicodeScalars
            .compactMap { UnicodeScalar(base + $0.value) }
            .map { String($0) }
            .joined()
    }

    private func countryName(for countryCode: String) -> String {
        let upper = countryCode.uppercased()
        let locale = Locale(identifier: "en_US")
        return locale.localizedString(forRegionCode: upper) ?? upper
    }
}
