//
//  FlagWithTooltip.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/11/26.
//

import Foundation
import SwiftUI

struct FlagWithTooltip: View {
    let countryCode: String
    let countryName: String

    @State private var showTooltip = false

    var body: some View {
        VStack(spacing: 4) {
            Text(flagEmoji(from: countryCode))
                .font(.largeTitle)
                .onTapGesture {
                    showTemporarily()
                }

            if showTooltip {
                Text(countryName)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.85))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showTooltip)
    }

    private func showTemporarily() {
        showTooltip = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showTooltip = false
            }
        }
    }

    private func flagEmoji(from countryCode: String) -> String {
        countryCode
            .uppercased()
            .unicodeScalars
            .map { 127397 + $0.value }
            .compactMap(UnicodeScalar.init)
            .map(String.init)
            .joined()
    }
}
