//
//  ProfileSettingsView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/9/26.
//

import Foundation
//
//  ProfileSettingsView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/9/26.
//

import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text("Profile settings coming next ✅")
                    .font(.headline)
                Text("This screen will let you edit your name, username, home countries, languages, travel style, and next destination.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Profile Settings")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
