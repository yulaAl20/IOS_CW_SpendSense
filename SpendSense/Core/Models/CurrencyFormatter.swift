//
//  CurrencyFormatter.swift
//  SpendSense
//
//  Centralized currency formatting (UI + accessibility).
//  Defaults to Sri Lankan Rupee (LKR).
//

import Foundation

enum CurrencyFormatter {
    /// UserDefaults key for persisting the app currency.
    static let currencyCodeDefaultsKey = "SpendSense.currencyCode"

    /// Default currency code when the user hasn't chosen one.
    static let defaultCurrencyCode = "LKR"

    /// Returns the currently selected currency code from UserDefaults, defaulting to LKR.
    static var currencyCode: String {
        let stored = UserDefaults.standard.string(forKey: currencyCodeDefaultsKey)
        return (stored?.isEmpty == false) ? stored! : defaultCurrencyCode
    }

    /// Update the persisted currency code.
    static func setCurrencyCode(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed.isEmpty ? defaultCurrencyCode : trimmed, forKey: currencyCodeDefaultsKey)
    }

    /// Currency string for on-screen display.
    /// Uses the user's current locale for separators, but forces the currency code.
    static func string(from value: Double, maximumFractionDigits: Int = 0) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        f.currencyCode = currencyCode
        f.maximumFractionDigits = maximumFractionDigits
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(currencyCode) \(Int(value))"
    }

    /// Currency string intended for VoiceOver.
    /// Uses a stable locale so the currency name is spoken correctly (e.g., “Sri Lankan Rupees”).
    static func accessibilityString(from value: Double, maximumFractionDigits: Int = 0) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        // en_LK tends to produce a readable currency name for LKR.
        // Still forcing the currencyCode so the user's chosen currency is honored.
        f.locale = Locale(identifier: "en_LK")
        f.currencyCode = currencyCode
        f.maximumFractionDigits = maximumFractionDigits
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(currencyCode) \(Int(value))"
    }
}
