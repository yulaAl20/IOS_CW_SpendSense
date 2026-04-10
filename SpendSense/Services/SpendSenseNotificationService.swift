//
//  SpendSenseNotificationService.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-10.
//

import Foundation
import UserNotifications

final class SpendSenseNotificationService {

    static let shared = SpendSenseNotificationService()
    private init() {}


    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("[Notifications] Auth error: \(error)")
            }
            print("[Notifications] Permission granted: \(granted)")
        }
    }

    //  Impulse Warning

    /// Fire an immediate local notification warning the user about an impulse purchase.
    func sendImpulseWarning(amount: Double,
                            category: String,
                            riskScore: Double) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Impulse Alert"
        content.body  = riskBody(amount: amount, category: category, riskScore: riskScore)
        content.sound = .default
        content.categoryIdentifier = "IMPULSE_WARNING"
        content.userInfo = [
            "amount": amount,
            "category": category,
            "riskScore": riskScore
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // Budget Warning

    func sendBudgetWarning(percentUsed: Int) {
        let content = UNMutableNotificationContent()
        content.title = "💰 Budget Warning"
        content.body  = "You've used \(percentUsed)% of your monthly budget. Slow down to stay on track!"
        content.sound = .default
        content.categoryIdentifier = "BUDGET_WARNING"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "budget-\(percentUsed)",
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    //  Transaction Confirmation

    func sendTransactionConfirmation(amount: Double, category: String) {
        let formatted = "Rs.\(Int(amount))"
        let content = UNMutableNotificationContent()
        content.title = "✅ Logged via Siri"
        content.body  = "\(formatted) in \(category) saved to SpendSense."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // Register Categories 

    func registerNotificationCategories() {
        let cancelAction = UNNotificationAction(identifier: "CANCEL_PURCHASE",
                                                title: "Cancel Purchase",
                                                options: .destructive)
        let proceedAction = UNNotificationAction(identifier: "PROCEED_PURCHASE",
                                                 title: "Proceed Anyway",
                                                 options: .foreground)

        let impulseCategory = UNNotificationCategory(identifier: "IMPULSE_WARNING",
                                                     actions: [cancelAction, proceedAction],
                                                     intentIdentifiers: [],
                                                     options: [])

        UNUserNotificationCenter.current().setNotificationCategories([impulseCategory])
    }

    //  Helpers

    private func riskBody(amount: Double, category: String, riskScore: Double) -> String {
        let pct = Int(riskScore * 100)
        let formatted = "Rs.\(Int(amount))"
        return "\(formatted) in \(category) looks impulsive (\(pct)% risk). Take a moment before buying!"
    }
}
