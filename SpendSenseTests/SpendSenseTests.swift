//
//  SpendSenseTests.swift
//  SpendSense
//
//  Created by COBSCCOMP242P-066 on 2026-04-25.
//

import XCTest
import CoreData
@testable import SpendSense

final class SpendSenseViewModelTests: XCTestCase {

    //Setup

    // In-memory Core Data stack so tests never touch the real persistent store.
    private var persistenceController: PersistenceController!
    private var sut: SpendSenseViewModel!          // system under test

    override func setUpWithError() throws {
        try super.setUpWithError()
        persistenceController = PersistenceController(inMemory: true)
        sut = SpendSenseViewModel(context: persistenceController.container.viewContext)

        // Seed a known profile so every test starts from a clean, deterministic state.
        var profile = UserProfileModel()
        profile.monthlyIncome      = 150_000
        profile.savingsGoalPercent = 20          // save 20 % → spend 80 % = 120,000/month
        profile.name               = "Tester"
        sut.saveOnboardingProfile(profile)
    }

    override func tearDownWithError() throws {
        sut  = nil
        persistenceController = nil
        try super.tearDownWithError()
    }

    // Monthly budget derivation

    // Spendable amount = income × (1 − savingsGoalPercent / 100).
    func testMonthlyBudgetEqualsSpendableAmount() {
        // 150,000 × 0.80 = 120,000
        XCTAssertEqual(sut.monthlyBudget, 120_000, accuracy: 0.01,
                       "Monthly budget should equal 80 % of income after 20 % savings goal.")
    }

    // Daily budget is automatically derived as monthlyBudget / 30.
    func testDailyBudgetIsDerivedFromMonthlyBudget() {
        let expectedDaily = 120_000.0 / 30.0   // 4,000
        XCTAssertEqual(sut.dailyBudget, expectedDaily, accuracy: 0.01,
                       "Daily budget should be monthly budget divided by 30.")
    }

    // Transaction recording

    // Adding a transaction increases totalSpentToday by the transaction amount.
    func testAddTransactionIncreasesTotalSpentToday() {
        let before = sut.totalSpentToday
        sut.addTransaction(amount: 500, category: .food, note: "Lunch")
        XCTAssertEqual(sut.totalSpentToday, before + 500, accuracy: 0.01,
                       "totalSpentToday should increase by the transaction amount.")
    }

    // Adding a transaction reduces remainingDaily by the same amount.
    func testAddTransactionReducesRemainingDaily() {
        let before = sut.remainingDaily
        sut.addTransaction(amount: 1_000, category: .transport, note: "Uber")
        XCTAssertEqual(sut.remainingDaily, before - 1_000, accuracy: 0.01,
                       "remainingDaily should decrease by the transaction amount.")
    }

    // Simulated transactions must NOT be counted in real spending totals.
    func testSimulatedTransactionsDoNotAffectTotals() {
        let beforeMonthly = sut.totalSpentThisMonth
        let beforeDaily   = sut.totalSpentToday
        // Simulate internally (simulatePurchase does not persist a transaction)
        _ = sut.simulatePurchase(amount: 10_000, category: .shopping)
        XCTAssertEqual(sut.totalSpentThisMonth, beforeMonthly, accuracy: 0.01,
                       "A simulated purchase must not change totalSpentThisMonth.")
        XCTAssertEqual(sut.totalSpentToday, beforeDaily, accuracy: 0.01,
                       "A simulated purchase must not change totalSpentToday.")
    }

    // Risk level classification

    // Spending below 60 % of the monthly budget → Low risk.
    func testRiskLevelLowWhenUnder60Percent() {
        // Spend 50 % of monthly budget (60,000 out of 120,000)
        sut.addTransaction(amount: 60_000, category: .shopping, note: "Test")
        XCTAssertEqual(sut.currentRiskLevel, .low,
                       "Risk should be Low when < 60 % of budget is used.")
    }

    // Spending between 60 % and 85 % → Moderate risk.
    func testRiskLevelModerateWhenBetween60And85Percent() {
        // Spend 70 % = 84,000
        sut.addTransaction(amount: 84_000, category: .shopping, note: "Test")
        XCTAssertEqual(sut.currentRiskLevel, .moderate,
                       "Risk should be Moderate when 60–85 % of budget is used.")
    }

