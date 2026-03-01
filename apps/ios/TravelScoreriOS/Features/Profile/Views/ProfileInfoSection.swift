//
//  ProfileInfoSection.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/13/26.
//

import Foundation
import SwiftUI

struct ProfileInfoSection: View {

    let relationshipState: RelationshipState
    let viewedTraveledCountries: Set<String>
    let viewedBucketListCountries: Set<String>
    let orderedTraveledCountries: [String]
    let orderedBucketListCountries: [String]
    let mutualTraveledCountries: [String]
    let mutualBucketCountries: [String]
    let mutualLanguages: [String]
    let languages: [String]
    let travelMode: String?
    let travelStyle: String?
    let nextDestination: String?

    let currentCountry: String?
    let favoriteCountries: [String]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LazyVStack(spacing: 28) {
            languagesCard
            locationCard

            if relationshipState == .friends && !mutualLanguages.isEmpty {
                sharedLanguagesCard
            }

            travelModeCard
            travelStyleCard
            infoCards
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 32)
    }

    private var infoCards: some View {
        LazyVStack(spacing: 12) {

            if relationshipState == .selfProfile {

                CollapsibleCountrySection(
                    title: "Countries Traveled",
                    countryCodes: orderedTraveledCountries,
                    highlightColor: .gold
                )

                CollapsibleCountrySection(
                    title: "Bucket List",
                    countryCodes: orderedBucketListCountries,
                    highlightColor: .blue
                )

            } else if relationshipState == .friends {

                CollapsibleCountrySection(
                    title: "Countries Traveled",
                    countryCodes: orderedTraveledCountries,
                    highlightColor: .gold,
                    mutualCountries: Set(mutualTraveledCountries)
                )

                CollapsibleCountrySection(
                    title: "Bucket List",
                    countryCodes: orderedBucketListCountries,
                    highlightColor: .blue,
                    mutualCountries: Set(mutualBucketCountries)
                )

            } else {
                lockedProfileMessage
            }
        }
    }

    private var languagesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Languages")
                .font(.subheadline)
                .fontWeight(.semibold)

            if languages.isEmpty {
                Text("Not set")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(languages.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var sharedLanguagesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shared Languages")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(mutualLanguages.joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            if let currentCountry, !currentCountry.isEmpty {
                let upper = currentCountry.uppercased()
                let flag = flagEmoji(for: upper)
                let name = countryName(for: upper)

                HStack(alignment: .firstTextBaseline) {
                    Text("Current Country")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer(minLength: 12)

                    Text("\(name) \(flag)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }

            if currentCountry != nil && nextDestination != nil {
                Divider()
                    .opacity(0.12)
            }

            if let code = nextDestination, !code.isEmpty {
                let upper = code.uppercased()
                let flag = flagEmoji(for: upper)
                let name = countryName(for: upper)

                HStack(alignment: .firstTextBaseline) {
                    Text("Next Destination")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer(minLength: 12)

                    Text("\(name) \(flag)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }

            if nextDestination != nil && !favoriteCountries.isEmpty {
                Divider()
                    .opacity(0.12)
            }

            if !favoriteCountries.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Favorite Countries")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer(minLength: 12)

                    HStack(spacing: 6) {
                        ForEach(favoriteCountries.sorted(), id: \.self) { code in
                            Text(flagEmoji(for: code.uppercased()))
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var travelModeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Travel Mode: Solo or Group?")
                .font(.subheadline)
                .fontWeight(.semibold)

            if let travelMode, !travelMode.isEmpty {
                Text(travelMode)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            } else {
                Text("Not set")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var travelStyleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Travel Style: Budget, Comfortable, or In Between?")
                .font(.subheadline)
                .fontWeight(.semibold)

            if let travelStyle, !travelStyle.isEmpty {
                Text(travelStyle)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            } else {
                Text("Not set")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func flagEmoji(for countryCode: String) -> String {
        countryCode
            .uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    private func countryName(for countryCode: String) -> String {
        let upper = countryCode.uppercased()
        let locale = Locale(identifier: "en_US")
        return locale.localizedString(forRegionCode: upper) ?? upper
    }

    private var lockedProfileMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Learn more about this user by adding them as a friend!")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
