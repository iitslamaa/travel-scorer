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
    @State private var editingLanguage: LanguageEntry? = nil

    private func displayName(for entry: LanguageEntry) -> String {
        LanguageRepository.shared.allLanguages
            .first(where: { $0.code == entry.name })?
            .displayName
            ?? entry.name
    }

    var body: some View {
        SectionCard(title: "Languages spoken") {

            if languages.isEmpty {
                Text("Add languages you speak or are learning")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 14) {
                    ForEach(languages.indices, id: \.self) { index in
                        HStack(alignment: .center) {

                            Button {
                                editingLanguage = languages[index]
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(displayName(for: languages[index]))
                                        .font(.body)
                                        .foregroundStyle(.primary)

                                    Text(languages[index].proficiency.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

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
            }

            Divider()

            Button {
                showAddLanguage = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Add language")
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
        .sheet(item: $editingLanguage) { entry in
            NavigationStack {
                List {
                    ForEach(LanguageProficiency.allCases, id: \.self) { level in
                        Button {
                            if let index = languages.firstIndex(where: { $0.id == entry.id }) {
                                languages[index] = LanguageEntry(
                                    id: entry.id,
                                    name: entry.name,
                                    proficiency: level
                                )
                            }
                            editingLanguage = nil
                        } label: {
                            HStack {
                                Text(level.rawValue)
                                Spacer()
                                if entry.proficiency == level {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Proficiency")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            editingLanguage = nil
                        }
                    }
                }
            }
        }
    }
}
