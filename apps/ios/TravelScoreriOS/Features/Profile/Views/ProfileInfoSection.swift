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
    let languages: [String]
    let travelMode: String?
    let travelStyle: String?
    let nextDestination: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let _ = print("🧩 ProfileInfoSection BODY")
        let _ = print("   relationshipState:", relationshipState)
        let _ = print("   orderedTraveledCountries count:", orderedTraveledCountries.count)
        let _ = print("   orderedTraveledCountries:", orderedTraveledCountries)
        let _ = print("   orderedBucketListCountries count:", orderedBucketListCountries.count)
        let _ = print("   orderedBucketListCountries:", orderedBucketListCountries)
        let _ = print("   viewedTraveledCountries count:", viewedTraveledCountries.count)
        let _ = print("   viewedBucketListCountries count:", viewedBucketListCountries.count)
        let _ = print("   mutualTraveledCountries:", mutualTraveledCountries)
        let _ = print("   mutualBucketCountries:", mutualBucketCountries)
        let _ = print("   languages:", languages)
        let _ = print("   travelMode:", travelMode as Any)
        let _ = print("   travelStyle:", travelStyle as Any)
        let _ = print("   nextDestination:", nextDestination as Any)
        LazyVStack(spacing: 28) {
            languagesCard
            travelModeCard
            travelStyleCard
            nextDestinationCard
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
                .id("traveled-\(orderedTraveledCountries.joined(separator: ","))")

                CollapsibleCountrySection(
                    title: "Bucket List",
                    countryCodes: orderedBucketListCountries,
                    highlightColor: .blue
                )
                .id("bucket-\(orderedBucketListCountries.joined(separator: ","))")

            } else if relationshipState == .friends {

                CollapsibleCountrySection(
                    title: "Countries Traveled",
                    countryCodes: orderedTraveledCountries,
                    highlightColor: .gold,
                    mutualCountries: Set(mutualTraveledCountries)
                )
                .id("traveled-\(orderedTraveledCountries.joined(separator: ","))")

                CollapsibleCountrySection(
                    title: "Bucket List",
                    countryCodes: orderedBucketListCountries,
                    highlightColor: .blue,
                    mutualCountries: Set(mutualBucketCountries)
                )
                .id("bucket-\(orderedBucketListCountries.joined(separator: ","))")

            } else {
                lockedProfileMessage
            }
        }
    }

    private func displayName(for code: String) -> String {
        LanguageRepository.shared.allLanguages
            .first(where: { $0.code == code })?
            .displayName
            ?? code
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
                let displayLanguages = languages.map { displayName(for: $0) }
                Text(displayLanguages.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.primary)
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

    private var nextDestinationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let code = nextDestination, !code.isEmpty {
                let upper = code.uppercased()
                let flag = flagEmoji(for: upper)
                let name = countryName(for: upper)

                Text("Next Destination: \(name) \(flag)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text("Next Destination: Not set")
                    .font(.subheadline)
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
