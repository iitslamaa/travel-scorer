//
//  ProfileSettingsLanguagesSection.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/14/26.
//

import Foundation
import SwiftUI

struct ProfileSettingsLanguagesSection: View {

    @Binding var languages: [LanguageEntry]
    @Binding var showAddLanguage: Bool

    private func displayName(for entry: LanguageEntry) -> String {
        LanguageRepository.shared.allLanguages
            .first(where: { $0.code == entry.code })?
            .displayName
            ?? entry.code
    }

    var body: some View {
        SectionCard(title: "Languages spoken") {

            if languages.isEmpty {
                Text("Add languages you speak or are learning")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(languages.indices, id: \.self) { index in
                    let entry = languages[index]

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName(for: entry))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            HStack(spacing: 6) {
                                Text(entry.comfort.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if entry.isLearning {
                                    Text("• Learning")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }

                                if entry.isPreferred {
                                    Text("• Preferred")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }

                        Spacer()

                        Button {
                            languages.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                showAddLanguage = true
            } label: {
                Label("Add language", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
