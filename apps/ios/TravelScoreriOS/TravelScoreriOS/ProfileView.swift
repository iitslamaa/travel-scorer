//
//  ProfileView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/6/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var bucketList: BucketListStore
    @EnvironmentObject private var traveled: TraveledStore

    // Data placeholders (for now)
    private var username: String? = nil
    private var travelMode: String? = nil      // solo / group / solo+group
    private var travelStyle: String? = nil     // budget / comfortable / in-between / both
    private var homeCountryCodes: [String] = [] // ISO2 codes
    private var languages: [String] = []        // e.g. "English (native)", "Lebanese Arabic (learning)"
    private var nextDestinationCode: String? = nil // ISO2 code

    var body: some View {
        List {
            header

            Section {
                ReadOnlyRow(
                    title: "Username",
                    trailing: AnyView(
                        Text(username.map { "@\($0)" } ?? "Not set")
                            .foregroundColor(username == nil ? .secondary : .primary)
                    )
                )

                ReadOnlyRow(
                    title: "Home",
                    trailing: AnyView(FlagInline(flags: flags(for: Set(homeCountryCodes))))
                )

                ReadOnlyRow(
                    title: "Traveled",
                    trailing: AnyView(FlagInline(flags: flags(for: traveled.ids)))
                )

                ReadOnlyRow(
                    title: "Want to visit",
                    trailing: AnyView(FlagInline(flags: flags(for: bucketList.ids)))
                )

                ReadOnlyRow(
                    title: "I’m a",
                    trailing: AnyView(
                        Text(travelModeDisplay ?? "Not set")
                            .foregroundColor(travelMode == nil ? .secondary : .primary)
                    )
                )

                ReadOnlyRow(
                    title: "I prefer",
                    trailing: AnyView(
                        Text(travelStyleDisplay ?? "Not set")
                            .foregroundColor(travelStyle == nil ? .secondary : .primary)
                    )
                )

                HStack(alignment: .top, spacing: 10) {
                    Text("Languages:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 120, alignment: .leading)

                    Text(languagesDisplay ?? "Not set")
                        .font(.subheadline)
                        .foregroundColor(languages.isEmpty ? .secondary : .primary)
                        .lineLimit(nil)

                    Spacer(minLength: 8)
                }
                .padding(.vertical, 4)

                HStack(spacing: 10) {
                    Text("Next destination:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 120, alignment: .leading)

                    if let nextDestinationCode {
                        FlagInline(flags: flags(for: Set([nextDestinationCode])))
                    } else {
                        Text("—")
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 8)
                }
                .padding(.vertical, 4)
            }
            .listSectionSeparator(.hidden)

            Section {
                NavigationLink {
                    MyTravelsView()
                } label: {
                    Label("My Travels", systemImage: "backpack.fill")
                }

                NavigationLink {
                    BucketListView()
                } label: {
                    Label("Bucket List", systemImage: "bookmark.fill")
                }
            }
        }
        .navigationTitle("Profile")
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ProfileSettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }

    private var header: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your name")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(username.map { "@\($0)" } ?? "@not-set")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
        .listSectionSeparator(.hidden)
    }

    private var travelModeDisplay: String? {
        guard let travelMode else { return nil }
        switch travelMode.lowercased() {
        case "solo": return "Solo"
        case "group": return "Group"
        case "solo + group": return "Solo + Group"
        default: return travelMode
        }
    }

    private var travelStyleDisplay: String? {
        guard let travelStyle else { return nil }
        switch travelStyle.lowercased() {
        case "budget": return "BUDGET"
        case "comfortable": return "COMFORTABLE"
        case "in-between": return "IN-between"
        case "both": return "Both on occasion"
        default: return travelStyle
        }
    }

    private var languagesDisplay: String? {
        guard !languages.isEmpty else { return nil }
        return languages.joined(separator: " · ")
    }

    // MARK: - Helpers

    private func flags(for ids: Set<String>) -> [String] {
        ids
            .map { $0.uppercased() }
            .sorted()
            .map { countryCodeToFlag($0) }
    }

    private func countryCodeToFlag(_ code: String) -> String {
        guard code.count == 2 else { return code }
        let base: UInt32 = 127397
        return code.unicodeScalars
            .compactMap { UnicodeScalar(base + $0.value) }
            .map { String($0) }
            .joined()
    }
}

// MARK: - Compact rows

private struct ReadOnlyRow: View {
    let title: String
    let trailing: AnyView

    var body: some View {
        HStack(spacing: 10) {
            Text("\(title):")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            Spacer(minLength: 8)

            trailing
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Flags inline

private struct FlagInline: View {
    let flags: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(flags.prefix(10), id: \.self) { flag in
                Text(flag)
                    .font(.title3)
            }
            if flags.count > 10 {
                Text("+\(flags.count - 10)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .lineLimit(1)
    }
}
