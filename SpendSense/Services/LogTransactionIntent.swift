//
//  LogTransactionIntent.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-09.
//
import AppIntents
import CoreData
import WidgetKit

struct SpendingCategoryEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Spending Category")
    static var defaultQuery = SpendingCategoryQuery()

    var id: String
    var displayName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }

    static let allCategories: [SpendingCategoryEntity] = SpendingCategory.allCases.map {
        SpendingCategoryEntity(id: $0.rawValue, displayName: $0.rawValue)
    }

    static let expenseCategories: [SpendingCategoryEntity] = SpendingCategory.allCases
        .filter { $0.isExpenseCategory }
        .map { SpendingCategoryEntity(id: $0.rawValue, displayName: $0.rawValue) }
}

struct SpendingCategoryQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SpendingCategoryEntity] {
        SpendingCategoryEntity.allCategories.filter { identifiers.contains($0.id) }
    }
    func suggestedEntities() async throws -> [SpendingCategoryEntity] {
        SpendingCategoryEntity.expenseCategories
    }
    func defaultResult() async -> SpendingCategoryEntity? {
        SpendingCategoryEntity.expenseCategories.first
    }
}

struct LogTransactionIntent: AppIntent {

    static var title: LocalizedStringResource = "Log a Spend"
    static var description = IntentDescription(
        "Log a new transaction in SpendSense via Siri and get an impulse-risk check.",
        categoryName: "Finance"
    )

    @IntentParameter(title: "Amount") var amount: Double

    @IntentParameter(
        title: "Category",
        requestValueDialog: IntentDialog("Which spending category is this for?")
    )
    var category: SpendingCategoryEntity

    @IntentParameter(title: "Note", default: "Logged via Siri") var note: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {

        let spendingCategory = SpendingCategory(rawValue: category.id) ?? .other

        let context = PersistenceController.shared.container.viewContext
        let risk = ImpulseRiskPredictor.shared.predictRisk(
            amount: amount, category: spendingCategory.rawValue, context: context)

        let store = CoreDataStore(context: context)
        let transaction = TransactionModel(amount: amount, category: spendingCategory, note: note)
        try store.insertTransaction(transaction)

        recordPurchaseAttempt(context: context, amount: amount,
                              category: spendingCategory.rawValue, riskScore: risk.score)

        if risk.score >= 0.5 {
            SpendSenseNotificationService.shared.sendImpulseWarning(
                amount: amount, category: spendingCategory.rawValue, riskScore: risk.score)
        }

        WidgetCenter.shared.reloadAllTimelines()

        let formatted = "Rs.\(Int(amount))"
        let riskEmoji: String
        switch risk.level {
        case .low:      riskEmoji = "✅"
        case .moderate: riskEmoji = "⚠️"
        case .high:     riskEmoji = "🚨"
        }

        let dialog = "\(riskEmoji) Logged \(formatted) in \(spendingCategory.rawValue). Impulse risk: \(risk.level.rawValue). \(risk.reason)"
        return .result(dialog: "\(dialog)")
    }

    private func recordPurchaseAttempt(context: NSManagedObjectContext,
                                        amount: Double, category: String, riskScore: Double) {
        guard let entity = NSEntityDescription.entity(forEntityName: "PurchaseAttempt", in: context) else { return }
        let obj = NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(UUID(),    forKey: "id")
        obj.setValue(amount,    forKey: "amount")
        obj.setValue(category,  forKey: "category")
        obj.setValue(Date(),    forKey: "attemptTime")
        obj.setValue(riskScore, forKey: "predictedRiskScore")
        obj.setValue(riskScore > 0.7, forKey: "warningShown")
        obj.setValue(riskScore > 0.7 ? "warned" : "proceeded", forKey: "userAction")
        try? context.save()
    }
}

struct AddExpenseIntent: AppIntent {

    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription(
        "Quickly add a new expense to SpendSense.",
        categoryName: "Finance"
    )
    static var openAppWhenRun: Bool = false

    @IntentParameter(title: "Amount") var amount: Double

    @IntentParameter(
        title: "Category",
        requestValueDialog: IntentDialog("Which category does this expense belong to?")
    )
    var category: SpendingCategoryEntity

