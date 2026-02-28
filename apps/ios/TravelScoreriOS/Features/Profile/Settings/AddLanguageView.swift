//
//  AddLanguageView.swift
//  TravelScoreriOS
//

import SwiftUI

struct AddLanguageView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    let onSelect: (LanguageEntry) -> Void

    private var languages: [AppLanguage] {
        let all = LanguageRepository.shared.allLanguages

        guard !searchText.isEmpty else { return all }

        return all.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(languages) { language in
                NavigationLink {
                    List {
                        ForEach(LanguageProficiency.allCases, id: \.self) { level in
                            Button {
                                onSelect(
                                    LanguageEntry(
                                        name: language.code,
                                        proficiency: level
                                    )
                                )
                                dismiss()
                            } label: {
                                HStack {
                                    Text(level.rawValue)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .navigationTitle(language.displayName)
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Text(language.displayName)
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Language")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
