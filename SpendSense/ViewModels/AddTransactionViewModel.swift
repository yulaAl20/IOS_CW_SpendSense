//
//  AddTransactionViewModel.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-09.
//
import SwiftUI
import Combine

class AddTransactionViewModel: ObservableObject {
    @Published var amount: String = ""
    @Published var selectedCategory: SpendingCategory = .food
    @Published var note: String = ""
    @Published var mode: Mode = .spend         
    @Published var simulationResult: SimulationResult? = nil
    @Published var showSimulation: Bool = false

    // Wishlist
    @Published var wishlistName: String = ""
    @Published var showWishlistAdd: Bool = false
    @Published var savingsDays: Int = 7  

    enum Mode: String, CaseIterable {
        case spend    = "Spend"
        case simulate = "Simulate"
        case wishlist = "Wishlist"
    }

    var amountDouble: Double {
        Double(amount.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var isValid: Bool {
        amountDouble > 0
    }

    func runSimulation(using vm: SpendSenseViewModel) {
        guard isValid else { return }
        simulationResult = vm.simulatePurchase(amount: amountDouble, category: selectedCategory)
        withAnimation { showSimulation = true }
    }

    func confirm(using vm: SpendSenseViewModel) {
        guard isValid else { return }
        vm.addTransaction(amount: amountDouble, category: selectedCategory, note: note)
        reset()
    }

    func addToWishlist(using vm: SpendSenseViewModel) {
        guard isValid, !wishlistName.isEmpty else { return }
        vm.addToWishlist(name: wishlistName, amount: amountDouble, category: selectedCategory, savingsDays: savingsDays)
        reset()
    }

    func reset() {
        amount = ""
        note = ""
        wishlistName = ""
        savingsDays = 7
        simulationResult = nil
        showSimulation = false
        showWishlistAdd = false
    }

    var dailySavingsPreview: Double {
        guard amountDouble > 0, savingsDays > 0 else { return 0 }
        return amountDouble / Double(savingsDays)
    }
}
