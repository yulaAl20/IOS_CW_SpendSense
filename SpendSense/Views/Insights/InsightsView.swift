//
//  InsightsView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-10.
//
import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var vm: SpendSenseViewModel
    @State private var selectedPeriod: BudgetPeriod = .weekly

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Period picker
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Weekly bar chart
                    WeeklyBarChart(data: vm.weeklySpendingData, vm: vm)
                        .padding(.horizontal, 20)

                    // Category breakdown
                    CategoryBreakdownSection(breakdown: vm.categoryBreakdown, vm: vm)
                        .padding(.horizontal, 20)

                    // Behavioral insights
                    BehavioralInsights(vm: vm)
                        .padding(.horizontal, 20)

                    Spacer().frame(height: 100)
                }
            }
            .background(Color.ssBackground)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// Weekly Bar Chart
struct WeeklyBarChart: View {
    var data: [DaySpending]
    var vm: SpendSenseViewModel
    @State private var animateBars = false

    var maxAmount: Double { data.map { $0.amount }.max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("7-Day Spending")
                    .font(SSFont.display(17, weight: .bold))
                    .foregroundColor(.ssTextPrimary)
                Spacer()
                Text("Total: \(vm.formatCurrency(data.reduce(0) { $0 + $1.amount }))")
                    .font(SSFont.mono(12))
                    .foregroundColor(.ssTextSecondary)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { day in
                    VStack(spacing: 6) {
                        // Amount label on top of bar
                        if day.amount > 0 {
                            Text(day.amount >= 1000 ?
                                 String(format: "%.0fk", day.amount / 1000) :
                                 String(Int(day.amount)))
                                .font(SSFont.mono(9, weight: .medium))
                                .foregroundColor(.ssTextTertiary)
                        }

                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                Calendar.current.isDateInToday(day.date)
                                    ? LinearGradient.ssAccentGradient
                                    : LinearGradient(colors: [Color.ssViolet.opacity(0.7), Color.ssViolet.opacity(0.4)],
                                                     startPoint: .top, endPoint: .bottom)
                            )
                            .frame(height: animateBars
                                   ? max(4, CGFloat(day.amount / maxAmount) * 120)
                                   : 4)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7)
                                .delay(Double(data.firstIndex(where: { $0.id == day.id }) ?? 0) * 0.05),
                                       value: animateBars)

                        Text(day.label.prefix(3).description)
                            .font(SSFont.body(10))
                            .foregroundColor(
                                Calendar.current.isDateInToday(day.date) ? .ssAccent : .ssTextTertiary
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 160)
        }
        .padding(18)
        .background(Color.ssSurface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.ssBorder, lineWidth: 1))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateBars = true
            }
        }
    }
}

// Category Breakdown
struct CategoryBreakdownSection: View {
    var breakdown: [CategorySpending]
    var vm: SpendSenseViewModel
    @State private var animateBars = false

    var total: Double { breakdown.reduce(0) { $0 + $1.amount } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(SSFont.display(17, weight: .bold))
                .foregroundColor(.ssTextPrimary)

            if breakdown.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.pie").font(.system(size: 28)).foregroundColor(.ssTextTertiary)
                        Text("No data yet").font(SSFont.body(14)).foregroundColor(.ssTextSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(breakdown) { item in
                        let pct = total > 0 ? item.amount / total : 0
                        HStack(spacing: 12) {
                            // Icon
                            ZStack {
                                Circle().fill(item.category.color.opacity(0.15)).frame(width: 36, height: 36)
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 15))
                                    .foregroundColor(item.category.color)
                            }

                            // Bar
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.category.rawValue)
                                        .font(SSFont.body(13, weight: .medium))
                                        .foregroundColor(.ssTextPrimary)
                                    Spacer()
                                    Text(vm.formatCurrency(item.amount))
                                        .font(SSFont.mono(13, weight: .bold))
                                        .foregroundColor(.ssTextPrimary)
                                    Text("(\(Int(pct * 100))%)")
                                        .font(SSFont.body(11))
                                        .foregroundColor(.ssTextTertiary)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.ssBorder).frame(height: 5)
                                        Capsule()
                                            .fill(item.category.color)
                                            .frame(width: geo.size.width * (animateBars ? pct : 0), height: 5)
                                            .animation(.easeOut(duration: 0.7)
                                                .delay(Double(breakdown.firstIndex(where: { $0.id == item.id }) ?? 0) * 0.07),
                                                       value: animateBars)
                                    }
                                }
                                .frame(height: 5)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color.ssSurface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.ssBorder, lineWidth: 1))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateBars = true
            }
        }
    }
}

// Behavioral Insights
struct BehavioralInsights: View {
    @ObservedObject var vm: SpendSenseViewModel

