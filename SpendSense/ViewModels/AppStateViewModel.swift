//
//  AppStateViewModel.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-09.
//
import SwiftUI
import Combine

class AppStateViewModel: ObservableObject {
    @Published var appPhase: AppPhase = .splash
    @Published var hasAcceptedTerms: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var isLoggedIn: Bool = false
    @Published var selectedTab: TabItem = .home
    @Published var selectedAppearance: AppearanceMode = .dark
    @Published var faceIDEnabled: Bool = UserDefaults.standard.bool(forKey: "faceIDEnabled")

    var pendingEmail: String = ""
    var pendingPassword: String = ""
    var pendingFirebaseUID: String = ""

    enum AppPhase {
        case splash, terms, onboarding, auth, main
    }

    func completeSplash() {
        withAnimation(.easeInOut(duration: 0.5)) {
            appPhase = isLoggedIn ? .main : .auth
        }
    }

    func acceptTerms() {
        hasAcceptedTerms = true
        withAnimation(.easeInOut(duration: 0.5)) { appPhase = .onboarding }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        login()
    }

    func login() {
        isLoggedIn = true
        selectedTab = .home
        withAnimation(.easeInOut(duration: 0.5)) { appPhase = .main }
    }

    func logout() {
        isLoggedIn = false
        selectedTab = .home
        withAnimation(.easeInOut(duration: 0.5)) { appPhase = .auth }
    }

    func enableFaceID(uid: String, email: String) {
        KeychainService.shared.saveCredentials(uid: uid, email: email)
        faceIDEnabled = true
        UserDefaults.standard.set(true, forKey: "faceIDEnabled")
    }

    func disableFaceID() {
        KeychainService.shared.clearCredentials()
        faceIDEnabled = false
        UserDefaults.standard.set(false, forKey: "faceIDEnabled")
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case dark, light, system
    var id: String { rawValue }

    var label: String {
        switch self {
        case .dark:   return "Dark"
        case .light:  return "Light"
        case .system: return "System"
        }
    }

    var icon: String {
        switch self {
        case .dark:   return "moon.stars.fill"
        case .light:  return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .dark:   return .dark
        case .light:  return .light
        case .system: return nil
        }
    }
}

enum TabItem: String, CaseIterable {
    case home      = "Home"
    case budget    = "Budget"
    case add       = "Add"
    case insights  = "Insights"
    case settings  = "Settings"

    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .budget:   return "chart.pie.fill"
        case .add:      return "plus"
        case .insights: return "waveform.path.ecg"
        case .settings: return "gearshape.fill"
        }
    }
}
