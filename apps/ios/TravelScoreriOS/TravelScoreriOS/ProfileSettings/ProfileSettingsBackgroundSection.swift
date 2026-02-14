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
                VStack(alignment: .leading, spacing: 4) {

                    Text("Which countries do you consider home?")
                        .foregroundStyle(.primary)

                    if !homeCountries.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(homeCountries.sorted(), id: \.self) { code in
                                Text(flag(for: code))
                                    .font(.largeTitle)
                            }
                        }
                    }
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
