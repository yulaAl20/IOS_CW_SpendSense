//
//  CoreDataSmokeTest.swift
//  SpendSense
//

import CoreData

struct CoreDataSmokeTest {
    static func run(using container: NSPersistentContainer) {
        // Minimal smoke test: ensure the persistent container is loaded.
        _ = container.viewContext
    }
}
