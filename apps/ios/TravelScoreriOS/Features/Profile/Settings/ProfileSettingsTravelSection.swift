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

    var body: some View {
        SectionCard(title: "Travel preferences") {

            NavigationLink {
                List {
                    ForEach(TravelMode.allCases) { mode in
                        Button {
                            travelMode = mode
                        } label: {
                            HStack {
                                Text(mode.label)
                                Spacer()
                                if travelMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Travel Mode")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Text("Travel mode")
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(travelMode?.label ?? "Not set")
                        .foregroundStyle(travelMode == nil ? .secondary : .primary)
                }
            }

            NavigationLink {
                List {
                    ForEach(TravelStyle.allCases) { style in
                        Button {
                            travelStyle = style
                        } label: {
                            HStack {
                                Text(style.label)
                                Spacer()
                                if travelStyle == style {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Travel Style")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Text("Travel style")
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(travelStyle?.label ?? "Not set")
                        .foregroundStyle(travelStyle == nil ? .secondary : .primary)
                }
            }
        }
    }
}
