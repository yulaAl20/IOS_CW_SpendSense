//
//  BudgetView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-10.
//
import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var vm: SpendSenseViewModel
    @State private var showAddBudget = false
    @State private var selectedPeriod: BudgetPeriod = .monthly

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Period selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Global budget card
                    GlobalBudgetCard(period: selectedPeriod)
                        .environmentObject(vm)
                        .padding(.horizontal, 20)

                    // Category budgets
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Category Budgets")
                            .font(SSFont.display(17, weight: .bold))
                            .foregroundColor(.ssTextPrimary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            ForEach(SpendingCategory.allCases) { category in
                                CategoryBudgetCard(
                                    category: category,
                                    limit: vm.budgetLimit(for: category),
                                    spent: vm.spent(for: category, period: selectedPeriod),
                                    vm: vm
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Add budget button
                    Button(action: { showAddBudget = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Set Category Budget")
                        }
                        .font(SSFont.display(15, weight: .semibold))
                        .foregroundColor(.ssAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.ssAccentDim)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ssAccent.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 100)
                }
            }
            .background(Color.ssBackground)
            .navigationTitle("Budget Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// Global Budget Card
struct GlobalBudgetCard: View {
    @EnvironmentObject var vm: SpendSenseViewModel
    var period: BudgetPeriod
    @State private var displayedProgress: Double = 0

    var spent: Double {
        switch period {
        case .daily:   return vm.totalSpentToday
        case .weekly:  return vm.transactions
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.amount }
        case .monthly: return vm.totalSpentThisMonth
        }
    }

    var limit: Double {
        switch period {
        case .daily:   return vm.dailyBudget
        case .weekly:  return vm.monthlyBudget / 4
        case .monthly: return vm.monthlyBudget
        }
    }

    var progress: Double { min(spent / max(limit, 1), 1.0) }

    var riskColor: Color {
        if progress < 0.6 { return .ssSuccess }
        if progress < 0.85 { return .ssWarning }
        return .ssDanger
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header gradient
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spent")
                            .font(SSFont.body(13))
                            .foregroundColor(.ssTextSecondary)
                        Text(vm.formatCurrency(spent))
                            .font(SSFont.mono(24, weight: .bold))
                            .foregroundColor(.ssTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(SSFont.body(13))
                            .foregroundColor(.ssTextSecondary)
                        Text(vm.formatCurrency(max(0, limit - spent)))
                            .font(SSFont.mono(24, weight: .bold))
                            .foregroundColor(riskColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }

                HStack {
                    Text("\(period.rawValue) Limit")
                        .font(SSFont.body(12))
                        .foregroundColor(.ssTextTertiary)
                    Spacer()
                    Text(vm.formatCurrency(limit))
                        .font(SSFont.mono(12, weight: .semibold))
                        .foregroundColor(.ssTextSecondary)
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.ssBorder)
                                .frame(height: 10)
                            Capsule()
                                .fill(riskColor)
                                .frame(width: geo.size.width * displayedProgress, height: 10)
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text(vm.formatCurrency(0))
                        Spacer()
                        Text("\(Int(progress * 100))% used")
                            .font(SSFont.body(12, weight: .semibold))
                            .foregroundColor(riskColor)
                        Spacer()
                        Text(vm.formatCurrency(limit))
                    }
                    .font(SSFont.body(11))
                    .foregroundColor(.ssTextTertiary)
                }
            }
            .padding(20)
        }
        .background(Color.ssSurfaceElevated)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.ssBorder, lineWidth: 1))
        .onAppear {
            displayedProgress = 0
            withAnimation(.easeOut(duration: 0.9)) {
                displayedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                displayedProgress = newValue
            }
        }
    }
}

// Category Budget Card
struct CategoryBudgetCard: View {
    var category: SpendingCategory
    var limit: Double?
    var spent: Double
    var vm: SpendSenseViewModel
    @State private var displayedProgress: Double = 0

    var progress: Double {
        guard let l = limit, l > 0 else { return 0 }
        return min(spent / l, 1.0)
    }

    var statusColor: Color {
        guard limit != nil else { return .ssTextTertiary }
        if progress < 0.6 { return .ssSuccess }
        if progress < 0.85 { return .ssWarning }
        return .ssDanger
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(category.color)
                }

                Text(category.rawValue)
                    .font(SSFont.body(14, weight: .semibold))
                    .foregroundColor(.ssTextPrimary)

                Spacer()

                if let l = limit {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(vm.formatCurrency(spent))
                            .font(SSFont.mono(13, weight: .semibold))
                            .foregroundColor(statusColor)
                        Text("/ \(vm.formatCurrency(l))")
                            .font(SSFont.mono(12))
                            .foregroundColor(.ssTextTertiary)
                    }
                } else {
                    Text(vm.formatCurrency(spent))
                        .font(SSFont.mono(14, weight: .semibold))
                        .foregroundColor(.ssTextSecondary)
                    Text("No limit")
                        .font(SSFont.body(12))
                        .foregroundColor(.ssTextTertiary)
                }
            }

            if limit != nil {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.ssBorder).frame(height: 5)
                        Capsule()
                            .fill(statusColor)
                            .frame(width: geo.size.width * displayedProgress, height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(14)
        .background(Color.ssSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ssBorder, lineWidth: 1))
        .onAppear {
            displayedProgress = 0
            withAnimation(.easeOut(duration: 0.7)) {
                displayedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 0.7)) {
                displayedProgress = newValue
            }
        }
    }
}

#if DEBUG
struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetView()
            .environmentObject(SpendSenseViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif
