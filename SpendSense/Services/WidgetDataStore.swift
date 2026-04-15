//
//  WidgetDataStore.swift
//  SpendSense
//
//
//  Created by Yulani Alwis on 2026-04-15.
//

import Foundation
import WidgetKit

struct WidgetDataStore {

    static let suiteName = "group.com.spendsense.app"
    static var defaults: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }

    // Keys
    private enum Key {
        static let todaySpent     = "widget_todaySpent"
        static let monthlySpent   = "widget_monthlySpent"
        static let monthlyBudget  = "widget_monthlyBudget"
        static let dailyBudget    = "widget_dailyBudget"
        static let remainingDaily = "widget_remainingDaily"
        static let riskLevel      = "widget_riskLevel"
        static let lastCategory   = "widget_lastCategory"
        static let userName       = "widget_userName"
        static let lastUpdated    = "widget_lastUpdated"
    }

    // Save

    static func save(todaySpent: Double, monthlySpent: Double,
                     monthlyBudget: Double, dailyBudget: Double,
                     remainingDaily: Double, riskLevel: String,
                     lastCategory: String, userName: String) {
        let d = defaults
        d.set(todaySpent,      forKey: Key.todaySpent)
        d.set(monthlySpent,    forKey: Key.monthlySpent)
        d.set(monthlyBudget,   forKey: Key.monthlyBudget)
        d.set(dailyBudget,     forKey: Key.dailyBudget)
        d.set(remainingDaily,  forKey: Key.remainingDaily)
        d.set(riskLevel,       forKey: Key.riskLevel)
        d.set(lastCategory,    forKey: Key.lastCategory)
        d.set(userName,        forKey: Key.userName)
        d.set(Date().timeIntervalSince1970, forKey: Key.lastUpdated)
    }

    // Load

    static func load() -> (todaySpent: Double, monthlySpent: Double,
                            monthlyBudget: Double, dailyBudget: Double,
                            remainingDaily: Double, riskLevel: String,
                            lastCategory: String, userName: String) {
        let d = defaults
        return (
            todaySpent:     d.double(forKey: Key.todaySpent),
            monthlySpent:   d.double(forKey: Key.monthlySpent),
            monthlyBudget:  d.double(forKey: Key.monthlyBudget),
            dailyBudget:    d.double(forKey: Key.dailyBudget),
            remainingDaily: d.double(forKey: Key.remainingDaily),
            riskLevel:      d.string(forKey: Key.riskLevel) ?? "Low",
            lastCategory:   d.string(forKey: Key.lastCategory) ?? "--",
            userName:       d.string(forKey: Key.userName) ?? ""
        )
    }

    // Clear 

    static func clearAll() {
        let d = defaults
        for key in [Key.todaySpent, Key.monthlySpent, Key.monthlyBudget,
                    Key.dailyBudget, Key.remainingDaily, Key.riskLevel,
                    Key.lastCategory, Key.userName, Key.lastUpdated] {
            d.removeObject(forKey: key)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
