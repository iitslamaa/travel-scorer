import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit
import Supabase

struct EmailAuthView: View {
    @StateObject private var vm = AuthViewModel()
    @State private var step: Step = .enterEmail
    @FocusState private var focusedField: Field?
    @State private var isSending = false
    @State private var cooldownSeconds = 0
    @State private var appleNonce: String?
    @State private var appleError: String?

    enum Step {
        case enterEmail
        case enterCode
    }

    enum Field {
        case email
        case code
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Sign in")
                .font(.largeTitle)
                .bold()

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
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if step == .enterEmail {
                TextField("Email address", text: $vm.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .email)

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
                        Text(
                            cooldownSeconds > 0
                            ? "Resend in \(cooldownSeconds)s"
                            : "Send code"
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSending || cooldownSeconds > 0 || vm.email.isEmpty)
            }

            if step == .enterCode {
                Text("Check your email for the 6‑digit code")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("6‑digit code", text: $vm.otp)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
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

            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            if let appleError {
                Text(appleError)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            focusedField = .email
        }
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
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
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
