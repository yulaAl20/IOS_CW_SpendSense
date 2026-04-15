//
//  SplashView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-15.
//


import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @State private var dotsOpacity: Double = 0
    @State private var currentDot: Int = 0

    private let dotTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background
            Color.ssBackground.ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(Color.ssAccent.opacity(0.06))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(y: -60)

            Circle()
                .fill(Color.ssViolet.opacity(0.05))
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: 80, y: 120)

            VStack(spacing: 0) {
                Spacer()

                // Logo lockup
                ZStack {
                    // Outer ring pulse
                    Circle()
                        .stroke(
                            LinearGradient.ssAccentGradient.opacity(0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 130, height: 130)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Inner ring
                    Circle()
                        .stroke(
                            LinearGradient.ssAccentGradient.opacity(0.6),
                            lineWidth: 2
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Icon background
                    Circle()
                        .fill(Color.ssSurfaceElevated)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(LinearGradient.ssAccentGradient.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: .ssAccent.opacity(0.25), radius: 20, x: 0, y: 0)

                    // Dollar/sense icon
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(LinearGradient.ssAccentGradient)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 32)

                // App name
                VStack(spacing: 6) {
                    Text("SpendSense")
                        .font(SSFont.display(36, weight: .bold))
                        .foregroundColor(.ssTextPrimary)
                        .opacity(logoOpacity)

                    Text("Spend smarter. Live better.")
                        .font(SSFont.body(15))
                        .foregroundColor(.ssTextSecondary)
                        .opacity(taglineOpacity)
                }

                Spacer().frame(height: 64)

                // Loading dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == currentDot ? Color.ssAccent : Color.ssBorder)
                            .frame(width: 7, height: 7)
                            .scaleEffect(i == currentDot ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3), value: currentDot)
                    }
                }
                .opacity(dotsOpacity)

                Spacer()

                // Version
                Text("v1.0.0")
                    .font(SSFont.body(12))
                    .foregroundColor(.ssTextTertiary)
                    .opacity(taglineOpacity)
                    .padding(.bottom, 32)
            }
        }
        .onAppear { startAnimations() }
        .onReceive(dotTimer) { _ in
            currentDot = (currentDot + 1) % 3
        }
    }

    private func startAnimations() {
        // Logo entrance
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
            ringScale = 1.0
            ringOpacity = 1.0
        }
        // Tagline
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            taglineOpacity = 1.0
        }
        // Dots
        withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
            dotsOpacity = 1.0
        }
        // Transition to next screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            appState.completeSplash()
        }
    }
}

#if DEBUG
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .environmentObject(AppStateViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif
