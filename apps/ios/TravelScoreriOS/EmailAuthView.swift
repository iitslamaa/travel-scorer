import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit
import Supabase

// Keep this in the same file for now so Xcode can always find it.
struct TranslucentAuthButton<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
    }
}

struct EmailAuthView: View {
    @StateObject private var vm = AuthViewModel()
    @State private var step: Step = .enterEmail
    @State private var showEmailFlow = false
    @FocusState private var focusedField: Field?
    @State private var isSending = false
    @State private var cooldownSeconds = 0
    @State private var appleNonce: String?
    @State private var appleError: String?
    @State private var googleError: String?

    enum Step {
        case enterEmail
        case enterCode
    }

    enum Field {
        case email
        case code
    }

    var body: some View {
        VStack {
            Spacer()

            ZStack {
                if !showEmailFlow {
                    VStack(spacing: 20) {
                        // Apple
                        TranslucentAuthButton {
                            SignInWithAppleButton(.signIn) { request in
                                let nonce = randomNonceString()
                                appleNonce = nonce
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = sha256(nonce)
                            } onCompletion: { result in
                                Task {
                                    switch result {
                                    case .success(let authorization):
                                        guard
                                            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                                            let tokenData = credential.identityToken,
                                            let idToken = String(data: tokenData, encoding: .utf8),
                                            let nonce = appleNonce
                                        else {
                                            appleError = "Apple Sign In failed."
                                            return
                                        }

                                        do {
                                            let credentials = OpenIDConnectCredentials(
                                                provider: .apple,
                                                idToken: idToken,
                                                nonce: nonce
                                            )
                                            try await vm.client.auth.signInWithIdToken(credentials: credentials)
                                            appleError = nil
                                        } catch {
                                            appleError = error.localizedDescription
                                        }

                                    case .failure(let error):
                                        appleError = error.localizedDescription
                                    }
                                }
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 52)
                        }

                        // Google
                        TranslucentAuthButton {
                            Button {
                                Task {
                                    do {
                                        try await vm.client.auth.signInWithOAuth(
                                            provider: .google,
                                            redirectTo: URL(string: "travelscorer://login-callback")
                                        )
                                        googleError = nil
                                    } catch {
                                        googleError = error.localizedDescription
                                    }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image("google_logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)

                                    Text("Continue with Google")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black.opacity(0.85))
                                }
                            }
                        }

                        // Email entry trigger (no keyboard yet)
                        TranslucentAuthButton {
                            Button {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showEmailFlow = true
                                }
                            } label: {
                                Text("Continue with Email")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black.opacity(0.85))
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if showEmailFlow && step == .enterEmail {
                    FrostedCard {
                        VStack(spacing: 14) {
                            Text("Enter your email address")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextField("Email address", text: $vm.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.25))
                                )
                                .focused($focusedField, equals: .email)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        focusedField = .email
                                    }
                                }

                            Button {
                                guard !isSending && cooldownSeconds == 0 else { return }
                                isSending = true

                                Task {
                                    await vm.sendEmailOTP()
                                    await MainActor.run {
                                        isSending = false
                                        if vm.errorMessage == nil {
                                            step = .enterCode
                                            focusedField = .code
                                            cooldownSeconds = 30
                                            startCooldown()
                                        }
                                    }
                                }
                            } label: {
                                if isSending {
                                    ProgressView()
                                } else {
                                    Text(cooldownSeconds > 0 ? "Resend in \(cooldownSeconds)s" : "Send code")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSending || cooldownSeconds > 0 || vm.email.isEmpty)
                        }
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }

                if step == .enterCode {
                    FrostedCard {
                        VStack(spacing: 14) {
                            Text("Check your email for the 6‑digit code")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            TextField("6‑digit code", text: $vm.otp)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.25))
                                )
                                .focused($focusedField, equals: .code)

                            Button {
                                Task { await vm.verifyEmailOTP() }
                            } label: {
                                if vm.isLoading {
                                    ProgressView()
                                } else {
                                    Text("Verify")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(vm.isLoading || vm.otp.count < 6)

                            Button("Change email") {
                                vm.otp = ""
                                step = .enterEmail
                                focusedField = .email
                            }
                            .font(.footnote)
                        }
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showEmailFlow)
            .animation(.easeInOut(duration: 0.4), value: step)

            Spacer()
        }
        .padding()
    }

    private func startCooldown() {
        Task {
            while cooldownSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    cooldownSeconds -= 1
                }
            }
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)

        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce")
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
