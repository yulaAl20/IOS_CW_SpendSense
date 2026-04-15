//
//  ImpulseRiskPredictor.swift
//  SpendSense
//
//
//  Created by Yulani Alwis on 2026-04-15.
//

import Foundation
import CoreData

struct ImpulseRiskResult {
    /// 0.0 – 1.0 (higher = riskier)
    let score: Double
    var level: RiskLevel {
        if score < 0.4 { return .low }
        if score < 0.7 { return .moderate }
        return .high
    }
    let reason: String
}

final class ImpulseRiskPredictor {

    static let shared = ImpulseRiskPredictor()
    private init() {}

    func predictRisk(amount: Double,
                     category: String,
                     hour: Int,
                     recentTransactions: [TransactionModel]) -> ImpulseRiskResult {

        var score: Double = 0.0
        var reasons: [String] = []

        //  Factor 1: Amount vs. average 
        let recentAmounts = recentTransactions.map(\.amount)
        let avg = recentAmounts.isEmpty ? 1500 : recentAmounts.reduce(0, +) / Double(recentAmounts.count)
        if amount > avg * 2 {
            score += 0.35
            reasons.append("Amount is \(Int(amount / avg))× your average spend")
        } else if amount > avg * 1.3 {
            score += 0.15
            reasons.append("Above-average spending")
        }

        //  Factor 2: High-risk category 
        let highRisk = ["Shopping", "Entertainment"]
        if highRisk.contains(where: { category.localizedCaseInsensitiveContains($0) }) {
            score += 0.20
            reasons.append("\(category) is a high-risk category")
        }

        //  Factor 3: Late-night spending 
        if hour >= 22 || hour < 5 {
            score += 0.20
            reasons.append("Late-night purchase")
        } else if hour >= 20 {
            score += 0.10
            reasons.append("Evening purchase")
        }

        //  Factor 4: Purchase frequency today 
        let todayCount = recentTransactions.filter { Calendar.current.isDateInToday($0.date) }.count
        if todayCount >= 5 {
            score += 0.15
            reasons.append("\(todayCount) purchases already today")
        } else if todayCount >= 3 {
            score += 0.08
        }

        score = min(score, 1.0)
        let reason = reasons.isEmpty ? "Low risk — no red flags detected" : reasons.joined(separator: ". ")
        return ImpulseRiskResult(score: score, reason: reason)
    }

    //Convenience: predict using Core Data context directly.
    func predictRisk(amount: Double,
                     category: String,
                     context: NSManagedObjectContext) -> ImpulseRiskResult {
        let store = CoreDataStore(context: context)
        let recent = (try? store.fetchTransactions()) ?? []
        let hour = Calendar.current.component(.hour, from: Date())
        return predictRisk(amount: amount, category: category, hour: hour, recentTransactions: recent)
    }
}
