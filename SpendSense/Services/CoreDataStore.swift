//
//  CoreDataStore.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-09.
//

import Foundation
import CoreData

final class CoreDataStore {
    enum StoreError: Error {
        case missingEntity(String)
        case invalidModel(String)
    }

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    //Transactions

    func fetchTransactions() throws -> [TransactionModel] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let objects = try context.fetch(request)
        return objects.compactMap { obj in
            guard
                let id = obj.value(forKey: "id") as? UUID,
                let amount = obj.value(forKey: "amount") as? Double,
                let categoryRaw = obj.value(forKey: "category") as? String,
                let category = SpendingCategory(rawValue: categoryRaw),
                let date = obj.value(forKey: "date") as? Date
            else {
                return nil
            }

            let note = (obj.value(forKey: "note") as? String) ?? ""

            let isImpulse = (obj.value(forKey: "isImpulse") as? Bool) ?? false

            return TransactionModel(id: id, amount: amount, category: category, note: note, date: date, isSimulated: isImpulse)
        }
    }

    func insertTransaction(_ model: TransactionModel) throws {
        let entity = NSEntityDescription.entity(forEntityName: "Transaction", in: context)
        guard let entity else { throw StoreError.missingEntity("Transaction") }

        let obj = NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(model.id, forKey: "id")
        obj.setValue(model.amount, forKey: "amount")
        obj.setValue(model.category.rawValue, forKey: "category")
        obj.setValue(model.note, forKey: "note")
        obj.setValue(model.date, forKey: "date")
        obj.setValue(model.isSimulated, forKey: "isImpulse")

        try saveIfNeeded()
    }

    func deleteAllTransactions() throws {
        try batchDelete(entityName: "Transaction")
    }

    //  Budgets

    func fetchBudgets() throws -> [BudgetModel] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Budget")
        request.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]

        let objects = try context.fetch(request)
        return objects.compactMap { obj in
            let id = (obj.value(forKey: "id") as? UUID) ?? UUID()
            let categoryRaw = obj.value(forKey: "category") as? String
            let category = categoryRaw.flatMap { SpendingCategory(rawValue: $0) }

            // Core Data has monthlyLimit/weeklyLimit/dailyLimit rather than (limit, period)
            let monthly = (obj.value(forKey: "monthlyLimit") as? Double) ?? 0
            let weekly = (obj.value(forKey: "weeklyLimit") as? Double) ?? 0
            let daily = (obj.value(forKey: "dailyLimit") as? Double) ?? 0

            if monthly > 0 { return BudgetModel(id: id, category: category, limit: monthly, period: .monthly) }
            if weekly > 0 { return BudgetModel(id: id, category: category, limit: weekly, period: .weekly) }
            if daily > 0 { return BudgetModel(id: id, category: category, limit: daily, period: .daily) }

            return nil
        }
    }

    func upsertBudget(category: SpendingCategory?, period: BudgetPeriod, limit: Double) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Budget")
        request.fetchLimit = 1

        if let category {
            request.predicate = NSPredicate(format: "category == %@", category.rawValue)
        } else {
            request.predicate = NSPredicate(format: "category == nil")
        }

        let existing = try context.fetch(request).first

        let obj: NSManagedObject
        if let existing {
            obj = existing
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "Budget", in: context)
            guard let entity else { throw StoreError.missingEntity("Budget") }
            obj = NSManagedObject(entity: entity, insertInto: context)
            obj.setValue(UUID(), forKey: "id")
            obj.setValue(category?.rawValue, forKey: "category")
        }

  
        obj.setValue(0.0, forKey: "monthlyLimit")
        obj.setValue(0.0, forKey: "weeklyLimit")
        obj.setValue(0.0, forKey: "dailyLimit")

        switch period {
        case .monthly: obj.setValue(limit, forKey: "monthlyLimit")
        case .weekly: obj.setValue(limit, forKey: "weeklyLimit")
        case .daily: obj.setValue(limit, forKey: "dailyLimit")
        }

        obj.setValue(Date(), forKey: "lastUpdated")

        try saveIfNeeded()
    }

    func deleteAllBudgets() throws {
        try batchDelete(entityName: "Budget")
    }


    func fetchWishlistItems() throws -> [WishlistItemModel] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "WishlistItem")
        request.sortDescriptors = [NSSortDescriptor(key: "addedDate", ascending: false)]

        let objects = try context.fetch(request)
        return objects.compactMap { obj in
            guard
                let id = obj.value(forKey: "id") as? UUID,
                let name = obj.value(forKey: "itemName") as? String,
                let price = obj.value(forKey: "price") as? Double,
                let categoryRaw = obj.value(forKey: "category") as? String,
                let category = SpendingCategory(rawValue: categoryRaw),
                let addedDate = obj.value(forKey: "addedDate") as? Date,
                let delayUntil = obj.value(forKey: "delayUntil") as? Date
            else {
                return nil
            }

            let savingsDays = (obj.value(forKey: "savingsDays") as? Int) ?? 3
            let savedAmount = (obj.value(forKey: "savedAmount") as? Double) ?? 0
            let dailySavingsAmount = (obj.value(forKey: "dailySavingsAmount") as? Double) ?? (savingsDays > 0 ? price / Double(savingsDays) : price)
            let lastDeductionDate = obj.value(forKey: "lastDeductionDate") as? Date

            var model = WishlistItemModel(id: id, name: name, amount: price, category: category, waitDays: savingsDays)
            model.addedDate = addedDate
            model.waitUntil = delayUntil
            model.savedAmount = savedAmount
            model.dailySavingsAmount = dailySavingsAmount
            model.lastDeductionDate = lastDeductionDate
            return model
        }
    }

    func insertWishlistItem(_ model: WishlistItemModel) throws {
        let entity = NSEntityDescription.entity(forEntityName: "WishlistItem", in: context)
        guard let entity else { throw StoreError.missingEntity("WishlistItem") }

        let obj = NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(model.id, forKey: "id")
        obj.setValue(model.name, forKey: "itemName")
        obj.setValue(model.amount, forKey: "price")
        obj.setValue(model.category.rawValue, forKey: "category")
        obj.setValue(model.addedDate, forKey: "addedDate")
        obj.setValue(model.waitUntil, forKey: "delayUntil")
        obj.setValue(model.savingsDays, forKey: "savingsDays")
        obj.setValue(model.savedAmount, forKey: "savedAmount")
        obj.setValue(model.dailySavingsAmount, forKey: "dailySavingsAmount")
        obj.setValue(model.lastDeductionDate, forKey: "lastDeductionDate")
        obj.setValue("active", forKey: "status")

        try saveIfNeeded()
    }

    func updateWishlistItem(_ model: WishlistItemModel) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "WishlistItem")
        request.predicate = NSPredicate(format: "id == %@", model.id as CVarArg)
        request.fetchLimit = 1

        guard let obj = try context.fetch(request).first else { return }
        obj.setValue(model.savedAmount, forKey: "savedAmount")
        obj.setValue(model.lastDeductionDate, forKey: "lastDeductionDate")
        obj.setValue(model.dailySavingsAmount, forKey: "dailySavingsAmount")

        try saveIfNeeded()
    }

    func deleteAllWishlistItems() throws {
        try batchDelete(entityName: "WishlistItem")
    }

    // Profile

    func fetchUserProfile() throws -> UserProfileModel? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1
        guard let obj = try context.fetch(request).first else { return nil }

        let name               = (obj.value(forKey: "name") as? String) ?? ""
        let email              = (obj.value(forKey: "email") as? String) ?? ""
        let monthlyIncome      = (obj.value(forKey: "monthlyIncome") as? Double) ?? 0
        let savingsGoal        = (obj.value(forKey: "savingsGoal") as? Double) ?? 0
        let categoriesRaw      = (obj.value(forKey: "selectedCategories") as? String) ?? ""
        let categories: [SpendingCategory] = categoriesRaw.isEmpty
            ? SpendingCategory.allCases
            : categoriesRaw.split(separator: ",").compactMap { SpendingCategory(rawValue: String($0)) }

        return UserProfileModel(
            name: name,
            email: email,
            monthlyIncome: monthlyIncome,
            savingsGoalPercent: savingsGoal,
            selectedCategories: categories
        )
    }

    func upsertUserProfile(_ profile: UserProfileModel) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1
        let existing = try context.fetch(request).first

        let obj: NSManagedObject
        if let existing {
            obj = existing
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "UserProfile", in: context)
            guard let entity else { throw StoreError.missingEntity("UserProfile") }
            obj = NSManagedObject(entity: entity, insertInto: context)
            obj.setValue(UUID(), forKey: "id")
            obj.setValue(Date(), forKey: "createdAt")
        }

        obj.setValue(profile.name,               forKey: "name")
        obj.setValue(profile.email,              forKey: "email")
        obj.setValue(profile.monthlyIncome,      forKey: "monthlyIncome")
        obj.setValue(profile.savingsGoalPercent, forKey: "savingsGoal")
        obj.setValue(profile.selectedCategories.map(\.rawValue).joined(separator: ","),
                     forKey: "selectedCategories")

        try saveIfNeeded()
    }

    func deleteAllProfiles() throws {
        try batchDelete(entityName: "UserProfile")
    }

    //  Alerts

    func fetchAlerts() throws -> [AlertItemModel] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Alert")
        request.sortDescriptors = [NSSortDescriptor(key: "triggerTime", ascending: false)]

        let objects = try context.fetch(request)
        return objects.compactMap { obj in
            guard
                let id = obj.value(forKey: "id") as? UUID,
                let title = (obj.value(forKey: "type") as? String),
                let message = (obj.value(forKey: "message") as? String),
                let date = (obj.value(forKey: "triggerTime") as? Date)
            else {
                return nil
            }

            // Map stored type string to a known AlertType.
            let alertType: AlertType
            switch title.lowercased() {
            case "budgetwarning", "budget warning": alertType = .budgetWarning
            case "locationalert", "location alert": alertType = .locationAlert
            case "impulsecheck", "impulse check": alertType = .impulseCheck
            case "milestone": alertType = .milestone
            default: alertType = .budgetWarning
            }

            let wasActionTaken = (obj.value(forKey: "wasActionTaken") as? Bool) ?? false
            return AlertItemModel(id: id, title: title, message: message, type: alertType, date: date, isRead: wasActionTaken)
        }
    }

    func insertAlert(_ model: AlertItemModel) throws {
        let entity = NSEntityDescription.entity(forEntityName: "Alert", in: context)
        guard let entity else { throw StoreError.missingEntity("Alert") }

        let obj = NSManagedObject(entity: entity, insertInto: context)
        obj.setValue(model.id, forKey: "id")
        obj.setValue(model.message, forKey: "message")
        obj.setValue(model.date, forKey: "triggerTime")
        obj.setValue(model.title, forKey: "type")
        obj.setValue(model.isRead, forKey: "wasActionTaken")

        try saveIfNeeded()
    }

    func deleteAllAlerts() throws {
        try batchDelete(entityName: "Alert")
    }

    func deleteAllPurchaseAttempts() throws {
        try batchDelete(entityName: "PurchaseAttempt")
    }


    private func saveIfNeeded() throws {
        guard context.hasChanges else { return }
        try context.save()
    }

    private func batchDelete(entityName: String) throws {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        request.resultType = .resultTypeObjectIDs

        let result = try context.execute(request) as? NSBatchDeleteResult
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
        }
    }
}
