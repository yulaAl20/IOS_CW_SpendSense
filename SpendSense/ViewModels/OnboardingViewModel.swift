//
//  OnboardingViewModel.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-15.
//
import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var name: String = ""
    @Published var monthlyIncome: String = ""
    @Published var savingsGoalPercent: Double = 20
    @Published var selectedCategories: Set<SpendingCategory> = Set(SpendingCategory.allCases)

    // Step 1 — account credentials
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var usedSocialSignUp: Bool = false  

    let totalSteps = 4   // 0:Name 1:Account 2:Income 3:Categories

    var isCurrentStepValid: Bool {
        switch currentStep {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1:
            if usedSocialSignUp { return true }
            return !email.isEmpty && password.count >= 6 && password == confirmPassword
        case 2:
            guard let income = Double(monthlyIncome.replacingOccurrences(of: ",", with: "")) else { return false }
            return income > 0
        case 3: return !selectedCategories.isEmpty
        default: return true
        }
    }

    var incomeDouble: Double {
        Double(monthlyIncome.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var savingsAmount: Double   { incomeDouble * (savingsGoalPercent / 100) }
    var spendableAmount: Double { incomeDouble - savingsAmount }

    func buildProfile() -> UserProfileModel {
        UserProfileModel(
            name: name,
            email: email,
            monthlyIncome: incomeDouble,
            savingsGoalPercent: savingsGoalPercent,
            selectedCategories: Array(selectedCategories)
        )
    }

    func next() {
        guard currentStep < totalSteps - 1 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentStep += 1 }
    }
    func back() {
        guard currentStep > 0 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentStep -= 1 }
    }
}
