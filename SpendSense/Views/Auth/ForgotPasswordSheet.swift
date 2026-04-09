//
//  ForgotPasswordSheet.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-02.
//
import SwiftUI

struct ForgotPasswordSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme
    @State private var email = ""
    @State private var sent  = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.ssBackground.ignoresSafeArea()

                VStack(spacing: 28) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.ssAccent.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: sent ? "checkmark.circle.fill" : "lock.rotation")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.ssAccent)
                    }
                    .animation(.spring(response: 0.4), value: sent)
                    .padding(.top, 16)

                    VStack(spacing: 8) {
                        Text(sent ? "Check your inbox" : "Reset Password")
                            .font(SSFont.display(24, weight: .bold))
                            .foregroundColor(.ssTextPrimary)
                        Text(sent
                             ? "We've sent a reset link to **\(email)**. Check your email and follow the instructions."
                             : "Enter your account email and we'll send you a link to reset your password.")
                            .font(SSFont.body(14))
                            .foregroundColor(.ssTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    if !sent {
                        // Email field
                        HStack(spacing: 14) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(focused ? .ssAccent : .ssTextTertiary)
                                .frame(width: 20)
                                .padding(.leading, 16)
                            TextField("your@email.com", text: $email)
                                .font(SSFont.body(15))
                                .foregroundColor(.ssTextPrimary)
                                .accentColor(.ssAccent)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focused)
                                .padding(.vertical, 16)
                                .padding(.trailing, 16)
                        }
                        .background(Color.ssSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.ssBorder, lineWidth: scheme == .dark ? 0.5 : 1))
                        .shadow(color: scheme == .dark ? .clear : Color.black.opacity(0.05), radius: 6, x: 0, y: 2)

                        // Send button
                        Button {
                            guard !email.isEmpty else { return }
                            focused = false
                            withAnimation(.spring(response: 0.4)) { sent = true }
                        } label: {
                            Text("Send Reset Link")
                                .font(SSFont.body(16, weight: .semibold))
                                .foregroundColor(.black.opacity(0.75))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(LinearGradient.ssAccentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: .ssAccentGlow, radius: 8, x: 0, y: 3)
                        }
                    } else {
                        // Back to login after sent
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
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
