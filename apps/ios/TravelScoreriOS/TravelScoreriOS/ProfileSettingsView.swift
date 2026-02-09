import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Draft state (UI only)

    @State private var firstName: String = ""
    @State private var username: String = ""

    @State private var homeCountries: Set<String> = []
    @State private var nextDestination: String? = nil

    @State private var travelMode: TravelMode? = nil
    @State private var travelStyle: TravelStyle? = nil

    @State private var languages: [LanguageEntry] = []

    // Sheets / dialogs
    @State private var showTravelModeDialog = false
    @State private var showTravelStyleDialog = false
    @State private var showHomePicker = false
    @State private var showNextDestinationPicker = false
    @State private var showAddLanguage = false

    var body: some View {
        ZStack {
            Image("profile_settings_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text("Profile Settings")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 24)

                    Spacer()
                }
                .padding(.horizontal, 20)

                Spacer()
            }

            ScrollView {
                VStack(spacing: 20) {

                    SectionCard {
                        TextField(
                            "",
                            text: $firstName,
                            prompt: Text("First name")
                                .foregroundColor(.gray.opacity(0.7))
                        )
                        .padding(12)
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(10)
                        .foregroundColor(.black)
                        .tint(.gray)

                        HStack(spacing: 6) {
                            Text("@")
                                .font(.body)
                                .foregroundColor(.black)

                            TextField(
                                "",
                                text: $username,
                                prompt: Text("username")
                                    .foregroundColor(.gray.opacity(0.7))
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .foregroundColor(.black)
                            .tint(.gray)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.95))
                        .cornerRadius(10)
                    }

                    SectionCard(title: "Your background") {
                        Button {
                            showHomePicker = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Which countries do you consider home?")
                                    .foregroundColor(.blue)
                                if !homeCountries.isEmpty {
                                    HStack(spacing: 8) {
                                        ForEach(homeCountries.sorted(), id: \.self) { code in
                                            Text(countryCodeToFlag(code))
                                                .font(.largeTitle)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    SectionCard(title: "Travel preferences") {
                        Button {
                            showTravelModeDialog = true
                        } label: {
                            HStack {
                                Text("Travel mode")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text(travelMode?.label ?? "Not set")
                                    .foregroundColor(travelMode == nil ? .secondary : .primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            showTravelStyleDialog = true
                        } label: {
                            HStack {
                                Text("Travel style")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text(travelStyle?.label ?? "Not set")
                                    .foregroundColor(travelStyle == nil ? .secondary : .primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    SectionCard(title: "Languages spoken") {
                        if languages.isEmpty {
                            Text("Add languages you speak or are learning")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(languages) { entry in
                                Text(entry.display)
                            }
                        }

                        Button {
                            showAddLanguage = true
                        } label: {
                            Label("Add language", systemImage: "plus")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    SectionCard {
                        Button {
                            showNextDestinationPicker = true
                        } label: {
                            HStack {
                                Text("Next destination")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text(nextDestinationDisplay)
                                    .foregroundColor(nextDestination == nil ? .secondary : .primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 90)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    // Persistence will be added in PR #6D
                    dismiss()
                }
            }
        }

        // MARK: - Dialogs

        .confirmationDialog("Travel Mode", isPresented: $showTravelModeDialog) {
            ForEach(TravelMode.allCases) { mode in
                Button(mode.label) { travelMode = mode }
            }
            Button("Cancel", role: .cancel) {}
        }

        .confirmationDialog("Travel Style", isPresented: $showTravelStyleDialog) {
            ForEach(TravelStyle.allCases) { style in
                Button(style.label) { travelStyle = style }
            }
            Button("Cancel", role: .cancel) {}
        }

        // MARK: - Sheets (temporary pickers)

        .sheet(isPresented: $showHomePicker) {
            CountryMultiSelectView(
                title: "Select home countries",
                selection: $homeCountries
            )
        }

        .sheet(isPresented: $showNextDestinationPicker) {
            CountrySingleSelectView(
                title: "Select next destination",
                selection: $nextDestination
            )
        }

        .sheet(isPresented: $showAddLanguage) {
            AddLanguageView { entry in
                languages.append(entry)
            }
        }
    }

    // MARK: - Display helpers

    private var homeCountriesDisplay: String {
        guard !homeCountries.isEmpty else { return "Not set" }
        return homeCountries.sorted().map(countryCodeToFlag).joined(separator: " ")
    }

    private var nextDestinationDisplay: String {
        guard let nextDestination else { return "Not set" }
        return countryCodeToFlag(nextDestination)
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

private struct SectionCard<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color.white.opacity(0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

// MARK: - Models

private enum TravelMode: String, CaseIterable, Identifiable {
    case solo, group, both
    var id: String { rawValue }
    var label: String {
        switch self {
        case .solo: return "Solo"
        case .group: return "Group"
        case .both: return "Solo + Group"
        }
    }
}

private enum TravelStyle: String, CaseIterable, Identifiable {
    case budget, comfortable, inBetween, both
    var id: String { rawValue }
    var label: String {
        switch self {
        case .budget: return "BUDGET"
        case .comfortable: return "COMFORTABLE"
        case .inBetween: return "IN‑between"
        case .both: return "Both on occasion"
        }
    }
}

private struct LanguageEntry: Identifiable {
    let id = UUID()
    let name: String
    let proficiency: String   // native / fluent / learning

    var display: String {
        "\(name) (\(proficiency))"
    }
}

// MARK: - Temporary picker views (UI only)

private struct CountryMultiSelectView: View {
    let title: String
    @Binding var selection: Set<String>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var hasChanges = false

    let initialSelection: Set<String>

    init(title: String, selection: Binding<Set<String>>) {
        self.title = title
        self._selection = selection
        self.initialSelection = selection.wrappedValue
    }

    let countries = Locale.isoRegionCodes
        .compactMap { code -> (String, String)? in
            let name = Locale.current.localizedString(forRegionCode: code)
            return name.map { (code, $0) }
        }
        .sorted { $0.1 < $1.1 }

    var body: some View {
        NavigationStack {
            let filtered = searchText.isEmpty
                ? countries
                : countries.filter { $0.1.localizedCaseInsensitiveContains(searchText) }

            List(filtered, id: \.0) { (code, name) in
                Button {
                    if selection.contains(code) {
                        selection.remove(code)
                    } else {
                        selection.insert(code)
                    }
                    hasChanges = selection != initialSelection
                } label: {
                    HStack {
                        Text(countryCodeToFlag(code))
                        Text(name)
                        Spacer()
                        if selection.contains(code) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(hasChanges ? .blue : .gray)
                    }
                    .disabled(!hasChanges)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
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

private struct CountrySingleSelectView: View {
    let title: String
    @Binding var selection: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    let countries = Locale.isoRegionCodes
        .compactMap { code -> (String, String)? in
            let name = Locale.current.localizedString(forRegionCode: code)
            return name.map { (code, $0) }
        }
        .sorted { $0.1 < $1.1 }

    var body: some View {
        NavigationStack {
            let filtered = searchText.isEmpty
                ? countries
                : countries.filter { $0.1.localizedCaseInsensitiveContains(searchText) }

            List(filtered, id: \.0) { (code, name) in
                Button {
                    selection = code
                    dismiss()
                } label: {
                    HStack {
                        Text(countryCodeToFlag(code))
                        Text(name)
                        Spacer()
                        if selection == code {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle(title)
        }
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

private struct AddLanguageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var language = ""
    @State private var proficiency = "native"

    let onAdd: (LanguageEntry) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Language", text: $language)

                Picker("Proficiency", selection: $proficiency) {
                    Text("Native").tag("native")
                    Text("Fluent").tag("fluent")
                    Text("Learning").tag("learning")
                }
            }
            .navigationTitle("Add language")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(LanguageEntry(name: language, proficiency: proficiency))
                        dismiss()
                    }
                    .disabled(language.isEmpty)
                }
            }
        }
    }
}
