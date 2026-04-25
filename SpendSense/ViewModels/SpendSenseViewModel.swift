//
//  SpendSenseViewModel.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-10.
//
import SwiftUI
import Combine
import CoreData
import WidgetKit

class SpendSenseViewModel: ObservableObject {

    //Published State
    @Published var userProfile  = UserProfileModel()
    @Published var transactions : [TransactionModel]  = []
    @Published var budgets      : [BudgetModel]       = []
    @Published var alerts       : [AlertItemModel]    = []
    @Published var wishlist     : [WishlistItemModel] = []

    private let store   : CoreDataStore?
    private let firebase = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext? = nil) {
        self.store = context.map { CoreDataStore(context: $0) }
        loadFromCoreData()

        NotificationCenter.default.publisher(for: .spendSenseInAppAlert)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                guard let self else { return }
                guard
                    let title = note.userInfo?["title"] as? String,
                    let message = note.userInfo?["message"] as? String,
                    let typeRaw = note.userInfo?["type"] as? String
                else { return }

                let type: AlertType
                switch typeRaw {
                case "budgetWarning": type = .budgetWarning
                case "locationAlert": type = .locationAlert
                case "impulseCheck": type = .impulseCheck
                case "milestone": type = .milestone
                default: type = .milestone
                }

                let alert = AlertItemModel(title: title, message: message, type: type)
                self.alerts.insert(alert, at: 0)
                try? self.store?.insertAlert(alert)
            }
            .store(in: &cancellables)
    }

    // Load from CoreData 
    func loadFromCoreData() {
        guard let store else { return }
        do {
            if let profile = try store.fetchUserProfile() {
                userProfile = profile
            }
            transactions = try store.fetchTransactions()
            budgets      = try store.fetchBudgets()
            alerts       = try store.fetchAlerts()
            wishlist     = try store.fetchWishlistItems()

            // Seed default budgets only on very first launch 
            if budgets.isEmpty && !userProfile.name.isEmpty {
                let defaultBudgets = BudgetModel.defaultBudgets(income: userProfile.monthlyIncome)
                for b in defaultBudgets {
                    try store.upsertBudget(category: b.category, period: b.period, limit: b.limit)
                }
                budgets = defaultBudgets
            }
        } catch {
            print("[SpendSenseVM] CoreData load error: \(error)")
        }

        // Process daily savings deductions for wishlist items
        processDailyWishlistSavings()

        // Push current data to the home screen widget
        updateWidgetData()
    }

    // Onboarding save (called from OnboardingView after last step)
    func saveOnboardingProfile(_ profile: UserProfileModel) {
        userProfile = profile

        // Persist to CoreData
        try? store?.upsertUserProfile(profile)

        // Seed default budgets from income
        let defaultBudgets = BudgetModel.defaultBudgets(income: profile.monthlyIncome)
        budgets = defaultBudgets
        for b in defaultBudgets {
            try? store?.upsertBudget(category: b.category, period: b.period, limit: b.limit)
        }

        // Sync non-confidential data to Firestore
        let uid = profile.firebaseUID ?? FirebaseService.shared.currentUID ?? ""
        guard !uid.isEmpty else { return }
        Task {
            try? await firebase.saveProfile(profile, uid: uid)
            for b in defaultBudgets {
                try? await firebase.saveBudget(b, uid: uid)
            }
        }
    }

    // Load from Firestore
    func loadFromFirestore(uid: String) {
        Task { @MainActor in
            do {
                // Always clear local data first so stale records from the
                // previous user never leak into the new session.
                try? store?.deleteAllTransactions()
                try? store?.deleteAllBudgets()
                try? store?.deleteAllWishlistItems()
                try? store?.deleteAllAlerts()
                try? store?.deleteAllPurchaseAttempts()

                transactions = []
                budgets      = []
                wishlist     = []
                alerts       = []

                // Fetch remote data for the new user
                if let profile = try await firebase.fetchProfile(uid: uid) {
                    userProfile = profile
                    userProfile.firebaseUID = uid
                    try? store?.upsertUserProfile(profile)
                }
                let remoteTx = try await firebase.fetchTransactions(uid: uid)
                transactions = remoteTx
                for t in remoteTx { try? store?.insertTransaction(t) }

                let remoteBudgets = try await firebase.fetchBudgets(uid: uid)
                budgets = remoteBudgets
                for b in remoteBudgets {
                    try? store?.upsertBudget(category: b.category, period: b.period, limit: b.limit)
                }

                let remoteWishlist = try await firebase.fetchWishlist(uid: uid)
                wishlist = remoteWishlist
                for w in remoteWishlist { try? store?.insertWishlistItem(w) }

                // Refresh widget with the new user's data
                updateWidgetData()
            } catch {
                print("[SpendSenseVM] Firestore load error: \(error)")
            }
        }
    }


    // Spending Summary Calculated
    var totalSpentThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        return transactions
            .filter { !$0.isSimulated && !$0.isIncome &&
                calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var totalIncomeThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        return transactions
            .filter { !$0.isSimulated && $0.isIncome &&
                calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var totalSpentToday: Double {
        let calendar = Calendar.current
        return transactions
            .filter { !$0.isSimulated && !$0.isIncome &&
                calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var totalIncomeToday: Double {
        let calendar = Calendar.current
        return transactions
            .filter { !$0.isSimulated && $0.isIncome &&
                calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var monthlyBudget: Double {
        budgets.first(where: { $0.category == nil && $0.period == .monthly })?.limit
            ?? userProfile.spendableAmount
    }

    var dailyBudget: Double {
        budgets.first(where: { $0.category == nil && $0.period == .daily })?.limit
            ?? (monthlyBudget / 30)
    }

    var remainingMonthly: Double { monthlyBudget + totalIncomeThisMonth - totalSpentThisMonth }
    var remainingDaily: Double   { dailyBudget + totalIncomeToday - totalSpentToday }

    var monthlyProgress: Double {
        guard monthlyBudget > 0 else { return 0 }
        return min(totalSpentThisMonth / monthlyBudget, 1.0)
    }

    var dailyProgress: Double {
        guard dailyBudget > 0 else { return 0 }
        return min(totalSpentToday / dailyBudget, 1.0)
    }

    var currentRiskLevel: RiskLevel {
        let p = monthlyProgress
        if p < 0.6 { return .low }
        if p < 0.85 { return .moderate }
        return .high
    }

    var unreadAlertsCount: Int {
        alerts.filter { !$0.isRead }.count
    }

    // Category Spending
    func spent(for category: SpendingCategory, period: BudgetPeriod = .monthly) -> Double {
        let calendar = Calendar.current
        let now = Date()
        return transactions
            .filter { t in
                guard !t.isSimulated && !t.isIncome && t.category == category else { return false }
                switch period {
                case .daily:   return calendar.isDateInToday(t.date)
                case .weekly:  return calendar.isDate(t.date, equalTo: now, toGranularity: .weekOfYear)
                case .monthly: return calendar.isDate(t.date, equalTo: now, toGranularity: .month)
                }
            }
            .reduce(0) { $0 + $1.amount }
    }

    func budgetLimit(for category: SpendingCategory) -> Double? {
        budgets.first(where: { $0.category == category })?.limit
    }

    func updateBudgets(monthly: Double, categories: [BudgetModel]) {
        // Update Monthly Budget
        if let idx = budgets.firstIndex(where: { $0.category == nil && $0.period == .monthly }) {
            budgets[idx].limit = monthly
        } else {
            budgets.insert(BudgetModel(category: nil, limit: monthly, period: .monthly), at: 0)
        }
        try? store?.upsertBudget(category: nil, period: .monthly, limit: monthly)

        // Update Category Budgets
        for nb in categories {
            guard let cat = nb.category else { continue }
            if let i = budgets.firstIndex(where: { $0.category == cat && $0.period == .monthly }) {
                budgets[i].limit = nb.limit
            } else {
                budgets.append(BudgetModel(category: cat, limit: nb.limit, period: .monthly))
            }
            try? store?.upsertBudget(category: cat, period: .monthly, limit: nb.limit)
        }
    }

    func setCategoryBudget(category: SpendingCategory, limit: Double) {
        if let idx = budgets.firstIndex(where: { $0.category == category && $0.period == .monthly }) {
            budgets[idx].limit = limit
        } else {
            budgets.append(BudgetModel(category: category, limit: limit, period: .monthly))
        }
        try? store?.upsertBudget(category: category, period: .monthly, limit: limit)
    }

    // Simulate Purchase
    func simulatePurchase(amount: Double, category: SpendingCategory) -> SimulationResult {
        let newTotal = totalSpentThisMonth + amount
        let newProgress = min(newTotal / monthlyBudget, 1.0)
        let newRemaining = remainingMonthly - amount

        let riskAfter: RiskLevel
        if newProgress < 0.6 { riskAfter = .low }
        else if newProgress < 0.85 { riskAfter = .moderate }
        else { riskAfter = .high }

        let categorySpent = spent(for: category)
        let categoryLimit = budgetLimit(for: category)
        var categoryWarning: String? = nil
        if let limit = categoryLimit, categorySpent + amount > limit {
            categoryWarning = "Exceeds \(category.rawValue) budget by \(formatCurrency(categorySpent + amount - limit))"
        }

        return SimulationResult(
            amount: amount,
            category: category,
            remainingAfter: newRemaining,
            progressAfter: newProgress,
            riskLevelAfter: riskAfter,
            categoryWarning: categoryWarning,
            isSafe: newProgress < 0.85
        )
    }

    // Add Transaction
    func addTransaction(amount: Double, category: SpendingCategory, note: String) {
        let t = TransactionModel(amount: amount, category: category, note: note)
        transactions.insert(t, at: 0)
        try? store?.insertTransaction(t)
        // Firebase is synced on logout, not per-transaction
        checkAndGenerateAlerts(for: t)

        // Impulse risk check + notification
        if let ctx = store?.context {
            let risk = ImpulseRiskPredictor.shared.predictRisk(
                amount: amount, category: category.rawValue, context: ctx
            )
            if risk.score >= 0.5 {
                SpendSenseNotificationService.shared.sendImpulseWarning(
                    amount: amount, category: category.rawValue, riskScore: risk.score
                )
            }
            // Start / update the Live Activity
            LiveActivityManager.shared.update(
                remainingBudget: remainingDaily,
                dailyBudget:     dailyBudget,
                riskLevel:       currentRiskLevel.rawValue,
                spentToday:      totalSpentToday,
                userName:        userProfile.name
            )
        }

        // Update widget data
        updateWidgetData(lastCategory: category.rawValue)
    }

    func addIncome(amount: Double, source: String) {
        let t = TransactionModel(
            amount: amount,
            category: .income,
            note: source,
            isIncome: true
        )
        transactions.insert(t, at: 0)
        try? store?.insertTransaction(t)

        updateWidgetData(lastCategory: "Income")
    }

    func addToWishlist(name: String, amount: Double, category: SpendingCategory, savingsDays: Int = 7) {
        let item = WishlistItemModel(name: name, amount: amount, category: category, waitDays: savingsDays)
        wishlist.append(item)
        try? store?.insertWishlistItem(item)
        // Firebase is synced on logout
    }


    func processDailyWishlistSavings() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for i in wishlist.indices {
            var item = wishlist[i]
            // Skip items already fully saved or completed
            guard item.savedAmount < item.amount else { continue }
            guard item.dailySavingsAmount > 0 else { continue }

            // Determine the last date we deducted; default to addedDate
            let lastDate = calendar.startOfDay(for: item.lastDeductionDate ?? item.addedDate)

            // Calculate how many days deserve a deduction
            var cursor = calendar.date(byAdding: .day, value: 1, to: lastDate)!
            var deductionsToMake = 0

            while cursor <= today && item.savedAmount + (Double(deductionsToMake + 1) * item.dailySavingsAmount) <= item.amount {
                deductionsToMake += 1
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
            }

            guard deductionsToMake > 0 else { continue }

            // Record a single consolidated expense transaction for catch-up days
            let totalDeduction = Double(deductionsToMake) * item.dailySavingsAmount
            let cappedDeduction = min(totalDeduction, item.amount - item.savedAmount)

            let txNote = "Wishlist saving: \(item.name)"
            let t = TransactionModel(amount: cappedDeduction, category: item.category, note: txNote)
            transactions.insert(t, at: 0)
            try? store?.insertTransaction(t)

            // Update the wishlist item
            item.savedAmount += cappedDeduction
            item.lastDeductionDate = today
            wishlist[i] = item
            try? store?.updateWishlistItem(item)
            // Firebase is synced on logout
        }
    }

    func updateUserProfile(_ profile: UserProfileModel) {
        userProfile = profile
        try? store?.upsertUserProfile(profile)
        // Firebase is synced on logout
    }

    // MARK: - Sync all Core Data to Firebase then logout

    /// Pushes the entire local Core Data session to Firebase, then clears local storage.
    /// This is the ONLY point where Firebase is written to (except initial account creation).
    func syncToFirebaseThenClear() async {
        let uid = userProfile.firebaseUID ?? firebase.currentUID ?? ""
        guard !uid.isEmpty else {
            clearLocalData()
            userProfile = UserProfileModel() // Reset profile
            return
        }

        do {
            // 1  Wipe old Firestore data so deletions made locally are reflected
            try await firebase.deleteAllUserData(uid: uid)

            // 2  Upload profile
            try await firebase.saveProfile(userProfile, uid: uid)

            // 3  Upload transactions (skip simulated ones)
            for t in transactions where !t.isSimulated {
                try await firebase.saveTransaction(t, uid: uid)
            }

            // 4  Upload budgets
            for b in budgets {
                try await firebase.saveBudget(b, uid: uid)
            }

            // 5  Upload wishlist
            for w in wishlist {
                try await firebase.saveWishlistItem(w, uid: uid)
            }

            // 6  Finally, wipe local data
            clearLocalData()
            userProfile = UserProfileModel() // Reset profile
        } catch {
            print("[SpendSenseVM] Firebase sync error: \(error)")
            // Still clear local data on failure to prevent merging inconsistent states
            clearLocalData()
            userProfile = UserProfileModel() // Reset profile
        }
    }

    /// Wipes all local Core Data entities.
    func clearLocalData() {
        guard let store else { return }
        try? store.deleteAllTransactions()
        try? store.deleteAllBudgets()
        try? store.deleteAllWishlistItems()
        try? store.deleteAllAlerts()
        try? store.deleteAllPurchaseAttempts()
        try? store.deleteAllProfiles()

        transactions = []
        budgets      = []
        wishlist     = []
        alerts       = []
    }

    // Delete all data (local and remote)
    func deleteAllData() {
        let uid = firebase.currentUID ?? ""

        clearLocalData()

        // Firestore wipe
        if !uid.isEmpty {
            Task { try? await firebase.deleteAllUserData(uid: uid) }
        }
    }

    func markAlertRead(_ id: UUID) {
        if let idx = alerts.firstIndex(where: { $0.id == id }) {
            alerts[idx].isRead = true
        }
        try? store?.markAlertRead(id)
    }

    // Helpers
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rs."
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rs.\(Int(value))"
    }

    // Weekly Spending Data (for charts)
    var weeklySpendingData: [DaySpending] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let total = transactions
                .filter { !$0.isSimulated && !$0.isIncome && calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.amount }
            let label = offset == 0 ? "Today" :
                calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1].prefix(3).description
            return DaySpending(label: label, amount: total, date: date)
        }.reversed()
    }

    // Daily Spending Data (24 hourly buckets for today)
    var dailySpendingData: [DaySpending] {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "ha" // e.g. 1PM

        return (0..<24).compactMap { hour in
            guard let bucketStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay) else { return nil }
            guard let bucketEnd = calendar.date(byAdding: .hour, value: 1, to: bucketStart) else { return nil }

            let total = transactions
                .filter { t in
                    guard !t.isSimulated && !t.isIncome else { return false }
                    return t.date >= bucketStart && t.date < bucketEnd
                }
                .reduce(0) { $0 + $1.amount }

            return DaySpending(label: formatter.string(from: bucketStart), amount: total, date: bucketStart)
        }
    }

    // Monthly Spending Data (one bucket per day in the current month)
    var monthlySpendingData: [DaySpending] {
        let calendar = Calendar.current
        let now = Date()

        guard let dayRange = calendar.range(of: .day, in: .month, for: now) else { return [] }
        let comps = calendar.dateComponents([.year, .month], from: now)

        return dayRange.compactMap { day in
            var dc = DateComponents()
            dc.year = comps.year
            dc.month = comps.month
            dc.day = day
            guard let date = calendar.date(from: dc) else { return nil }

            let total = transactions
                .filter { !$0.isSimulated && !$0.isIncome && calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.amount }

            return DaySpending(label: String(day), amount: total, date: date)
        }
    }

    var categoryBreakdown: [CategorySpending] {
        SpendingCategory.allCases.compactMap { cat in
            let total = spent(for: cat)
            guard total > 0 else { return nil }
            return CategorySpending(category: cat, amount: total)
        }.sorted { $0.amount > $1.amount }
    }

    // Private
    private func checkAndGenerateAlerts(for transaction: TransactionModel) {
        if monthlyProgress > 0.8 {
            let alert = AlertItemModel(
                title: "Budget Warning",
                message: "You've used \(Int(monthlyProgress * 100))% of your monthly budget.",
                type: .budgetWarning
            )
            alerts.insert(alert, at: 0)

            if let store {
                try? store.insertAlert(alert)
            }

            // Also fire a push notification
            SpendSenseNotificationService.shared.sendBudgetWarning(percentUsed: Int(monthlyProgress * 100))
        }
    }

    // Push latest spending data to the widget.
    func updateWidgetData(lastCategory: String = "--") {
        WidgetDataStore.save(
            todaySpent:     totalSpentToday,
            monthlySpent:   totalSpentThisMonth,
            monthlyBudget:  monthlyBudget,
            dailyBudget:    dailyBudget,
            remainingDaily: remainingDaily,
            riskLevel:      currentRiskLevel.rawValue,
            lastCategory:   lastCategory,
            userName:       userProfile.name
        )
        WidgetCenter.shared.reloadAllTimelines()
    }
}

