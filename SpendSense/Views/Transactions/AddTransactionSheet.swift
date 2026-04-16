//
//  AddTransactionSheet.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-15.
import SwiftUI

struct AddTransactionSheet: View {
    @EnvironmentObject var vm: SpendSenseViewModel
    @StateObject private var addVM = AddTransactionViewModel()
    @Environment(\.dismiss) var dismiss
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.ssBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        HStack(spacing: 0) {
                            ForEach(AddTransactionViewModel.Mode.allCases, id: \.self) { mode in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        addVM.mode = mode
                                        addVM.showSimulation = false
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Text(mode.rawValue)
                                            .font(SSFont.body(14, weight: addVM.mode == mode ? .bold : .regular))
                                            .foregroundColor(addVM.mode == mode ? modeAccentColor(mode) : .ssTextSecondary)
                                        Rectangle()
                                            .fill(addVM.mode == mode ? modeAccentColor(mode) : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        VStack(spacing: 8) {
                            Text(addVM.mode == .income ? "Income Amount" : "Amount")
                                .font(SSFont.body(12))
                                .foregroundColor(.ssTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)

                            HStack(alignment: .center, spacing: 8) {
                                Text("Rs.")
                                    .font(SSFont.mono(28, weight: .bold))
                                    .foregroundColor(addVM.mode == .income ? .ssSuccess : .ssAccent)

                                TextField("0", text: $addVM.amount)
                                    .font(SSFont.mono(40, weight: .bold))
                                    .foregroundColor(.ssTextPrimary)
                                    .keyboardType(.decimalPad)
                                    .focused($amountFocused)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 24)

                            Divider()
                                .background(amountFocused
                                    ? (addVM.mode == .income ? Color.green.opacity(0.6) : Color.ssAccent.opacity(0.6))
                                    : Color.ssBorder)
                                .padding(.horizontal, 24)
                                .animation(.easeInOut, value: amountFocused)
                        }

                        if addVM.mode == .income {
                            incomeSection
                        } else {
                            categorySection

                            if addVM.mode != .wishlist {
                                noteField
                            }

                            if addVM.mode == .wishlist {
                                wishlistSection
                            }

                            if addVM.showSimulation, let result = addVM.simulationResult {
                                SimulationResultCard(result: result, vm: vm)
                                    .padding(.horizontal, 24)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }

                        actionButton
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle(addVM.mode == .income ? "Record Income" : "Record Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.ssTextSecondary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { amountFocused = true }
    }

    private func modeAccentColor(_ mode: AddTransactionViewModel.Mode) -> Color {
        mode == .income ? Color(hex: "#22C55E") : .ssAccent
    }

    @ViewBuilder
    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Source (optional)")
                .font(SSFont.body(12))
                .foregroundColor(.ssTextSecondary)

            TextField("e.g. Freelance, Salary Bonus, Gift", text: $addVM.incomeSource)
                .font(SSFont.body(15))
                .foregroundColor(.ssTextPrimary)
                .padding(14)
                .background(Color.ssSurfaceElevated)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#22C55E").opacity(0.3), lineWidth: 1))
        }
        .padding(.horizontal, 24)

        if addVM.amountDouble > 0 {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#22C55E").opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#22C55E"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Income: Rs.\(Int(addVM.amountDouble))")
                        .font(SSFont.body(14, weight: .semibold))
                        .foregroundColor(.ssTextPrimary)
                    Text("Will be added to your tracked income")
                        .font(SSFont.body(12))
                        .foregroundColor(.ssTextSecondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color(hex: "#22C55E").opacity(0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#22C55E").opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(SSFont.body(12))
                .foregroundColor(.ssTextSecondary)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Spacer().frame(width: 14)
                    ForEach(SpendingCategory.allCases.filter { $0.isExpenseCategory }) { cat in
                        CategoryChip(
                            category: cat,
                            isSelected: addVM.selectedCategory == cat
                        ) { addVM.selectedCategory = cat }
                    }
                    Spacer().frame(width: 14)
                }
            }
        }
    }

    @ViewBuilder
    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note (optional)")
                .font(SSFont.body(12))
                .foregroundColor(.ssTextSecondary)

            TextField("e.g. Lunch with friends", text: $addVM.note)
                .font(SSFont.body(15))
                .foregroundColor(.ssTextPrimary)
                .padding(14)
                .background(Color.ssSurfaceElevated)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ssBorder, lineWidth: 1))
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var wishlistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Item Name")
                .font(SSFont.body(12))
                .foregroundColor(.ssTextSecondary)
            TextField("e.g. New iPhone", text: $addVM.wishlistName)
                .font(SSFont.body(15))
                .foregroundColor(.ssTextPrimary)
                .padding(14)
                .background(Color.ssSurfaceElevated)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ssBorder, lineWidth: 1))

            VStack(alignment: .leading, spacing: 8) {
                Text("Save over")
                    .font(SSFont.body(12))
                    .foregroundColor(.ssTextSecondary)

                HStack(spacing: 12) {
                    ForEach([3, 7, 14, 30], id: \.self) { days in
                        Button(action: { addVM.savingsDays = days }) {
                            Text("\(days)d")
                                .font(SSFont.body(14, weight: addVM.savingsDays == days ? .bold : .regular))
                                .foregroundColor(addVM.savingsDays == days ? .ssBackground : .ssTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(addVM.savingsDays == days
                                            ? Color.ssViolet.cornerRadius(10)
                                            : Color.ssSurfaceElevated.cornerRadius(10))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(addVM.savingsDays == days ? Color.ssViolet : Color.ssBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Stepper("Custom: \(addVM.savingsDays) days", value: $addVM.savingsDays, in: 1...365)
                    .font(SSFont.body(13))
                    .foregroundColor(.ssTextSecondary)
                    .padding(.horizontal, 4)
            }

            if addVM.amountDouble > 0 {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 13)).foregroundColor(.ssAccent)
                        Text("Savings Plan")
                            .font(SSFont.body(13, weight: .semibold)).foregroundColor(.ssTextPrimary)
                        Spacer()
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily savings").font(SSFont.body(11)).foregroundColor(.ssTextTertiary)
                            Text("Rs. \(Int(addVM.dailySavingsPreview))")
                                .font(SSFont.mono(16, weight: .bold)).foregroundColor(.ssAccent)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Target date").font(SSFont.body(11)).foregroundColor(.ssTextTertiary)
                            Text(Calendar.current.date(byAdding: .day, value: addVM.savingsDays, to: Date())?
                                .formatted(.dateTime.day().month(.abbreviated)) ?? "--")
                                .font(SSFont.mono(13, weight: .semibold)).foregroundColor(.ssTextPrimary)
                        }
                    }
                }
                .padding(12)
                .background(Color.ssAccent.opacity(0.08))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ssAccent.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var actionButton: some View {
        VStack(spacing: 12) {
            switch addVM.mode {
            case .income:
                Button(action: { addVM.confirmIncome(using: vm); dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Income")
                    }
                    .font(SSFont.display(16, weight: .semibold))
                    .foregroundColor(addVM.isIncomeValid ? .ssBackground : .ssTextTertiary)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(addVM.isIncomeValid
                                ? AnyView(LinearGradient(colors: [Color(hex: "#22C55E"), Color(hex: "#16A34A")],
                                                         startPoint: .leading, endPoint: .trailing).cornerRadius(14))
                                : AnyView(Color.ssBorder.cornerRadius(14)))
                }
                .disabled(!addVM.isIncomeValid)

            case .simulate where !addVM.showSimulation:
                Button(action: { addVM.runSimulation(using: vm) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text("Run Simulation")
                    }
                    .font(SSFont.display(16, weight: .semibold))
                    .foregroundColor(addVM.isValid ? .ssBackground : .ssTextTertiary)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(addVM.isValid
                                ? AnyView(LinearGradient.ssAccentGradient.cornerRadius(14))
                                : AnyView(Color.ssBorder.cornerRadius(14)))
                }
                .disabled(!addVM.isValid)

            case .simulate:
                Button(action: { addVM.confirm(using: vm); dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirm Expense")
                    }
                    .font(SSFont.display(16, weight: .semibold)).foregroundColor(.ssBackground)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(LinearGradient.ssAccentGradient.cornerRadius(14))
                }

            case .wishlist:
                Button(action: { addVM.addToWishlist(using: vm); dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                        Text("Add to Wishlist")
                    }
                    .font(SSFont.display(16, weight: .semibold)).foregroundColor(.ssBackground)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(LinearGradient(colors: [.ssViolet, Color(hex: "#A855F7")],
                                              startPoint: .leading, endPoint: .trailing).cornerRadius(14))
                }
                .disabled(!addVM.isValid || addVM.wishlistName.isEmpty)

            default:
                Button(action: { addVM.confirm(using: vm); dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Expense")
                    }
                    .font(SSFont.display(16, weight: .semibold))
                    .foregroundColor(addVM.isValid ? .ssBackground : .ssTextTertiary)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(addVM.isValid
                                ? AnyView(LinearGradient.ssAccentGradient.cornerRadius(14))
                                : AnyView(Color.ssBorder.cornerRadius(14)))
                }
                .disabled(!addVM.isValid)
            }
        }
    }
}

