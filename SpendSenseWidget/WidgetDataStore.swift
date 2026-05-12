//
//  WidgetDataStore.swift
//  SpendSenseWidget
//

import Foundation

struct WidgetDataStore {
    static let suiteName = "group.SpendSense.com"
    static var defaults: UserDefaults {
        guard let d = UserDefaults(suiteName: suiteName) else {

            return .standard
        }
        return d
    }

    enum Key {
        static let todaySpent     = "widget_todaySpent"
        static let monthlySpent   = "widget_monthlySpent"
        static let monthlyBudget  = "widget_monthlyBudget"
        static let dailyBudget    = "widget_dailyBudget"
        static let remainingDaily = "widget_remainingDaily"
        static let riskLevel      = "widget_riskLevel"
        static let lastCategory   = "widget_lastCategory"
        static let userName       = "widget_userName"
        static let monthlyIncome  = "widget_monthlyIncome"
        static let todayIncome    = "widget_todayIncome"
        static let lastUpdated    = "widget_lastUpdated"
        static let debugSuiteName = "widget_debug_suiteName"
        static let debugWriter    = "widget_debug_writer"
    }
}
