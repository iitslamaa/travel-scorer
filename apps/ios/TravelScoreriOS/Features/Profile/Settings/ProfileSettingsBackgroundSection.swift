//
//  ProfileSettingsBackgroundSection.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/14/26.
//

import Foundation
import SwiftUI

struct ProfileSettingsBackgroundSection: View {

    let homeCountries: Set<String>
    @Binding var showHomePicker: Bool

    var body: some View {
        SectionCard(title: "Your background") {

            Button {
                showHomePicker = true
            } label: {
                HStack(spacing: 8) {

                    Text("My flags:")
                        .fontWeight(.bold)

                    if !homeCountries.isEmpty {
                        ForEach(homeCountries.sorted(), id: \.self) { code in
                            Text(flag(for: code))
                        }
                    } else {
                        Text("None")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func flag(for code: String) -> String {
        guard code.count == 2 else { return code }
        let base: UInt32 = 127397
        return code.unicodeScalars
            .compactMap { UnicodeScalar(base + $0.value) }
            .map { String($0) }
            .joined()
    }
}