//  Supporting Types
struct SimulationResult {
    var amount: Double
    var category: SpendingCategory
    var remainingAfter: Double
    var progressAfter: Double
    var riskLevelAfter: RiskLevel
    var categoryWarning: String?
    var isSafe: Bool
}

struct DaySpending: Identifiable {
    let id = UUID()
    var label: String
    var amount: Double
    var date: Date
}

struct CategorySpending: Identifiable {
    let id = UUID()
    var category: SpendingCategory
    var amount: Double
}

// Mock Data (for Previews only) (for Previews only)
extension TransactionModel {
    static func mockData() -> [TransactionModel] {
        let cal = Calendar.current
        let now = Date()
        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: now) ?? now
        }
        return [
            TransactionModel(amount: 1200, category: .food,          note: "Lunch at cafe",          date: now),
            TransactionModel(amount: 500,  category: .transport,     note: "Uber",                   date: now),
            TransactionModel(amount: 3500, category: .shopping,      note: "New sneakers",            date: daysAgo(1)),
            TransactionModel(amount: 800,  category: .food,          note: "Grocery run",             date: daysAgo(1)),
            TransactionModel(amount: 1500, category: .entertainment, note: "Movie + dinner",          date: daysAgo(2)),
            TransactionModel(amount: 250,  category: .transport,     note: "Bus pass",                date: daysAgo(2)),
            TransactionModel(amount: 2200, category: .health,        note: "Pharmacy",                date: daysAgo(3)),
            TransactionModel(amount: 4500, category: .utilities,     note: "Internet bill",           date: daysAgo(4)),
            TransactionModel(amount: 900,  category: .food,          note: "Coffee & snacks",         date: daysAgo(4)),
            TransactionModel(amount: 6000, category: .shopping,      note: "Clothing haul",           date: daysAgo(5)),
            TransactionModel(amount: 1800, category: .education,     note: "Online course",           date: daysAgo(6)),
            TransactionModel(amount: 350,  category: .food,          note: "Street food",             date: daysAgo(6)),
        ]
    }
}