struct CategoryChip: View {
    var category: SpendingCategory
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .medium))
                Text(category.rawValue.components(separatedBy: " ").first ?? "")
                    .font(SSFont.body(13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .ssBackground : .ssTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? category.color.cornerRadius(20) : Color.ssSurfaceElevated.cornerRadius(20))
            .overlay(Capsule().stroke(isSelected ? category.color : Color.ssBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct SimulationResultCard: View {
    var result: SimulationResult
    var vm: SpendSenseViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "wand.and.stars").font(.system(size: 14)).foregroundColor(.ssViolet)
                Text("Purchase Impact Preview")
                    .font(SSFont.display(15, weight: .bold)).foregroundColor(.ssTextPrimary)
                Spacer()
                Image(systemName: result.riskLevelAfter.icon).foregroundColor(result.riskLevelAfter.color)
            }

            Divider().background(Color.ssBorder)

            VStack(spacing: 12) {
                SimRow(label: "Purchase Amount",     value: vm.formatCurrency(result.amount), color: .ssDanger)
                SimRow(label: "Budget Remaining After", value: vm.formatCurrency(max(0, result.remainingAfter)), color: result.riskLevelAfter.color)
                SimRow(label: "Budget Used After",   value: "\(Int(result.progressAfter * 100))%", color: result.riskLevelAfter.color)
                SimRow(label: "Risk Level",          value: result.riskLevelAfter.rawValue, color: result.riskLevelAfter.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Budget after purchase").font(SSFont.body(11)).foregroundColor(.ssTextTertiary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.ssBorder).frame(height: 8)
                        Capsule()
                            .fill(result.riskLevelAfter.color)
                            .frame(width: geo.size.width * result.progressAfter, height: 8)
                    }
                }
                .frame(height: 8)
            }

            if let warning = result.categoryWarning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.ssWarning)
                    Text(warning).font(SSFont.body(12)).foregroundColor(.ssWarning)
                }
                .padding(10).background(Color.ssWarning.opacity(0.1)).cornerRadius(8)
            }

            if !result.isSafe {
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill").foregroundColor(.ssDanger)
                    Text("High risk! Consider adding this to your wishlist instead.")
                        .font(SSFont.body(12)).foregroundColor(.ssDanger)
                }
                .padding(10).background(Color.ssDanger.opacity(0.1)).cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.ssSurfaceElevated)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ssViolet.opacity(0.3), lineWidth: 1))
    }
}

struct SimRow: View {
    var label: String; var value: String; var color: Color
    var body: some View {
        HStack {
            Text(label).font(SSFont.body(13)).foregroundColor(.ssTextSecondary)
            Spacer()
            Text(value).font(SSFont.mono(13, weight: .bold)).foregroundColor(color)
        }
    }
}
