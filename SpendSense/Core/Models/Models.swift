//
//  Models.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-09.
//
import Foundation
import SwiftUI

enum SpendingCategory: String, CaseIterable, Codable, Identifiable {
    case food          = "Food & Dining"
    case transport     = "Transport"
    case entertainment = "Entertainment"
    case shopping      = "Shopping"
    case health        = "Health"
    case utilities     = "Utilities"
    case education     = "Education"
    case income        = "Income"
    case other         = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food:          return "fork.knife"
        case .transport:     return "car.fill"
        case .entertainment: return "popcorn.fill"
        case .shopping:      return "bag.fill"
        case .health:        return "heart.fill"
        case .utilities:     return "bolt.fill"
        case .education:     return "book.fill"
        case .income:        return "banknote.fill"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food:          return Color(hex: "#FF6B6B")
        case .transport:     return Color(hex: "#4DA6FF")
        case .entertainment: return Color(hex: "#A78BFA")
        case .shopping:      return Color(hex: "#FFB830")
        case .health:        return Color(hex: "#00E5B0")
        case .utilities:     return Color(hex: "#F97316")
        case .education:     return Color(hex: "#06B6D4")
        case .income:        return Color(hex: "#22C55E")
        case .other:         return Color(hex: "#8A95B0")
        }
    }

    var isExpenseCategory: Bool { self != .income }
}

struct TransactionModel: Identifiable, Codable {
    let id: UUID
    var amount: Double
    var category: SpendingCategory
    var note: String
    var date: Date
    var isSimulated: Bool
    var isIncome: Bool

    init(id: UUID = UUID(), amount: Double, category: SpendingCategory,
         note: String = "", date: Date = Date(),
         isSimulated: Bool = false, isIncome: Bool = false) {
        self.id         = id
        self.amount     = amount
        self.category   = category
        self.note       = note
        self.date       = date
        self.isSimulated = isSimulated
        self.isIncome   = isIncome || category == .income
    }
}

struct BudgetModel: Identifiable, Codable {
    let id: UUID
    var category: SpendingCategory?
    var limit: Double
    var period: BudgetPeriod

    init(id: UUID = UUID(), category: SpendingCategory? = nil,
         limit: Double, period: BudgetPeriod = .monthly) {
        self.id       = id
        self.category = category
        self.limit    = limit
        self.period   = period
    }
}

enum BudgetPeriod: String, CaseIterable, Codable {
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
}

enum RiskLevel: String {
    case low      = "Low"
    case moderate = "Moderate"
    case high     = "High"

    var color: Color {
        switch self {
        case .low:      return .ssSuccess
        case .moderate: return .ssWarning
        case .high:     return .ssDanger
        }
    }
    var icon: String {
        switch self {
        case .low:      return "checkmark.shield.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high:     return "xmark.octagon.fill"
        }
    }
}

struct AlertItemModel: Identifiable {
    let id: UUID
    var title: String
    var message: String
    var type: AlertType
    var date: Date
    var isRead: Bool

    init(id: UUID = UUID(), title: String, message: String,
         type: AlertType, date: Date = Date(), isRead: Bool = false) {
        self.id      = id
        self.title   = title
        self.message = message
        self.type    = type
        self.date    = date
        self.isRead  = isRead
    }
}

enum AlertType {
    case budgetWarning, locationAlert, impulseCheck, milestone

    var icon: String {
        switch self {
        case .budgetWarning:  return "exclamationmark.triangle.fill"
        case .locationAlert:  return "location.fill"
        case .impulseCheck:   return "hand.raised.fill"
        case .milestone:      return "star.fill"
        }
    }
    var color: Color {
        switch self {
        case .budgetWarning:  return .ssWarning
        case .locationAlert:  return .ssViolet
        case .impulseCheck:   return .ssDanger
        case .milestone:      return .ssAccent
        }
    }
}

struct UserProfileModel: Codable {
    var name: String
    var email: String
    var monthlyIncome: Double
    var savingsGoalPercent: Double
    var selectedCategories: [SpendingCategory]
    var firebaseUID: String?

    init(name: String = "", email: String = "",
         monthlyIncome: Double = 0, savingsGoalPercent: Double = 20,
         selectedCategories: [SpendingCategory] = SpendingCategory.allCases.filter { $0.isExpenseCategory },
         firebaseUID: String? = nil) {
        self.name               = name
        self.email              = email
        self.monthlyIncome      = monthlyIncome
        self.savingsGoalPercent = savingsGoalPercent
        self.selectedCategories = selectedCategories
        self.firebaseUID        = firebaseUID
    }

    var savingsGoalAmount: Double { monthlyIncome * (savingsGoalPercent / 100) }
    var spendableAmount: Double   { monthlyIncome - savingsGoalAmount }
}

struct WishlistItemModel: Identifiable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var category: SpendingCategory
    var addedDate: Date
    var waitUntil: Date
    var savingsDays: Int
    var savedAmount: Double
    var dailySavingsAmount: Double
    var lastDeductionDate: Date?

    init(id: UUID = UUID(), name: String, amount: Double,
         category: SpendingCategory, waitDays: Int = 3) {
        self.id                 = id
        self.name               = name
        self.amount             = amount
        self.category           = category
        self.savingsDays        = waitDays
        self.savedAmount        = 0
        self.dailySavingsAmount = waitDays > 0 ? amount / Double(waitDays) : amount
        self.addedDate          = Date()
        self.waitUntil          = Calendar.current.date(byAdding: .day, value: waitDays, to: Date()) ?? Date()
        self.lastDeductionDate  = nil
    }

    var isReadyToPurchase: Bool { Date() >= waitUntil || savedAmount >= amount }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: waitUntil).day ?? 0)
    }

    var daysElapsed: Int {
        max(0, Calendar.current.dateComponents([.day], from: addedDate, to: Date()).day ?? 0)
    }

    var savingsProgress: Double {
        guard amount > 0 else { return 1.0 }
        return min(savedAmount / amount, 1.0)
    }

    var amountRemaining: Double { max(0, amount - savedAmount) }
}
