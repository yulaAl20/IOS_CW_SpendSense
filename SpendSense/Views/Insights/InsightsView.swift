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

    private var spendingData: [DaySpending] {
        switch selectedPeriod {
        case .weekly:  return vm.weeklySpendingData
        case .daily:   return vm.dailySpendingData
        case .monthly: return vm.monthlySpendingData
        }
    }

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

                    // Spending bar chart
                    PeriodBarChart(period: selectedPeriod, data: spendingData, vm: vm)
                        .padding(.horizontal, 20)

                    // Category breakdown
                    CategoryBreakdownSection(breakdown: vm.categoryBreakdown, vm: vm)
                        .padding(.horizontal, 20)

                    // Behavioral insights
                    BehavioralInsights(vm: vm)
                        .padding(.horizontal, 20)

                    // MapKit spending zones (for location alerts)
                    NavigationLink(destination: SpendingZonesMapView()) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.ssViolet.opacity(0.15))
                                    .frame(width: 42, height: 42)
                                Image(systemName: "map.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.ssViolet)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Spending Zones")
                                    .font(SSFont.display(15, weight: .bold))
                                    .foregroundColor(.ssTextPrimary)
                                Text("View high-spending areas and simulate location alerts.")
                                    .font(SSFont.body(12))
                                    .foregroundColor(.ssTextSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.ssTextTertiary)
                        }
                        .padding(16)
                        .background(Color.ssSurface)
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.ssBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
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

// Period Bar Chart
struct PeriodBarChart: View {
    var period: BudgetPeriod
    var data: [DaySpending]
    var vm: SpendSenseViewModel
    @State private var animateBars = false

    var maxAmount: Double {
        let maxVal = data.map { $0.amount }.max() ?? 1
        return maxVal > 0 ? maxVal : 1
    }

    private var title: String {
        switch period {
        case .weekly:
            return "7-Day Spending"
        case .daily:
            return "Today (Hourly)"
        case .monthly:
            let f = DateFormatter()
            f.locale = Locale.current
            f.dateFormat = "MMMM"
            return "\(f.string(from: Date())) Spending"
        }
    }

    private var barWidth: CGFloat {
        switch period {
        case .weekly:  return 28
        case .daily:   return 22
        case .monthly: return 18
        }
    }

    private var barSpacing: CGFloat { 8 }

    private var showValueLabels: Bool { data.count <= 12 }

    private func isCurrentBucket(_ bucket: DaySpending) -> Bool {
        let calendar = Calendar.current
        switch period {
        case .weekly, .monthly:
            return calendar.isDateInToday(bucket.date)
        case .daily:
            let now = Date()
            return calendar.isDate(bucket.date, equalTo: now, toGranularity: .hour)
                && calendar.isDate(bucket.date, inSameDayAs: now)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(SSFont.display(17, weight: .bold))
                    .foregroundColor(.ssTextPrimary)
                Spacer()
                Text("Total: \(vm.formatCurrency(data.reduce(0) { $0 + $1.amount }))")
                    .font(SSFont.mono(12))
                    .foregroundColor(.ssTextSecondary)
            }

            if period == .weekly {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data) { bucket in
                        VStack(spacing: 6) {
                            if bucket.amount > 0 {
                                Text(bucket.amount >= 1000 ?
                                     String(format: "%.0fk", bucket.amount / 1000) :
                                     String(Int(bucket.amount)))
                                    .font(SSFont.mono(9, weight: .medium))
                                    .foregroundColor(.ssTextTertiary)
                            }

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    isCurrentBucket(bucket)
                                        ? LinearGradient.ssAccentGradient
                                        : LinearGradient(colors: [Color.ssViolet.opacity(0.7), Color.ssViolet.opacity(0.4)],
                                                         startPoint: .top, endPoint: .bottom)
                                )
                                .frame(height: max(4, CGFloat(bucket.amount / maxAmount) * 120))
                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: bucket.amount)

                            Text(bucket.label.prefix(3).description)
                                .font(SSFont.body(10))
                                .foregroundColor(isCurrentBucket(bucket) ? .ssAccent : .ssTextTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 160)
            } else {
                GeometryReader { geo in
                    let contentWidth = CGFloat(data.count) * barWidth + CGFloat(max(0, data.count - 1)) * barSpacing
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: barSpacing) {
                            ForEach(data) { bucket in
                                VStack(spacing: 6) {
                                    if showValueLabels, bucket.amount > 0 {
                                        Text(bucket.amount >= 1000 ?
                                             String(format: "%.0fk", bucket.amount / 1000) :
                                             String(Int(bucket.amount)))
                                            .font(SSFont.mono(9, weight: .medium))
                                            .foregroundColor(.ssTextTertiary)
                                            .frame(width: barWidth)
                                    } else {
                                        Color.clear.frame(height: 10)
                                    }

                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            isCurrentBucket(bucket)
                                                ? LinearGradient.ssAccentGradient
                                                : LinearGradient(
                                                    colors: [Color.ssViolet.opacity(0.7), Color.ssViolet.opacity(0.4)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                        )
                                        .frame(width: barWidth,
                                               height: max(4, CGFloat(bucket.amount / maxAmount) * 120))
                                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: bucket.amount)

                                    Text(bucket.label)
                                        .font(SSFont.body(10))
                                        .foregroundColor(isCurrentBucket(bucket) ? .ssAccent : .ssTextTertiary)
                                        .frame(width: barWidth)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                        }
                        .frame(width: max(geo.size.width, contentWidth), alignment: .leading)
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(18)
        .background(Color.ssSurface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.ssBorder, lineWidth: 1))
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
                                            .frame(width: geo.size.width * pct, height: 5)
                                            .animation(.easeOut(duration: 0.7), value: pct)
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
