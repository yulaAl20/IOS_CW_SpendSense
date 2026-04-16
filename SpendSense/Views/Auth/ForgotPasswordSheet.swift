//
//  ForgotPasswordSheet.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-02.
//
import SwiftUI
import FirebaseAuth

struct ForgotPasswordSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    private enum Step {
        case requestLink
        case enterCode
        case done
    }

    private enum Field {
        case email
        case code
        case newPassword
        case confirmPassword
    }

    @State private var step: Step = .requestLink

    @State private var email = ""
    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var verifiedEmail = ""

    @State private var isWorking = false
    @State private var errorMsg = ""
    @State private var showError = false

    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationView {
            ZStack {
                Color.ssBackground.ignoresSafeArea()

                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(Color.ssAccent.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: iconName)
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.ssAccent)
                    }
                    .animation(.spring(response: 0.4), value: step)
                    .padding(.top, 16)

                    VStack(spacing: 8) {
                        Text(titleText)
                            .font(SSFont.display(24, weight: .bold))
                            .foregroundColor(.ssTextPrimary)

                        Text(subtitleText)
                            .font(SSFont.body(14))
                            .foregroundColor(.ssTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    switch step {
                    case .requestLink:
                        VStack(spacing: 14) {
                            fieldRow(icon: "envelope.fill",
                                     placeholder: "your@email.com",
                                     text: $email,
                                     isSecure: false,
                                     keyboardType: .emailAddress,
                                     field: .email)

                            if showError {
                                errorRow
                            }

                            Button { sendResetLink() } label: {
                                ZStack {
                                    if isWorking {
                                        ProgressView().tint(.black.opacity(0.6))
                                    } else {
                                        Text("Send Reset Link")
                                            .font(SSFont.body(16, weight: .semibold))
                                            .foregroundColor(.black.opacity(0.75))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(LinearGradient.ssAccentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: .ssAccentGlow, radius: 8, x: 0, y: 3)
                            }
                            .disabled(isWorking)
                        }

                    case .enterCode:
                        VStack(spacing: 14) {
                            Text("Paste the code from the reset link (the value after `oobCode=`) and choose a new password.")
                                .font(SSFont.body(12))
                                .foregroundColor(.ssTextTertiary)
                                .multilineTextAlignment(.center)

                            fieldRow(icon: "number",
                                     placeholder: "Reset code",
                                     text: $resetCode,
                                     isSecure: false,
                                     keyboardType: .asciiCapable,
                                     textContentType: .oneTimeCode,
                                     field: .code)

                            fieldRow(icon: "lock.fill",
                                     placeholder: "New password",
                                     text: $newPassword,
                                     isSecure: true,
                                     keyboardType: .default,
                                     textContentType: .newPassword,
                                     field: .newPassword)

                            fieldRow(icon: "lock.fill",
                                     placeholder: "Confirm password",
                                     text: $confirmPassword,
                                     isSecure: true,
                                     keyboardType: .default,
                                     textContentType: .newPassword,
                                     field: .confirmPassword)

                            if !verifiedEmail.isEmpty {
                                Text("Resetting password for **\(verifiedEmail)**")
                                    .font(SSFont.body(12, weight: .medium))
                                    .foregroundColor(.ssTextSecondary)
                            }

                            if showError {
                                errorRow
                            }

                            Button { resetPassword() } label: {
                                ZStack {
                                    if isWorking {
                                        ProgressView().tint(.black.opacity(0.6))
                                    } else {
                                        Text("Reset Password")
                                            .font(SSFont.body(16, weight: .semibold))
                                            .foregroundColor(.black.opacity(0.75))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(LinearGradient.ssAccentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: .ssAccentGlow, radius: 8, x: 0, y: 3)
                            }
                            .disabled(isWorking)

                            Button("Back to Sign In") { dismiss() }
                                .font(SSFont.body(15, weight: .semibold))
                                .foregroundColor(.ssAccent)
                                .padding(.top, 2)
                        }

                    case .done:
                        VStack(spacing: 14) {
                            if showError {
                                errorRow
                            }

                            Button {
                                dismiss()
                            } label: {
                                Text("Back to Sign In")
                                    .font(SSFont.body(16, weight: .semibold))
                                    .foregroundColor(.ssAccent)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color.ssAccent.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(Color.ssAccent.opacity(0.3), lineWidth: 0.5))
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.ssAccent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            focusedField = .email
        }
    }

    private var iconName: String {
        switch step {
        case .requestLink: return "lock.rotation"
        case .enterCode:   return "key.fill"
        case .done:        return "checkmark.circle.fill"
        }
    }

    private var titleText: String {
        switch step {
        case .requestLink: return "Reset Password"
        case .enterCode:   return "Enter Reset Code"
        case .done:        return "Password updated"
        }
    }

    private var subtitleText: String {
        switch step {
        case .requestLink:
            return "Enter your account email and we’ll send you a reset link."
        case .enterCode:
            return "Use the code from the email to authorise the reset and set a new password."
        case .done:
            return "Your password has been updated in Firebase. You can now sign in with the new password."
        }
    }

    private var errorRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.ssDanger)
            Text(errorMsg)
                .font(SSFont.body(13))
                .foregroundColor(.ssDanger)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }

    private func fieldRow(icon: String,
                          placeholder: String,
                          text: Binding<String>,
                          isSecure: Bool,
                          keyboardType: UIKeyboardType,
                          textContentType: UITextContentType? = nil,
                          field: Field) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(focusedField == field ? .ssAccent : .ssTextTertiary)
                .frame(width: 20)
                .padding(.leading, 16)

            if isSecure {
                SecureField(placeholder, text: text)
                    .font(SSFont.body(15))
                    .foregroundColor(.ssTextPrimary)
                    .accentColor(.ssAccent)
                    .textContentType(textContentType)
                    .focused($focusedField, equals: field)
                    .padding(.vertical, 16)
                    .padding(.trailing, 16)
            } else {
                TextField(placeholder, text: text)
                    .font(SSFont.body(15))
                    .foregroundColor(.ssTextPrimary)
                    .accentColor(.ssAccent)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .textContentType(textContentType)
                    .focused($focusedField, equals: field)
                    .padding(.vertical, 16)
                    .padding(.trailing, 16)
            }
        }
        .background(Color.ssSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(Color.ssBorder, lineWidth: scheme == .dark ? 0.5 : 1))
        .shadow(color: scheme == .dark ? .clear : Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func sendResetLink() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMsg = "Please enter your email address."
            showError = true
            return
        }
        guard trimmed.contains("@"), trimmed.contains(".") else {
            errorMsg = "Please enter a valid email address."
            showError = true
            return
        }

        showError = false
        isWorking = true
        focusedField = nil

        Task { @MainActor in
            defer { isWorking = false }
            do {
                try await FirebaseService.shared.sendPasswordReset(email: trimmed)
                withAnimation(.spring(response: 0.4)) { step = .enterCode }
                focusedField = .code
            } catch {
                let ns = error as NSError
                if let code = AuthErrorCode(rawValue: ns.code), code == .userNotFound {
                    withAnimation(.spring(response: 0.4)) { step = .enterCode }
                    focusedField = .code
                    return
                }

                errorMsg = error.localizedDescription
                showError = true
            }
        }
    }

    private func resetPassword() {
        let trimmedCode = resetCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            errorMsg = "Please enter the reset code from the email."
            showError = true
            return
        }

        guard newPassword.count >= 6 else {
            errorMsg = "Password must be at least 6 characters."
            showError = true
            return
        }

        guard newPassword == confirmPassword else {
            errorMsg = "Passwords do not match."
            showError = true
            return
        }

        showError = false
        isWorking = true
        focusedField = nil

        Task { @MainActor in
            defer { isWorking = false }
            do {
                verifiedEmail = try await FirebaseService.shared.verifyPasswordResetCode(trimmedCode)
                try await FirebaseService.shared.confirmPasswordReset(code: trimmedCode, newPassword: newPassword)

                resetCode = ""
                newPassword = ""
                confirmPassword = ""

                withAnimation(.spring(response: 0.4)) { step = .done }
            } catch {
                errorMsg = error.localizedDescription
                showError = true
            }
        }
    }
}
