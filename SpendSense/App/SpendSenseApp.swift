//
//  SpendSenseApp.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-03-30.
//
import SwiftUI
import FirebaseCore
import WidgetKit

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    // Set up local notifications
    SpendSenseNotificationService.shared.requestAuthorization()
    SpendSenseNotificationService.shared.registerNotificationCategories()

    return true
  }
}

@main
struct SpendSenseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    let persistenceController: PersistenceController
    @StateObject private var appState = AppStateViewModel()
    @StateObject private var vm: SpendSenseViewModel

    init() {
        let persistenceController = PersistenceController.shared
        self.persistenceController = persistenceController

        let viewContext = persistenceController.container.viewContext
        _vm = StateObject(wrappedValue: SpendSenseViewModel(context: viewContext))

        #if DEBUG
        CoreDataSmokeTest.run(using: persistenceController.container)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(vm)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
