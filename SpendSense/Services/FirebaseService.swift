//
//  FirebaseService.swift
//  SpendSense
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseService {

    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private init() {}

    func signUp(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    var currentUID: String? { Auth.auth().currentUser?.uid }

    func saveProfile(_ profile: UserProfileModel, uid: String) async throws {
        let data: [String: Any] = [
            "name":               profile.name,
            "monthlyIncome":      profile.monthlyIncome,
            "savingsGoalPercent": profile.savingsGoalPercent,
            "selectedCategories": profile.selectedCategories.map(\.rawValue),
            "updatedAt":          FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(uid).setData(data, merge: true)
    }

    func fetchProfile(uid: String) async throws -> UserProfileModel? {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let d = doc.data() else { return nil }

        let name               = d["name"] as? String ?? ""
        let email              = Auth.auth().currentUser?.email ?? ""
        let monthlyIncome      = d["monthlyIncome"] as? Double ?? 0
        let savingsGoalPercent = d["savingsGoalPercent"] as? Double ?? 20
        let categoriesRaw      = d["selectedCategories"] as? [String] ?? []
        let categories         = categoriesRaw.compactMap { SpendingCategory(rawValue: $0) }

        return UserProfileModel(
            name: name, email: email, monthlyIncome: monthlyIncome,
            savingsGoalPercent: savingsGoalPercent,
            selectedCategories: categories.isEmpty ? SpendingCategory.allCases.filter { $0.isExpenseCategory } : categories,
            firebaseUID: uid
        )
    }

    func saveTransaction(_ t: TransactionModel, uid: String) async throws {
        let data: [String: Any] = [
            "id":        t.id.uuidString,
            "amount":    t.amount,
            "category":  t.category.rawValue,
            "note":      t.note,
            "date":      Timestamp(date: t.date),
            "isImpulse": t.isSimulated,
            "isIncome":  t.isIncome
        ]
        try await db.collection("users").document(uid)
            .collection("transactions").document(t.id.uuidString).setData(data)
    }

    func fetchTransactions(uid: String) async throws -> [TransactionModel] {
        let snap = try await db.collection("users").document(uid)
            .collection("transactions")
            .order(by: "date", descending: true)
            .getDocuments()

        return snap.documents.compactMap { doc -> TransactionModel? in
            let d = doc.data()
            guard
                let idStr    = d["id"] as? String,
                let id       = UUID(uuidString: idStr),
                let amount   = d["amount"] as? Double,
                let catRaw   = d["category"] as? String,
                let category = SpendingCategory(rawValue: catRaw),
                let ts       = d["date"] as? Timestamp
            else { return nil }
            let note      = d["note"] as? String ?? ""
            let isImpulse = d["isImpulse"] as? Bool ?? false
            let isIncome  = d["isIncome"]  as? Bool ?? (category == .income)
            return TransactionModel(id: id, amount: amount, category: category,
                                    note: note, date: ts.dateValue(),
                                    isSimulated: isImpulse, isIncome: isIncome)
        }
    }

    func deleteTransaction(id: UUID, uid: String) async throws {
        try await db.collection("users").document(uid)
            .collection("transactions").document(id.uuidString).delete()
    }

    func saveBudget(_ b: BudgetModel, uid: String) async throws {
        let data: [String: Any] = [
            "id":       b.id.uuidString,
            "category": b.category?.rawValue ?? "",
            "limit":    b.limit,
            "period":   b.period.rawValue
        ]
        try await db.collection("users").document(uid)
            .collection("budgets").document(b.id.uuidString).setData(data)
    }

    func fetchBudgets(uid: String) async throws -> [BudgetModel] {
        let snap = try await db.collection("users").document(uid)
            .collection("budgets").getDocuments()
        return snap.documents.compactMap { doc -> BudgetModel? in
            let d = doc.data()
            guard
                let idStr  = d["id"] as? String,
                let id     = UUID(uuidString: idStr),
                let limit  = d["limit"] as? Double,
                let perRaw = d["period"] as? String,
                let period = BudgetPeriod(rawValue: perRaw)
            else { return nil }
            let catRaw = d["category"] as? String ?? ""
            let category = catRaw.isEmpty ? nil : SpendingCategory(rawValue: catRaw)
            return BudgetModel(id: id, category: category, limit: limit, period: period)
        }
    }

    func saveWishlistItem(_ item: WishlistItemModel, uid: String) async throws {
        let data: [String: Any] = [
            "id":                item.id.uuidString,
            "name":              item.name,
            "amount":            item.amount,
            "category":          item.category.rawValue,
            "addedDate":         Timestamp(date: item.addedDate),
            "waitUntil":         Timestamp(date: item.waitUntil),
            "savingsDays":       item.savingsDays,
            "savedAmount":       item.savedAmount,
            "dailySavingsAmount": item.dailySavingsAmount
        ]
        try await db.collection("users").document(uid)
            .collection("wishlist").document(item.id.uuidString).setData(data)
    }

    func fetchWishlist(uid: String) async throws -> [WishlistItemModel] {
        let snap = try await db.collection("users").document(uid)
            .collection("wishlist").getDocuments()
        return snap.documents.compactMap { doc -> WishlistItemModel? in
            let d = doc.data()
            guard
                let idStr   = d["id"] as? String,
                let id      = UUID(uuidString: idStr),
                let name    = d["name"] as? String,
                let amount  = d["amount"] as? Double,
                let catRaw  = d["category"] as? String,
                let cat     = SpendingCategory(rawValue: catRaw),
                let addedTs = d["addedDate"] as? Timestamp,
                let waitTs  = d["waitUntil"] as? Timestamp
            else { return nil }

            let savingsDays        = (d["savingsDays"] as? Int) ?? 3
            let savedAmount        = (d["savedAmount"] as? Double) ?? 0
            let dailySavingsAmount = (d["dailySavingsAmount"] as? Double) ?? (savingsDays > 0 ? amount / Double(savingsDays) : amount)

            var item = WishlistItemModel(id: id, name: name, amount: amount, category: cat, waitDays: savingsDays)
            item.addedDate          = addedTs.dateValue()
            item.waitUntil          = waitTs.dateValue()
            item.savedAmount        = savedAmount
            item.dailySavingsAmount = dailySavingsAmount
            return item
        }
    }

    func deleteAllUserData(uid: String) async throws {
        async let _ = deleteCollection("transactions", uid: uid)
        async let _ = deleteCollection("budgets",      uid: uid)
        async let _ = deleteCollection("wishlist",     uid: uid)
        try await db.collection("users").document(uid).delete()
    }

    private func deleteCollection(_ name: String, uid: String) async throws {
        let snap = try await db.collection("users").document(uid).collection(name).getDocuments()
        for doc in snap.documents { try await doc.reference.delete() }
    }
}
