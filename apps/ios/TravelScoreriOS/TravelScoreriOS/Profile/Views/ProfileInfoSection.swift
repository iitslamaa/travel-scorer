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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 28) {
            languagesCard
            infoCards
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 32)
    }

    private var infoCards: some View {
        VStack(spacing: 12) {

            if relationshipState == .selfProfile {

                CollapsibleCountrySection(
                    title: "Countries Traveled",
                    countryCodes: orderedTraveledCountries,
                    highlightColor: .gold
                )

                CollapsibleCountrySection(
                    title: "Want to Visit",
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
                    title: "Want to Visit",
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
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var lockedProfileMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundColor(.secondary)

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