extension BudgetModel {
    // Sensible default budgets seeded from the user's monthly income.
    static func defaultBudgets(income: Double) -> [BudgetModel] {
        let monthly = income > 0 ? income * 0.8 : 120_000   // 80% of income as spendable
        let daily   = monthly / 30
        return [
            BudgetModel(category: nil,            limit: monthly,          period: .monthly),
            BudgetModel(category: nil,            limit: daily,            period: .daily),
            BudgetModel(category: .food,          limit: monthly * 0.20,   period: .monthly),
            BudgetModel(category: .shopping,      limit: monthly * 0.15,   period: .monthly),
            BudgetModel(category: .entertainment, limit: monthly * 0.10,   period: .monthly),
            BudgetModel(category: .transport,     limit: monthly * 0.08,   period: .monthly),
        ]
    }

    static func mockData() -> [BudgetModel] { defaultBudgets(income: 150_000) }
}

extension AlertItemModel {
    static func mockData() -> [AlertItemModel] {
        [
            AlertItemModel(title: "Budget Alert",
                      message: "You've spent 72% of your monthly budget. Slow down to stay on track.",
                      type: .budgetWarning, isRead: false),
            AlertItemModel(title: "Impulse Check",
                      message: "You've made 3 shopping purchases today. Pause and review your wishlist.",
                      type: .impulseCheck, isRead: false),
            AlertItemModel(title: "Location Alert",
                      message: "You're near One Galle Face Mall — a high-spending zone. Current budget: Rs. 4,200 remaining today.",
                      type: .locationAlert, isRead: true),
            AlertItemModel(title: "Savings Milestone!",
                      message: "You're on track to hit your 20% savings goal this month. Keep it up!",
                      type: .milestone, isRead: true),
        ]
    }
}

extension WishlistItemModel {
    static func mockData() -> [WishlistItemModel] {
        [
            WishlistItemModel(name: "Wireless Earbuds", amount: 15000, category: .shopping, waitDays: 7),
            WishlistItemModel(name: "Gym Membership",   amount: 5000,  category: .health,   waitDays: 14),
        ]
    }
}
