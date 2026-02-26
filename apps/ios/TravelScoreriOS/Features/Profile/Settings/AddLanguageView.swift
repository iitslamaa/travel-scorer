//
//  AddLanguageView.swift
//  TravelScoreriOS
//

import SwiftUI

struct AddLanguageView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedLanguage: AppLanguage? = nil
    @State private var selectedComfort: LanguageComfort = .nativeLevel
    @State private var isLearning: Bool = false
    @State private var isPreferred: Bool = false

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
            if let selectedLanguage {
                languageDetailView(selectedLanguage)
            } else {
                languageListView
            }
        }
    }

    // MARK: - Language List

    private var languageListView: some View {
        List(languages) { language in
            Button {
                selectedLanguage = language
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

    // MARK: - Language Detail

    private func languageDetailView(_ language: AppLanguage) -> some View {
        Form {
            Section(header: Text(language.displayName)) {
                Picker("Comfort Level", selection: $selectedComfort) {
                    ForEach(LanguageComfort.allCases) { level in
                        Text(level.label).tag(level)
                    }
                }
                .pickerStyle(.inline)

                Toggle("Actively practicing", isOn: $isLearning)

                Toggle("Set as preferred language", isOn: $isPreferred)
            }

            Section {
                Button {
                    let entry = LanguageEntry(
                        code: language.code,
                        comfort: selectedComfort,
                        isLearning: isLearning,
                        isPreferred: isPreferred
                    )
                    onSelect(entry)
                    dismiss()
                } label: {
                    Text("Add Language")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Language Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    selectedLanguage = nil
                }
            }
        }
    }
}
