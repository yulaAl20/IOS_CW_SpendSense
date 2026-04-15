//
//  RootView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-02.
//


import SwiftUI
import LocalAuthentication

struct RootView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var vm: SpendSenseViewModel

    var body: some View {
        ZStack {
            Color.ssBackground.ignoresSafeArea()

            switch appState.appPhase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .terms:
                TermsView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity))
            case .onboarding:
                OnboardingView()
                    .environmentObject(appState)
                    .environmentObject(vm)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity))
            case .auth:
                AuthView()
                    .environmentObject(vm)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity))
            case .main:
                MainTabView()
                    .environmentObject(vm)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.appPhase)
        .preferredColorScheme(appState.selectedAppearance.colorScheme)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RootView()
                .environmentObject(AppStateViewModel())
                .environmentObject(SpendSenseViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
            RootView()
                .environmentObject(AppStateViewModel())
                .environmentObject(SpendSenseViewModel())
                .preferredColorScheme(.light)
                .previewDisplayName("Light")
        }
    }
}
