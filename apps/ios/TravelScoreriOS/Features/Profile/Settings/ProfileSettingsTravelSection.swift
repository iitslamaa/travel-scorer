//
//  ProfileSettingsTravelSection.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/14/26.
//

import Foundation
import SwiftUI

struct ProfileSettingsTravelSection: View {

    @Binding var travelMode: TravelMode?
    @Binding var travelStyle: TravelStyle?

    @Binding var showTravelModeDialog: Bool
    @Binding var showTravelStyleDialog: Bool

    var body: some View {
        SectionCard(title: "Travel preferences") {

            Button {
                showTravelModeDialog = true
            } label: {
                HStack {
                    Text("Travel mode")
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(travelMode?.label ?? "Not set")
                        .foregroundStyle(travelMode == nil ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                showTravelStyleDialog = true
            } label: {
                HStack {
                    Text("Travel style")
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(travelStyle?.label ?? "Not set")
                        .foregroundStyle(travelStyle == nil ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
