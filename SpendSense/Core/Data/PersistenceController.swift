//
//  PersistenceController.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-09.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "SpendSenseModel")
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Core Data failed: \(error), \(error.userInfo)")
            }
        }
    }
}