    // Spending above 85 % → High risk.
    func testRiskLevelHighWhenOver85Percent() {
        // Spend 90 % = 108,000
        sut.addTransaction(amount: 108_000, category: .shopping, note: "Test")
        XCTAssertEqual(sut.currentRiskLevel, .high,
                       "Risk should be High when > 85 % of budget is used.")
    }

    // Purchase simulation

    // simulatePurchase should return isSafe = true when the spend stays below 85 %.
    func testSimulationIsSafeWhenUnder85Percent() {
        let result = sut.simulatePurchase(amount: 1_000, category: .food)
        XCTAssertTrue(result.isSafe,
                      "Simulation should be safe when remaining budget is ample.")
    }

    // simulatePurchase should return isSafe = false when the spend would exceed 85 %.
    func testSimulationIsUnsafeWhenOver85Percent() {
        // Pre-spend 100,000 (83 %) then simulate 3,000 more → total = 103,000 / 120,000 = 85.8 %
        sut.addTransaction(amount: 100_000, category: .shopping, note: "Pre-spend")
        let result = sut.simulatePurchase(amount: 3_000, category: .shopping)
        XCTAssertFalse(result.isSafe,
                       "Simulation should be unsafe when it pushes spending over 85 %.")
    }

    // simulatePurchase remainingAfter must equal current remaining minus simulated amount.
    func testSimulationRemainingAfterIsCorrect() {
        let currentRemaining = sut.remainingMonthly
        let simAmount        = 5_000.0
        let result           = sut.simulatePurchase(amount: simAmount, category: .food)
        XCTAssertEqual(result.remainingAfter, currentRemaining - simAmount, accuracy: 0.01,
                       "remainingAfter in simulation result should be remainingMonthly minus the simulated amount.")
    }

    // simulatePurchase should include a category warning when the spend exceeds the category limit.
    func testSimulationGeneratesCategoryWarningWhenLimitExceeded() {
        // Food category limit is 20 % of monthly budget = 24,000
        let result = sut.simulatePurchase(amount: 30_000, category: .food)
        XCTAssertNotNil(result.categoryWarning,
                        "A category warning should be generated when the spend exceeds the category limit.")
    }

    // monthlyProgress clamping

    // monthlyProgress must never exceed 1.0 even when spending is over budget.
    func testMonthlyProgressClampedAtOne() {
        // Spend 200 % of budget
        sut.addTransaction(amount: 240_000, category: .shopping, note: "Over budget")
        XCTAssertLessThanOrEqual(sut.monthlyProgress, 1.0,
                                 "monthlyProgress should be clamped to 1.0 even when over budget.")
    }
}

//  BudgetModel Tests

final class BudgetModelTests: XCTestCase {

    // defaultBudgets should seed one monthly global budget equal to 80 % of income.
    func testDefaultBudgetsMonthlyGlobalLimit() {
        let budgets = BudgetModel.defaultBudgets(income: 150_000)
        let monthly = budgets.first { $0.category == nil && $0.period == .monthly }
        XCTAssertNotNil(monthly, "A global monthly budget should be seeded.")
        XCTAssertEqual(monthly?.limit ?? 0, 120_000, accuracy: 0.01,
                       "Monthly global limit should be 80 % of income.")
    }

    // defaultBudgets should seed a daily budget equal to monthlyLimit / 30.
    func testDefaultBudgetsDailyLimit() {
        let budgets = BudgetModel.defaultBudgets(income: 150_000)
        let daily   = budgets.first { $0.category == nil && $0.period == .daily }
        XCTAssertNotNil(daily, "A global daily budget should be seeded.")
        XCTAssertEqual(daily?.limit ?? 0, 120_000.0 / 30.0, accuracy: 0.01,
                       "Daily global limit should be monthly limit divided by 30.")
    }

    // defaultBudgets should always include food, shopping, entertainment, and transport category limits.
    func testDefaultBudgetsContainExpectedCategories() {
        let budgets    = BudgetModel.defaultBudgets(income: 100_000)
        let categories = budgets.compactMap { $0.category }
        XCTAssertTrue(categories.contains(.food),          "Food category budget should be seeded.")
        XCTAssertTrue(categories.contains(.shopping),      "Shopping category budget should be seeded.")
        XCTAssertTrue(categories.contains(.entertainment), "Entertainment category budget should be seeded.")
        XCTAssertTrue(categories.contains(.transport),     "Transport category budget should be seeded.")
    }

