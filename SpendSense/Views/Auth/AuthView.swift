//
//  AuthView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-02.
//
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var vm: SpendSenseViewModel
    @Environment(\.colorScheme) var scheme
    @State private var showLogin   = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.ssBackground.ignoresSafeArea()

            Circle()
                .fill(Color.ssAccent.opacity(0.07))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: -60, y: -180)
            Circle()
                .fill(Color.ssViolet.opacity(0.06))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: 100, y: 160)

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(LinearGradient.ssAccentGradient.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 120, height: 120)
                        Circle()
                            .fill(Color.ssSurfaceElevated)
                            .frame(width: 88, height: 88)
                            .overlay(Circle().stroke(LinearGradient.ssAccentGradient.opacity(0.5), lineWidth: 1))
                            .shadow(color: .ssAccentGlow, radius: 20)
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(LinearGradient.ssAccentGradient)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    VStack(spacing: 8) {
                        Text("SpendSense")
                            .font(SSFont.display(34, weight: .bold))
                            .foregroundColor(.ssTextPrimary)
                        Text("Spend smarter. Live better.")
                            .font(SSFont.body(16))
                            .foregroundColor(.ssTextSecondary)
                    }
                    .opacity(logoOpacity)
                }

                Spacer()

                // Feature highlights
                VStack(spacing: 14) {
                    AuthFeatureRow(icon: "chart.pie.fill",     color: .ssAccent,  text: "Track budgets & spending in real time")
                    AuthFeatureRow(icon: "brain.head.profile", color: .ssViolet,  text: "AI-powered smart spending insights")
                    AuthFeatureRow(icon: "bell.badge.fill",    color: .ssWarning, text: "Personalised budget warnings & alerts")
                }
                .padding(.horizontal, 32)
                .opacity(contentOpacity)

                Spacer().frame(height: 48)

                // CTA buttons
                VStack(spacing: 14) {
                    // Create account ->Terms ->Onboarding (email/pw collected on last onboarding step)
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            appState.appPhase = .terms
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Create Account")
                                .font(SSFont.body(16, weight: .semibold))
                        }
                        .foregroundColor(.black.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.ssAccentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .ssAccentGlow, radius: 12, x: 0, y: 4)
                    }

                    Button { showLogin = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Log In")
                                .font(SSFont.body(16, weight: .semibold))
                        }
                        .foregroundColor(.ssTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.ssSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.ssBorder, lineWidth: scheme == .dark ? 0.5 : 1)
                        )
                    }

                    Text("By continuing you agree to our **Terms of Service** and **Privacy Policy**")
                        .font(SSFont.body(12))
                        .foregroundColor(.ssTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.horizontal, 24)
                .opacity(contentOpacity)

                Spacer().frame(height: 48)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
                contentOpacity = 1.0
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
                .environmentObject(appState)
                .environmentObject(vm)
        }
    }
}
