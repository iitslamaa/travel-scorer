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
    @State private var shouldRemoveAvatar = false

    // Sheets / dialogs
    @State private var showTravelModeDialog = false
    @State private var showTravelStyleDialog = false
    @State private var showHomePicker = false
    @State private var showNextDestinationPicker = false
    @State private var showAddLanguage = false

    // Delete account state
    @State private var showDeleteConfirm = false
    @State private var showDeleteSheet = false
    @State private var deleteText = ""
    @State private var isDeleting = false
    @State private var deleteError: String? = nil
    @State private var showSaveSuccess = false
    @State private var isSavingProfile = false

    private var isFormValid: Bool {
        let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && !trimmedUsername.isEmpty
    }

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

                    SectionCard {
                        HStack(alignment: .center, spacing: 16) {

                            ProfileSettingsAvatarSection(
                                selectedUIImage: selectedUIImage,
                                profileVM: profileVM,
                                selectedPhotoItem: $selectedPhotoItem,
                                isUploadingAvatar: isUploadingAvatar,
                                shouldRemoveAvatar: shouldRemoveAvatar,
                                onRemoveAvatar: {
                                    markAvatarForRemoval()
                                }
                            )
                            .frame(width: 120)

                            VStack(spacing: 14) {

                                TextField(
                                    "",
                                    text: $firstName,
                                    prompt:
                                        (Text("Name")
                                            .foregroundStyle(.secondary)
                                         +
                                         Text(" *")
                                            .foregroundStyle(.red))
                                )
                                .padding(12)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                                .foregroundStyle(.primary)
                                .tint(.primary)

                                HStack(spacing: 6) {
                                    Text("@")
                                        .foregroundStyle(.secondary)

                                    TextField(
                                        "",
                                        text: $username,
                                        prompt:
                                            (Text("username")
                                                .foregroundStyle(.secondary)
                                             +
                                             Text(" *")
                                                .foregroundStyle(.red))
                                    )
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .foregroundStyle(.primary)
                                    .tint(.primary)
                                }
                                .padding(12)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                            }
                            .frame(maxHeight: .infinity, alignment: .center)

                            Spacer()
                        }
                    }

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

                    SectionCard {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Account")
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

            // META-style top overlay toast (above everything)
            VStack {
                if showSaveSuccess {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Profile updated")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
            .padding(.top, 16)
            .padding(.horizontal)
            .zIndex(9999)
            .allowsHitTesting(false)
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
                        shouldRemoveAvatar = false
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
                Button {
                    Task {
                        isSavingProfile = true

                        let avatarURL = await resolveAvatarChange()

                        let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

                        await profileVM.saveProfile(
                            firstName: trimmedName,
                            username: trimmedUsername,
                            homeCountries: Array(homeCountries),
                            languages: languages.map { $0.name },
                            travelMode: travelMode?.rawValue,
                            travelStyle: travelStyle?.rawValue,
                            nextDestination: nextDestination,
                            avatarUrl: avatarURL
                        )

                        isSavingProfile = false
                        // ✅ Clear temporary avatar state so future saves don't re-upload
                        selectedUIImage = nil
                        shouldRemoveAvatar = false

                        await MainActor.run {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                showSaveSuccess = true
                            }
                        }

                        try? await Task.sleep(nanoseconds: 1_800_000_000)

                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showSaveSuccess = false
                            }
                        }
                    }
                } label: {
                    if isSavingProfile {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Save")
                    }
                }
                .disabled(!isFormValid || isSavingProfile)
                .opacity(isFormValid ? 1 : 0.5)
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
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Continue", role: .destructive) {
                showDeleteSheet = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }

        // MARK: - Sheets (temporary pickers)

        .sheet(isPresented: $showHomePicker) {
            CountryMultiSelectView(
                title: "Home Countries",
                subtitle: "Add any flag that represents you! Your home country, background, places you've lived, ethnicity, etc.",
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
        .sheet(isPresented: $showDeleteSheet) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Type DELETE to confirm")
                        .font(.headline)

                    TextField("DELETE", text: $deleteText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    if let deleteError {
                        Text(deleteError)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }

                    Button(role: .destructive) {
                        Task { await handleDelete() }
                    } label: {
                        if isDeleting {
                            ProgressView()
                        } else {
                            Text("Permanently Delete")
                        }
                    }
                    .disabled(deleteText.uppercased() != "DELETE" || isDeleting)

                    Spacer()
                }
                .padding()
                .navigationTitle("Delete Account")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            showDeleteSheet = false
                        }
                    }
                }
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

        // 🔥 Versioned filename to avoid image caching
        let fileName = "\(userId)_\(UUID().uuidString).jpg"

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

    private func resolveAvatarChange() async -> String? {
        // If user chose to remove avatar
        if shouldRemoveAvatar {
            return ""
        }

        // Otherwise upload if new image selected
        return await uploadAvatarIfNeeded()
    }

    func markAvatarForRemoval() {
        selectedUIImage = nil
        selectedPhotoItem = nil
        shouldRemoveAvatar = true
    }

    private func handleDelete() async {
        isDeleting = true
        deleteError = nil

        do {
            try await SupabaseManager.shared.deleteAccount()
            showDeleteSheet = false

            // Force app back to auth screen even if a stale local session briefly exists
            sessionManager.handleAccountDeleted()

            dismiss()
        } catch {
            deleteError = "Failed to delete account. Please try again."
        }

        isDeleting = false
    }
}



// MARK: - Temporary picker views (UI only)

private struct CountryMultiSelectView: View {
    let title: String
    let subtitle: String?
    @Binding var selection: Set<String>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var hasChanges = false

    let initialSelection: Set<String>

    init(title: String, subtitle: String? = nil, selection: Binding<Set<String>>) {
        self.title = title
        self.subtitle = subtitle
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

            VStack(alignment: .leading, spacing: 12) {

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 24)
                }

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)

                List {
                    Section {
                        ForEach(filtered, id: \.0) { (code, name) in
                            Button {
                                if selection.contains(code) {
                                    selection.remove(code)
                                } else {
                                    selection.insert(code)
                                }
                                hasChanges = selection != initialSelection
                            } label: {
                                HStack(spacing: 12) {
                                    Text(countryCodeToFlag(code))
                                        .font(.title3)

                                    Text(name)

                                    Spacer()

                                    if selection.contains(code) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(hasChanges ? .blue : .secondary)
                    .disabled(!hasChanges)
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
