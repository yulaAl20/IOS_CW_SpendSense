//
//  WidgetDataStore.swift
//  SpendSenseWidget
//

import Foundation

struct WidgetDataStore {
    static let suiteName = "group.com.spendsense.app"
    static var defaults: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }
}
