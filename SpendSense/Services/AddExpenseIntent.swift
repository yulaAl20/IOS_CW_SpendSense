//
//  AddExpenseIntent.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-09.
//

import AppIntents
import CoreData
import WidgetKit

struct AddExpenseIntent: AppIntent {

    // Metadata

    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription(
        "Quickly add a new expense to SpendSense.",
        categoryName: "Finance"
    )

    // widget button action
    static var openAppWhenRun: Bool = false

    // Parameters -for shortcut app

    @IntentParameter(title: "Amount")
    var amount: Double

    @IntentParameter(title: "Category")
    var category: SpendingCategoryEntity

    @IntentParameter(title: "Note", default: "Quick expense")
    var note: String

    // function

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {

        // category
        guard let spendingCategory = SpendingCategory(rawValue: category.id) else {
            return .result(dialog: "Unknown category. Please try again.")
        }

        //  Core Data 
        let context = PersistenceController.shared.container.viewContext
        let store   = CoreDataStore(context: context)

        // save the transaction
        let tx = TransactionModel(
            amount: amount,
            category: spendingCategory,
            note: note
        )
        try store.insertTransaction(tx)

        let risk = ImpulseRiskPredictor.shared.predictRisk(
            amount: amount,
            category: spendingCategory.rawValue,
            context: context
        )

        if risk.score >= 0.5 {
            SpendSenseNotificationService.shared.sendImpulseWarning(
                amount: amount,
                category: spendingCategory.rawValue,
                riskScore: risk.score
            )
        }

        //  Refresh widget
        WidgetCenter.shared.reloadAllTimelines()

        // confirmation
        let formatted = "Rs.\(Int(amount))"
        return .result(dialog: "Done! \(formatted) added to \(spendingCategory.rawValue).")
    }
}