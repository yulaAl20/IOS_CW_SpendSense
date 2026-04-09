//
//  LoginView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-02.
//
import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var vm: SpendSenseViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var email       = ""
    @State private var password    = ""
    @State private var isLoading   = false
    @State private var errorMsg    = ""
    @State private var showError   = false
    @State private var showForgotPassword = false
    @FocusState private var focused: LoginField?

    enum LoginField { case email, password }

    var body: some View {
        ZStack {
            Color.ssBackground.ignoresSafeArea()

            Circle()
                .fill(Color.ssAccent.opacity(0.06))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: 80, y: -200)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.ssTextSecondary)
                                    .padding(10)
                                    .background(scheme == .dark
                                                ? Color.white.opacity(0.08)
                                                : Color.black.opacity(0.05))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.ssSurfaceElevated)
                                    .frame(width: 64, height: 64)
                                    .overlay(Circle().stroke(LinearGradient.ssAccentGradient.opacity(0.5), lineWidth: 1))
                                Image(systemName: "waveform.path.ecg")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(LinearGradient.ssAccentGradient)
                            }
                            Text("Welcome back")
                                .font(SSFont.display(28, weight: .bold))
                                .foregroundColor(.ssTextPrimary)
                            Text("Sign in to your SpendSense account")
                                .font(SSFont.body(15))
                                .foregroundColor(.ssTextSecondary)
                        }
                        .padding(.top, 8)
                    }

                    Spacer().frame(height: 36)

                    VStack(spacing: 16) {
                        // Email / Password fields
                        VStack(spacing: 0) {
                            LoginInputRow(icon: "envelope.fill", placeholder: "Email address",
                                         text: $email, isSecure: false, field: .email, focused: $focused)
                            Divider().overlay(Color.ssBorder).padding(.leading, 56)
                            LoginInputRow(icon: "lock.fill", placeholder: "Password",
                                         text: $password, isSecure: true, field: .password, focused: $focused)
                        }
                        .background(Color.ssSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.ssBorder, lineWidth: scheme == .dark ? 0.5 : 1))
                        .shadow(color: scheme == .dark ? .clear : Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

                        HStack {
                            Spacer()
                            Button("Forgot password?") { showForgotPassword = true }
                                .font(SSFont.body(13, weight: .medium))
                                .foregroundColor(.ssAccent)
                        }

                        if showError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.ssDanger)
                                Text(errorMsg)
                                    .font(SSFont.body(13))
                                    .foregroundColor(.ssDanger)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Sign In button
                        Button { loginWithEmail() } label: {
                            ZStack {
                                if isLoading {
                                    ProgressView().tint(.black.opacity(0.6))
                                } else {
                                    Text("Sign In")
                                        .font(SSFont.body(16, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.75))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(LinearGradient.ssAccentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .ssAccentGlow, radius: 10, x: 0, y: 3)
                        }
                        .disabled(isLoading)

                        // Divider
                        HStack(spacing: 12) {
                            Rectangle().fill(Color.ssBorder).frame(height: 0.5)
                            Text("or continue with")
                                .font(SSFont.body(12))
                                .foregroundColor(.ssTextTertiary)
                                .fixedSize()
                            Rectangle().fill(Color.ssBorder).frame(height: 0.5)
                        }

                        // ── Biometric + Social row ──────────────────
                        // Face ID: icon-only circle button
                        // Apple / Google: centered full-width buttons
                        VStack(spacing: 12) {
                            // Face ID — icon only, circular
                            Button { loginWithBiometrics() } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.ssAccent.opacity(0.1))
                                        .frame(width: 58, height: 58)
                                        .overlay(
                                            Circle().strokeBorder(
                                                Color.ssAccent.opacity(0.35),
                                                lineWidth: scheme == .dark ? 0.5 : 1)
                                        )
                                    Image(systemName: "faceid")
                                        .font(.system(size: 26, weight: .medium))
                                        .foregroundColor(.ssAccent)
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)   // centre in the column

                            // Apple
                            CenteredSocialButton(
                                icon: "apple.logo",
                                label: "Continue with Apple",
                                foreground: scheme == .dark ? Color.white : Color.black,
                                background: scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06),
                                border: scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.12)
                            ) { socialLogin() }

                            // Google
                            CenteredSocialButton(
                                icon: "globe",
                                label: "Continue with Google",
                                foreground: Color.ssTextPrimary,
                                background: Color.ssSurface,
                                border: Color.ssBorder
                            ) { socialLogin() }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)

                    HStack(spacing: 6) {
                        Text("Don't have an account?")
                            .font(SSFont.body(14))
                            .foregroundColor(.ssTextSecondary)
                        Button("Sign up") {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                withAnimation { appState.appPhase = .terms }
                            }
                        }
                        .font(SSFont.body(14, weight: .semibold))
                        .foregroundColor(.ssAccent)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet()
        }
    }

    private func loginWithEmail() {
        focused = nil
        guard !email.isEmpty else { errorMsg = "Please enter your email address."; showError = true; return }
        guard !password.isEmpty else { errorMsg = "Please enter your password."; showError = true; return }
        showError  = false
        isLoading  = true
        Task { @MainActor in
            do {
                let uid = try await FirebaseService.shared.signIn(email: email, password: password)
                appState.pendingFirebaseUID = uid
                appState.pendingEmail       = email
                vm.loadFromFirestore(uid: uid)   // pull this user's data from Firestore
                isLoading = false
                appState.login()
            } catch {
                isLoading = false
                errorMsg  = error.localizedDescription
                showError = true
            }
        }
    }

    private func loginWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMsg = "Biometrics not available on this device."
            showError = true
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                localizedReason: "Sign in to SpendSense") { success, authError in
            DispatchQueue.main.async {
                if success { appState.login() }
                else { errorMsg = authError?.localizedDescription ?? "Authentication failed."; showError = true }
            }
        }
    }

    private func socialLogin() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isLoading = false
            appState.login()
        }
    }
}
