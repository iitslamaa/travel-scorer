//
//  ProfileSettingsLanguagesSection.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/14/26.
//

import Foundation
import SwiftUI

struct ProfileSettingsLanguagesSection: View {

    let languages: [LanguageEntry]
    @Binding var showAddLanguage: Bool

    var body: some View {
        SectionCard(title: "Languages spoken") {

            if languages.isEmpty {
                Text("Add languages you speak or are learning")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(languages) { entry in
                    Text(entry.display)
                        .foregroundStyle(.primary)
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
