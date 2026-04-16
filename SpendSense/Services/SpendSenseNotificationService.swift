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

    func sendExpenseReminder() {
        let content = UNMutableNotificationContent()
        content.title = "SpendSense Check-in"
        content.body = "Log today's spending to stay on budget."
        content.sound = .default

        var date = DateComponents()
        date.hour = 20
        date.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-expense-reminder",
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func sendImpulseWarning(amount: Double,
                            category: String,
                            riskScore: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Impulse Alert"
        content.body = riskBody(amount: amount, category: category, riskScore: riskScore)
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

    func sendBudgetWarning(percentUsed: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Budget Warning"
        content.body = "You've used \(percentUsed)% of your monthly budget."
        content.sound = .default
        content.categoryIdentifier = "BUDGET_WARNING"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "budget-\(percentUsed)",
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func sendTransactionConfirmation(amount: Double, category: String) {
        let content = UNMutableNotificationContent()
        content.title = "Logged via Siri"
        content.body = "Rs.\(Int(amount)) in \(category) saved to SpendSense."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func sendLocationAlert(zoneName: String, remainingBudget: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Location Alert"
        content.body = "You're near \(zoneName). Remaining daily budget: Rs.\(Int(max(0, remainingBudget)))."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func riskBody(amount: Double, category: String, riskScore: Double) -> String {
        let pct = Int(riskScore * 100)
        return "Rs.\(Int(amount)) in \(category) looks impulsive (\(pct)% risk)."
    }
}
