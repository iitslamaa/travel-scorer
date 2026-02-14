import SwiftUI
import PhotosUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    private let viewedUserId: UUID

    init(profileVM: ProfileViewModel, viewedUserId: UUID) {
        self.profileVM = profileVM
        self.viewedUserId = viewedUserId
    }

    // MARK: - Draft state (UI only)

    @State private var firstName: String = ""
    @State private var username: String = ""

    @State private var homeCountries: Set<String> = []
    @State private var nextDestination: String? = nil

    @State private var travelMode: TravelMode? = nil
    @State private var travelStyle: TravelStyle? = nil

    @State private var languages: [LanguageEntry] = []

    @State private var hasLoadedProfile = false

    // Avatar picker state
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var isUploadingAvatar = false

    // Sheets / dialogs
    @State private var showTravelModeDialog = false
    @State private var showTravelStyleDialog = false
    @State private var showHomePicker = false
    @State private var showNextDestinationPicker = false
    @State private var showAddLanguage = false

    var body: some View {
        Group {
            if SupabaseManager.shared.currentUserId != viewedUserId {
                Color.clear
                    .onAppear {
                        dismiss()
                    }
            } else {
                settingsContent
            }
        }
    }

    private var settingsContent: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ProfileSettingsHeader()

            ScrollView {
                VStack(spacing: 20) {

                    ProfileSettingsAvatarSection(
                        selectedUIImage: selectedUIImage,
                        profileVM: profileVM,
                        selectedPhotoItem: $selectedPhotoItem,
                        isUploadingAvatar: isUploadingAvatar
                    )

                    ProfileSettingsAccountSection(
                        firstName: $firstName,
                        username: $username
                    )

                    ProfileSettingsBackgroundSection(
                        homeCountries: homeCountries,
                        showHomePicker: $showHomePicker
                    )

                    ProfileSettingsTravelSection(
                        travelMode: $travelMode,
                        travelStyle: $travelStyle,
                        showTravelModeDialog: $showTravelModeDialog,
                        showTravelStyleDialog: $showTravelStyleDialog
                    )

                    ProfileSettingsLanguagesSection(
                        languages: languages,
                        showAddLanguage: $showAddLanguage
                    )

                    ProfileSettingsNextDestinationSection(
                        nextDestination: nextDestination,
                        showNextDestinationPicker: $showNextDestinationPicker
                    )

                    SectionCard {
                        Button(role: .destructive) {
                            Task {
                                await sessionManager.signOut()
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.backward.square")
                                Text("Sign Out")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .foregroundStyle(.red)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 90)
            }
        }
        .onAppear {
            guard !hasLoadedProfile else { return }
            hasLoadedProfile = true

            if let profile = profileVM.profile {
                firstName = profile.fullName ?? ""
                username = profile.username ?? ""

                // livedCountries is NON-optional [String]
                homeCountries = Set(profile.livedCountries)

                // travelMode / travelStyle are [String]
                travelMode = profile.travelMode.first.flatMap { TravelMode(rawValue: $0) }
                travelStyle = profile.travelStyle.first.flatMap { TravelStyle(rawValue: $0) }

                // next destination
                nextDestination = profile.nextDestination

                // languages is NON-optional [String]
                languages = profile.languages.map {
                    LanguageEntry(name: $0, proficiency: "native")
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }

            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        selectedUIImage = uiImage
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        let avatarURL = await uploadAvatarIfNeeded()

                        await profileVM.saveProfile(
                            firstName: firstName.isEmpty ? nil : firstName,
                            username: username.isEmpty ? nil : username,
                            homeCountries: Array(homeCountries),
                            languages: languages.map { $0.name },
                            travelMode: travelMode?.rawValue,
                            travelStyle: travelStyle?.rawValue,
                            nextDestination: nextDestination,
                            avatarUrl: avatarURL
                        )
                        dismiss()
                    }
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

    // MARK: - Avatar upload helper
    private func uploadAvatarIfNeeded() async -> String? {
        guard let image = selectedUIImage,
              let userId = profileVM.profile?.id,
              let data = image.jpegData(compressionQuality: 0.85)
        else {
            return nil
        }

        isUploadingAvatar = true
        defer { isUploadingAvatar = false }

        let fileName = "\(userId).jpg"

        do {
            let publicURL = try await profileVM.uploadAvatar(
                data: data,
                fileName: fileName
            )
            return publicURL
        } catch {
            print("🔴 Avatar upload failed:", error)
            return nil
        }
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
                            .foregroundStyle(hasChanges ? .blue : .secondary)
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
