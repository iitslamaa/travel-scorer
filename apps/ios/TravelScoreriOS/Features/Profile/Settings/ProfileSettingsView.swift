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
    @State private var currentCountry: String? = nil
    @State private var favoriteCountries: [String] = []

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
    @State private var showCurrentCountryPicker = false
    @State private var showFavoriteCountriesPicker = false
    @State private var showAddLanguage = false

    // Delete account state
    @State private var showDeleteConfirm = false
    @State private var showDeleteSheet = false
    @State private var deleteText = ""
    @State private var isDeleting = false
    @State private var deleteError: String? = nil
    @State private var showSaveSuccess = false
    @State private var isSavingProfile = false
    @State private var usernameError: String? = nil

    private var isFormValid: Bool {
        let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && !trimmedUsername.isEmpty
    }

    private var hasChanges: Bool {
        guard hasLoadedProfile else { return false }
        guard let profile = profileVM.profile else { return false }

        let originalFirstName = profile.fullName
        let originalUsername = profile.username
        let originalHomeCountries = Set(profile.livedCountries)
        let originalTravelMode = profile.travelMode.first.flatMap { TravelMode(rawValue: $0) }
        let originalTravelStyle = profile.travelStyle.first.flatMap { TravelStyle(rawValue: $0) }
        let originalNextDestination = profile.nextDestination
        let originalLanguages: [(String, LanguageProficiency)] =
            profile.languages.map { ($0, .fluent) }

        let currentLanguages: [(String, LanguageProficiency)] =
            languages.map { ($0.name, $0.proficiency) }

        let avatarChanged = shouldRemoveAvatar || selectedUIImage != nil

        return firstName != originalFirstName
            || username != originalUsername
            || homeCountries != originalHomeCountries
            || travelMode != originalTravelMode
            || travelStyle != originalTravelStyle
            || nextDestination != originalNextDestination
            || !currentLanguages.elementsEqual(originalLanguages, by: { $0 == $1 })
            || avatarChanged
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
        AnyView(
            VStack(spacing: 0) {
                mainScrollContent
            }
            .background(Color(.systemBackground))
            .overlay(alignment: .top) {
                successBanner
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
                    languages = profile.languages.map { raw in
                        if let match = LanguageRepository.shared.allLanguages.first(where: { $0.displayName == raw }) {
                            return LanguageEntry(name: match.code, proficiency: .fluent)
                        } else {
                            return LanguageEntry(name: raw, proficiency: .fluent)
                        }
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
            .navigationTitle("Profile Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            let result = await ProfileSettingsSaveCoordinator.handleSave(
                                profileVM: profileVM,
                                firstName: firstName,
                                username: username,
                                homeCountries: homeCountries,
                                languages: languages,
                                travelMode: travelMode,
                                travelStyle: travelStyle,
                                nextDestination: nextDestination,
                                selectedUIImage: selectedUIImage,
                                shouldRemoveAvatar: shouldRemoveAvatar,
                                setSaving: { isSavingProfile = $0 },
                                setAvatarUploading: { isUploadingAvatar = $0 },
                                setAvatarCleared: {
                                    selectedUIImage = nil
                                    shouldRemoveAvatar = false
                                }
                            )

                            switch result {
                            case .success:
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                    showSaveSuccess = true
                                }
                                usernameError = nil

                            case .usernameTaken:
                                usernameError = "Username is already taken"

                            case .failure(let message):
                                usernameError = message
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
                    .tint(hasChanges && isFormValid ? .blue : .gray)
                    .disabled(!hasChanges || !isFormValid || isSavingProfile)
                    .opacity(hasChanges && isFormValid ? 1 : 0.5)
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
                    if !languages.contains(where: { $0.name == entry.name }) {
                        languages.append(entry)
                    }
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
                            Task {
                                await ProfileSettingsDeletionCoordinator.handleDelete(
                                    sessionManager: sessionManager,
                                    dismiss: { dismiss() },
                                    setDeleting: { isDeleting = $0 },
                                    setError: { deleteError = $0 },
                                    closeSheet: { showDeleteSheet = false }
                                )
                            }
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
        )
    }


    private var mainScrollContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Test")
            }
            .padding()
        }
    }

    private var successBanner: some View {
        Group {
            if showSaveSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Profile updated")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 8)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
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


    func markAvatarForRemoval() {
        selectedUIImage = nil
        selectedPhotoItem = nil
        shouldRemoveAvatar = true
    }

}



