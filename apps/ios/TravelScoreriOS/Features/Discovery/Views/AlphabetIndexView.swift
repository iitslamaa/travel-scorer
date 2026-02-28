//
//  AlphabetIndexView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/28/26.
//

import SwiftUI

struct AlphabetIndexView: View {
    let letters: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(letter)
                    }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview {
    AlphabetIndexView(
        letters: ["A","B","C","D","E","F","G"],
        onSelect: { _ in }
    )
}
