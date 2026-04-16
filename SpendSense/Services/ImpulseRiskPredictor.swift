//
//  ImpulseRiskPredictor.swift
//  SpendSense
//
//
//  Created by Yulani Alwis on 2026-04-15.
//
import Foundation
import CoreData
import CoreML

struct ImpulseRiskResult {
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

    private lazy var mlModel: MLModel? = {
        guard let url = Bundle.main.url(forResource: "ImpulseClassifier", withExtension: "mlmodelc")
                     ?? Bundle.main.url(forResource: "ImpulseClassifier", withExtension: "mlmodel") else {
            return nil
        }
        return try? MLModel(contentsOf: url)
    }()

    func predictRisk(amount: Double,
                     category: String,
                     hour: Int,
                     recentTransactions: [TransactionModel]) -> ImpulseRiskResult {

        let expenseTransactions = recentTransactions.filter { !$0.isIncome && !$0.isSimulated }

        if let score = predictWithCoreML(amount: amount, category: category,
                                          hour: hour, recentTransactions: expenseTransactions) {
            let reason = score >= 0.7 ? "CoreML model flagged this as high-risk"
                       : score >= 0.4 ? "Moderate risk detected by spending model"
                       : "Low risk — within normal spending pattern"
            return ImpulseRiskResult(score: score, reason: reason)
        }

        return predictHeuristic(amount: amount, category: category,
                                 hour: hour, recentTransactions: expenseTransactions)
    }

    private func predictWithCoreML(amount: Double, category: String,
                                    hour: Int, recentTransactions: [TransactionModel]) -> Double? {
        guard let model = mlModel else { return nil }

        let recentAmounts = recentTransactions.map(\.amount)
        let avgAmount = recentAmounts.isEmpty ? 1500.0 : recentAmounts.reduce(0, +) / Double(recentAmounts.count)
        let todayCount = Double(recentTransactions.filter { Calendar.current.isDateInToday($0.date) }.count)
        let isHighRiskCategory: Double = ["Shopping", "Entertainment"].contains(where: { category.localizedCaseInsensitiveContains($0) }) ? 1.0 : 0.0
        let isLateNight: Double = (hour >= 22 || hour < 5) ? 1.0 : 0.0

        let input = try? MLDictionaryFeatureProvider(dictionary: [
            "amount":             MLFeatureValue(double: amount),
            "avgRecentAmount":    MLFeatureValue(double: avgAmount),
            "amountRatio":        MLFeatureValue(double: avgAmount > 0 ? amount / avgAmount : 1.0),
            "hourOfDay":          MLFeatureValue(double: Double(hour)),
            "todayPurchaseCount": MLFeatureValue(double: todayCount),
            "isHighRiskCategory": MLFeatureValue(double: isHighRiskCategory),
            "isLateNight":        MLFeatureValue(double: isLateNight)
        ])

        guard let input, let output = try? model.prediction(from: input) else { return nil }

        if let score = output.featureValue(for: "riskScore")?.doubleValue {
            return min(max(score, 0.0), 1.0)
        }
        if let label = output.featureValue(for: "classLabel")?.stringValue {
            switch label.lowercased() {
            case "high":     return 0.85
            case "moderate": return 0.55
            default:         return 0.20
            }
        }
        return nil
    }

    private func predictHeuristic(amount: Double,
                                   category: String,
                                   hour: Int,
                                   recentTransactions: [TransactionModel]) -> ImpulseRiskResult {
        var score: Double = 0.0
        var reasons: [String] = []

        let recentAmounts = recentTransactions.map(\.amount)
        let avg = recentAmounts.isEmpty ? 1500.0 : recentAmounts.reduce(0, +) / Double(recentAmounts.count)
        if amount > avg * 2 {
            score += 0.35
            reasons.append("Amount is \(Int(amount / avg))× your average spend")
        } else if amount > avg * 1.3 {
            score += 0.15
            reasons.append("Above-average spending")
        }

        if ["Shopping", "Entertainment"].contains(where: { category.localizedCaseInsensitiveContains($0) }) {
            score += 0.20
            reasons.append("\(category) is a high-risk category")
        }

        if hour >= 22 || hour < 5 {
            score += 0.20
            reasons.append("Late-night purchase")
        } else if hour >= 20 {
            score += 0.10
            reasons.append("Evening purchase")
        }

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

    func predictRisk(amount: Double,
                     category: String,
                     context: NSManagedObjectContext) -> ImpulseRiskResult {
        let store = CoreDataStore(context: context)
        let recent = (try? store.fetchTransactions()) ?? []
        let hour = Calendar.current.component(.hour, from: Date())
        return predictRisk(amount: amount, category: category, hour: hour, recentTransactions: recent)
    }
}