    @IntentParameter(title: "Note", default: "Quick expense") var note: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {

        let spendingCategory = SpendingCategory(rawValue: category.id) ?? .other

        let context = PersistenceController.shared.container.viewContext
        let store   = CoreDataStore(context: context)

        let tx = TransactionModel(amount: amount, category: spendingCategory, note: note)
        try store.insertTransaction(tx)

        let risk = ImpulseRiskPredictor.shared.predictRisk(
            amount: amount, category: spendingCategory.rawValue, context: context)

        if risk.score >= 0.5 {
            SpendSenseNotificationService.shared.sendImpulseWarning(
                amount: amount, category: spendingCategory.rawValue, riskScore: risk.score)
        }

        WidgetCenter.shared.reloadAllTimelines()

        let formatted = "Rs.\(Int(amount))"
        return .result(dialog: "Done! \(formatted) added to \(spendingCategory.rawValue).")
    }
}

struct AddIncomeIntent: AppIntent {

    static var title: LocalizedStringResource = "Add Income"
    static var description = IntentDescription(
        "Log extra income in SpendSense — freelance, bonuses, gifts, etc.",
        categoryName: "Finance"
    )
    static var openAppWhenRun: Bool = false

    @IntentParameter(title: "Amount") var amount: Double
    @IntentParameter(title: "Source", default: "Extra income") var source: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {

        let context = PersistenceController.shared.container.viewContext
        let store   = CoreDataStore(context: context)

        let tx = TransactionModel(
            amount: amount, category: .income,
            note: source, isIncome: true
        )
        try store.insertTransaction(tx)

        WidgetCenter.shared.reloadAllTimelines()

        let formatted = "Rs.\(Int(amount))"
        return .result(dialog: "Nice! \(formatted) income logged as \(source).")
    }
}

struct CheckBudgetIntent: AppIntent {

    static var title: LocalizedStringResource = "Check My Budget"
    static var description = IntentDescription(
        "Ask Siri how your SpendSense budget is looking today.",
        categoryName: "Finance"
    )

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.container.viewContext
        let store = CoreDataStore(context: context)

        let transactions = (try? store.fetchTransactions()) ?? []
        let budgets      = (try? store.fetchBudgets()) ?? []

        let calendar = Calendar.current
        let now = Date()

        let monthlySpent = transactions
            .filter { !$0.isSimulated && !$0.isIncome &&
                calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }

        let monthlyLimit = budgets
            .first(where: { $0.category == nil && $0.period == .monthly })?.limit ?? 0

        let todaySpent = transactions
            .filter { !$0.isSimulated && !$0.isIncome && calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }

        let todayIncome = transactions
            .filter { $0.isIncome && calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }

        let pct = monthlyLimit > 0 ? Int(monthlySpent / monthlyLimit * 100) : 0
        let remaining = max(0, monthlyLimit - monthlySpent)

        var response = "You've spent Rs.\(Int(monthlySpent)) this month (\(pct)% of budget). Rs.\(Int(remaining)) remaining. Today: Rs.\(Int(todaySpent))."
        if todayIncome > 0 {
            response += " Income today: Rs.\(Int(todayIncome))."
        }

        return .result(dialog: "\(response)")
    }
}

struct SpendSenseShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogTransactionIntent(),
            phrases: [
                "Log a spend in \(.applicationName)",
                "Add expense in \(.applicationName)",
                "Record a purchase in \(.applicationName)",
                "I spent money in \(.applicationName)"
            ],
            shortTitle: "Log a Spend",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: AddIncomeIntent(),
            phrases: [
                "Add income in \(.applicationName)",
                "Log income in \(.applicationName)",
                "I received money in \(.applicationName)"
            ],
            shortTitle: "Add Income",
            systemImageName: "banknote.fill"
        )
        AppShortcut(
            intent: CheckBudgetIntent(),
            phrases: [
                "Check my budget in \(.applicationName)",
                "How much have I spent in \(.applicationName)",
                "Budget status in \(.applicationName)"
            ],
            shortTitle: "Check Budget",
            systemImageName: "chart.pie.fill"
        )
    }
}