    var insights: [InsightCard] {
        var cards: [InsightCard] = []
        let calendar = Calendar.current
        let dayOfMonth = Double(max(1, calendar.component(.day, from: Date())))

        // Highest spending category
        if let top = vm.categoryBreakdown.first {
            let limit = vm.budgetLimit(for: top.category)
            let overBudget = limit.map { top.amount > $0 } ?? false
            cards.append(InsightCard(
                icon: top.category.icon,
                iconColor: top.category.color,
                title: "Highest Spending",
                body: overBudget
                    ? "\(top.category.rawValue) has exceeded its budget at \(vm.formatCurrency(top.amount)). Consider cutting back."
                    : "\(top.category.rawValue) accounts for the most spending this month at \(vm.formatCurrency(top.amount)).",
                type: overBudget ? .warning : .info
            ))
        }

        // Daily average
        let avg = vm.totalSpentThisMonth / dayOfMonth
        let dailyBudget = vm.dailyBudget
        let avgStatus: InsightCard.InsightType = avg > dailyBudget ? .warning : .neutral
        cards.append(InsightCard(
            icon: "calendar.badge.clock",
            iconColor: avgStatus == .warning ? .ssWarning : .ssViolet,
            title: "Daily Average",
            body: avg > dailyBudget
                ? "You're averaging \(vm.formatCurrency(avg))/day — above your \(vm.formatCurrency(dailyBudget)) target. Try to reduce daily spending."
                : "You're averaging \(vm.formatCurrency(avg))/day this month, within your \(vm.formatCurrency(dailyBudget)) daily target.",
            type: avgStatus
        ))

        // Spending velocity — compare first half vs current pace
        if dayOfMonth > 3 {
            let projectedTotal = avg * 30
            let budgetPct = vm.monthlyBudget > 0 ? projectedTotal / vm.monthlyBudget * 100 : 0
            if projectedTotal > vm.monthlyBudget {
                cards.append(InsightCard(
                    icon: "speedometer",
                    iconColor: .ssDanger,
                    title: "Spending Velocity",
                    body: "At this pace you'll spend \(vm.formatCurrency(projectedTotal)) this month — \(Int(budgetPct))% of your budget. Slow down!",
                    type: .warning
                ))
            } else {
                cards.append(InsightCard(
                    icon: "speedometer",
                    iconColor: .ssSuccess,
                    title: "Spending Velocity",
                    body: "You're projected to spend \(vm.formatCurrency(projectedTotal)) this month — well within your \(vm.formatCurrency(vm.monthlyBudget)) budget.",
                    type: .positive
                ))
            }
        }

        // Wishlist savings progress
        let activeWishlist = vm.wishlist.filter { !$0.isReadyToPurchase }
        let totalWishlistSaved = vm.wishlist.reduce(0.0) { $0 + $1.savedAmount }
        if !activeWishlist.isEmpty {
            let totalTarget = activeWishlist.reduce(0.0) { $0 + $1.amount }
            let totalSaved  = activeWishlist.reduce(0.0) { $0 + $1.savedAmount }
            cards.append(InsightCard(
                icon: "heart.circle.fill",
                iconColor: .ssViolet,
                title: "Wishlist Savings",
                body: "You've saved \(vm.formatCurrency(totalSaved)) of \(vm.formatCurrency(totalTarget)) across \(activeWishlist.count) wishlist item\(activeWishlist.count == 1 ? "" : "s"). Keep it up!",
                type: .info
            ))
        } else if totalWishlistSaved > 0 {
            cards.append(InsightCard(
                icon: "heart.circle.fill",
                iconColor: .ssAccent,
                title: "Wishlist Savings",
                body: "All wishlist items are fully saved! You've set aside \(vm.formatCurrency(totalWishlistSaved)) total.",
                type: .positive
            ))
        }

        // Savings projection
        if vm.userProfile.monthlyIncome > 0 {
            let savingsPct = (vm.userProfile.monthlyIncome - vm.totalSpentThisMonth) / vm.userProfile.monthlyIncome * 100
            let goalPct = vm.userProfile.savingsGoalPercent
            cards.append(InsightCard(
                icon: "arrow.up.right.circle.fill",
                iconColor: savingsPct >= goalPct ? .ssSuccess : .ssWarning,
                title: "Savings Projection",
                body: savingsPct >= goalPct
                    ? "You're on track to save \(Int(savingsPct))% this month — above your \(Int(goalPct))% goal! 🎉"
                    : "You're projected to save \(Int(max(0, savingsPct)))% this month — below your \(Int(goalPct))% target. Try cutting non-essential spending.",
                type: savingsPct >= goalPct ? .positive : .warning
            ))
        }

        //  Impulse pattern detection — count shopping/entertainment vs total
        let impulseCategories: Set<SpendingCategory> = [.shopping, .entertainment]
        let impulseSpend = vm.categoryBreakdown
            .filter { impulseCategories.contains($0.category) }
            .reduce(0.0) { $0 + $1.amount }
        let totalSpend = vm.totalSpentThisMonth
        if totalSpend > 0 {
            let impulsePct = impulseSpend / totalSpend * 100
            if impulsePct > 40 {
                cards.append(InsightCard(
                    icon: "hand.raised.fill",
                    iconColor: .ssDanger,
                    title: "Impulse Alert",
                    body: "Shopping & Entertainment make up \(Int(impulsePct))% of your spending. Consider using the wishlist to cool off before buying.",
                    type: .warning
                ))
            }
        }

        return cards
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Behavioral Insights")
                .font(SSFont.display(17, weight: .bold))
                .foregroundColor(.ssTextPrimary)

            if insights.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 28))
                            .foregroundColor(.ssTextTertiary)
                        Text("Add some transactions to see insights")
                            .font(SSFont.body(14))
                            .foregroundColor(.ssTextSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                ForEach(insights, id: \.title) { card in
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(card.iconColor.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: card.icon)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(card.iconColor)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.title)
                                .font(SSFont.body(14, weight: .semibold))
                                .foregroundColor(.ssTextPrimary)
                            Text(card.body)
                                .font(SSFont.body(13))
                                .foregroundColor(.ssTextSecondary)
                                .lineSpacing(3)
                        }
                    }
                    .padding(14)
                    .background(Color.ssSurface)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ssBorder, lineWidth: 1))
                }
            }
        }
    }
}

struct InsightCard {
    var icon: String
    var iconColor: Color
    var title: String
    var body: String
    var type: InsightType

    enum InsightType { case info, neutral, positive, warning }
}

#if DEBUG
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView()
            .environmentObject(SpendSenseViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif
