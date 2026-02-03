import Foundation
import SwiftUI

struct EmailAuthView: View {
    @StateObject private var vm = AuthViewModel()
    @State private var step: Step = .enterEmail
    @FocusState private var focusedField: Field?
    @State private var isSending = false
    @State private var cooldownSeconds = 0

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
}
