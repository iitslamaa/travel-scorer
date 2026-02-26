//
//  AddLanguageView.swift
//  TravelScoreriOS
//

import SwiftUI

struct AddLanguageView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var language = ""
    @State private var proficiency = "native"

    let onAdd: (LanguageEntry) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Language", text: $language)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    Picker("Proficiency", selection: $proficiency) {
                        Text("Native").tag("native")
                        Text("Fluent").tag("fluent")
                        Text("Learning").tag("learning")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }

                        onAdd(
                            LanguageEntry(
                                name: trimmed,
                                proficiency: proficiency
                            )
                        )
                        dismiss()
                    }
                    .disabled(language.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