    //When income is 0, defaultBudgets should fall back to a non-zero default (120,000).
    func testDefaultBudgetsFallbackWhenIncomeIsZero() {
        let budgets = BudgetModel.defaultBudgets(income: 0)
        let monthly = budgets.first { $0.category == nil && $0.period == .monthly }
        XCTAssertEqual(monthly?.limit ?? 0, 120_000, accuracy: 0.01,
                       "Monthly budget should fall back to 120,000 when income is 0.")
    }
}

// WishlistItemModel Tests

final class WishlistItemModelTests: XCTestCase {

    //savingsProgress should be 0.0 for a brand-new item with no savings.
    func testInitialSavingsProgressIsZero() {
        let item = WishlistItemModel(name: "Earbuds", amount: 15_000, category: .shopping, waitDays: 7)
        XCTAssertEqual(item.savingsProgress, 0.0, accuracy: 0.001,
                       "A new wishlist item should have 0 % savings progress.")
    }

    // savingsProgress should be 1.0 when savedAmount equals the target amount.
    func testSavingsProgressIsOneWhenFullySaved() {
        var item = WishlistItemModel(name: "Earbuds", amount: 15_000, category: .shopping, waitDays: 7)
        item.savedAmount = 15_000
        XCTAssertEqual(item.savingsProgress, 1.0, accuracy: 0.001,
                       "savingsProgress should be 1.0 when the item is fully saved.")
    }

    // savingsProgress should clamp at 1.0 even if savedAmount exceeds the target.
    func testSavingsProgressClampedAtOne() {
        var item = WishlistItemModel(name: "Earbuds", amount: 15_000, category: .shopping, waitDays: 7)
        item.savedAmount = 20_000      // more than the target
        XCTAssertEqual(item.savingsProgress, 1.0, accuracy: 0.001,
                       "savingsProgress must be clamped to 1.0 even when savedAmount exceeds amount.")
    }

    // dailySavingsAmount should equal amount / savingsDays when waitDays > 0.
    func testDailySavingsAmountCalculation() {
        let item = WishlistItemModel(name: "Gym", amount: 5_000, category: .health, waitDays: 10)
        XCTAssertEqual(item.dailySavingsAmount, 500, accuracy: 0.01,
                       "dailySavingsAmount should be amount divided by savingsDays.")
    }

    // isReadyToPurchase should be true when savedAmount reaches the target.
    func testIsReadyToPurchaseWhenFullySaved() {
        var item = WishlistItemModel(name: "Gym", amount: 5_000, category: .health, waitDays: 30)
        item.savedAmount = 5_000
        XCTAssertTrue(item.isReadyToPurchase,
                      "isReadyToPurchase should be true when savedAmount >= amount.")
    }

    // amountRemaining should equal amount minus savedAmount.
    func testAmountRemainingCalculation() {
        var item = WishlistItemModel(name: "Gym", amount: 5_000, category: .health, waitDays: 10)
        item.savedAmount = 2_000
        XCTAssertEqual(item.amountRemaining, 3_000, accuracy: 0.01,
                       "amountRemaining should be amount minus savedAmount.")
    }
}



// UserProfileModel Tests

final class UserProfileModelTests: XCTestCase {

    // savingsGoalAmount should be income × savingsGoalPercent / 100.
    func testSavingsGoalAmount() {
        let profile = UserProfileModel(monthlyIncome: 100_000, savingsGoalPercent: 25)
        XCTAssertEqual(profile.savingsGoalAmount, 25_000, accuracy: 0.01,
                       "savingsGoalAmount should be 25 % of 100,000 = 25,000.")
    }

    // spendableAmount should be income minus savingsGoalAmount.
    func testSpendableAmount() {
        let profile = UserProfileModel(monthlyIncome: 100_000, savingsGoalPercent: 25)
        XCTAssertEqual(profile.spendableAmount, 75_000, accuracy: 0.01,
                       "spendableAmount should be income minus savings = 75,000.")
    }
}
