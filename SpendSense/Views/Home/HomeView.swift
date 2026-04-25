//
//  HomeView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-10.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var vm: SpendSenseViewModel
    @State private var showWishlist = false
    @State private var showAlerts = false

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.ssBackground.ignoresSafeArea()

            // Scrollable Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    Spacer()
                        .frame(height: 60)

                    
                    BudgetHeroCard()
                        .environmentObject(vm)
                    
                   
                    HStack(spacing: 12) {
                        QuickStatCard(
                            label: "Today",
                            value: vm.formatCurrency(vm.totalSpentToday),
                            subValue: "\(vm.formatCurrency(vm.remainingDaily)) left",
                            icon: "sun.max.fill",
                            color: .ssWarning,
                            progress: vm.dailyProgress
                        )
                        QuickStatCard(
                            label: "This Month",
                            value: vm.formatCurrency(vm.totalSpentThisMonth),
                            subValue: "\(Int(vm.monthlyProgress * 100))% used",
                            icon: "calendar",
                            color: vm.currentRiskLevel.color,
                            progress: vm.monthlyProgress
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    
                    RiskBanner(riskLevel: vm.currentRiskLevel, progress: vm.monthlyProgress)
                        .padding(.horizontal, 20)
                    
                    // Recent transactions
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Recent Activity")
                                .font(SSFont.display(17, weight: .bold))
                                .foregroundColor(.ssTextPrimary)
                            Spacer()
                            if !vm.transactions.isEmpty {
                                NavigationLink("See all", destination: TransactionsView().environmentObject(vm))
                                    .font(SSFont.body(13, weight: .medium))
                                    .foregroundColor(.ssAccent)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        if vm.transactions.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "tray")
                                    .font(.system(size: 28))
                                    .foregroundColor(.ssTextTertiary)
                                Text("No transactions yet")
                                    .font(SSFont.body(14))
                                    .foregroundColor(.ssTextSecondary)
                                Text("Tap + to add your first expense")
                                    .font(SSFont.body(12))
                                    .foregroundColor(.ssTextTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color.ssSurface)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ssBorder, lineWidth: 1))
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 1) {
                                ForEach(vm.transactions.prefix(5)) { t in
                                    TransactionRow(transaction: t, vm: vm)
                                }
                            }
                            .background(Color.ssSurface)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ssBorder, lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Wishlist section
                    if !vm.wishlist.isEmpty {
                        WishlistPreview(showWishlist: $showWishlist)
                            .environmentObject(vm)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer().frame(height: 100)
                }
            }
            .background(Color.ssBackground)
            
            // Modern Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(greetingTime)")
                        .font(.subheadline)
                        .foregroundColor(.ssTextSecondary)
                    
                    Text(vm.userProfile.name.isEmpty ? "Spender" : vm.userProfile.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.ssTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                Button {
                    showAlerts = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.ssAccent.opacity(0.9), Color.ssViolet.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        if vm.unreadAlertsCount > 0 {
                            Text("\(min(vm.unreadAlertsCount, 99))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(Color.ssDanger))
                                .offset(x: 14, y: -14)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .frame(height: 50)
        }
        .sheet(isPresented: $showWishlist) {
            WishlistSheet().environmentObject(vm)
        }
        .sheet(isPresented: $showAlerts) {
            AlertsView().environmentObject(vm)
        }
    }

    var greetingTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Morning" }
        if hour < 17 { return "Afternoon" }
        return "Evening"
    }
}


struct BudgetHeroCard: View {
    @EnvironmentObject var vm: SpendSenseViewModel

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.ssSurfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.ssAccent.opacity(0.3), Color.ssViolet.opacity(0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            // Ambient glow
            Circle()
                .fill(vm.currentRiskLevel.color.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: 80, y: -20)

            HStack(spacing: 24) {
                // Ring chart
                ZStack {
                    Circle()
                        .stroke(Color.ssBorder, lineWidth: 10)
                        .frame(width: 110, height: 110)

                    Circle()
                        .trim(from: 0, to: vm.monthlyProgress)
                        .stroke(
                            LinearGradient(
                                colors: [vm.currentRiskLevel.color, vm.currentRiskLevel.color.opacity(0.6)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(vm.monthlyProgress * 100))%")
                            .font(SSFont.mono(22, weight: .bold))
                            .foregroundColor(.ssTextPrimary)
                        Text("used")
                            .font(SSFont.body(11))
                            .foregroundColor(.ssTextSecondary)
                    }
                }

                // Labels
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Monthly Budget")
                            .font(SSFont.body(12))
                            .foregroundColor(.ssTextSecondary)
                        Text(vm.formatCurrency(vm.monthlyBudget))
                            .font(SSFont.mono(22, weight: .bold))
                            .foregroundColor(.ssTextPrimary)
                    }

                    Divider().background(Color.ssBorder)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Remaining")
                            .font(SSFont.body(12))
                            .foregroundColor(.ssTextSecondary)
                        Text(vm.formatCurrency(max(0, vm.remainingMonthly)))
                            .font(SSFont.mono(20, weight: .bold))
                            .foregroundColor(vm.currentRiskLevel.color)
                    }

                    // Risk badge
                    HStack(spacing: 5) {
                        Image(systemName: vm.currentRiskLevel.icon)
                            .font(.system(size: 11))
                        Text("\(vm.currentRiskLevel.rawValue) Risk")
                            .font(SSFont.body(12, weight: .semibold))
                    }
                    .foregroundColor(vm.currentRiskLevel.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(vm.currentRiskLevel.color.opacity(0.15))
                    .cornerRadius(20)
                }

                Spacer()
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
    }
}

// Quick Stat Card
struct QuickStatCard: View {
    var label: String
    var value: String
    var subValue: String
    var icon: String
    var color: Color
    var progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(SSFont.body(12))
                    .foregroundColor(.ssTextSecondary)
            }

            Text(value)
                .font(SSFont.mono(18, weight: .bold))
                .foregroundColor(.ssTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ssBorder).frame(height: 4)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * min(progress, 1.0), height: 4)
                        .animation(.easeOut(duration: 0.8), value: progress)
                }
            }
            .frame(height: 4)

            Text(subValue)
                .font(SSFont.body(11))
                .foregroundColor(.ssTextSecondary)
        }
        .padding(14)
        .background(Color.ssSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ssBorder, lineWidth: 1))
        .frame(maxWidth: .infinity)
    }
}

// Risk Banner
struct RiskBanner: View {
    var riskLevel: RiskLevel
    var progress: Double

    var message: String {
        switch riskLevel {
        case .low: return "You're on track! Keep maintaining your budget habits."
        case .moderate: return "Heads up — you've used \(Int(progress * 100))% of your budget. Slow down."
        case .high: return "⚠️ High risk! You're close to exceeding your monthly limit."
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: riskLevel.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(riskLevel.color)

            Text(message)
                .font(SSFont.body(13))
                .foregroundColor(.ssTextSecondary)

            Spacer()
        }
        .padding(14)
        .background(riskLevel.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(riskLevel.color.opacity(0.3), lineWidth: 1))
    }
}

// Transaction Row
struct TransactionRow: View {
    var transaction: TransactionModel
    var vm: SpendSenseViewModel

    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(transaction.category.color)
            }

            // Details
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.note.isEmpty ? transaction.category.rawValue : transaction.note)
                    .font(SSFont.body(14, weight: .medium))
                    .foregroundColor(.ssTextPrimary)
                    .lineLimit(1)
                Text(transaction.category.rawValue)
                    .font(SSFont.body(12))
                    .foregroundColor(.ssTextSecondary)
            }

            Spacer()

            // Amount & date
            VStack(alignment: .trailing, spacing: 3) {
                Text(transaction.isIncome ? "+\(vm.formatCurrency(transaction.amount))" : "-\(vm.formatCurrency(transaction.amount))")
                    .font(SSFont.mono(14, weight: .semibold))
                    .foregroundColor(transaction.isIncome ? .ssSuccess : .ssDanger)
                Text(transaction.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(SSFont.body(11))
                    .foregroundColor(.ssTextTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.ssSurface)
    }
}

// Wishlist Preview
struct WishlistPreview: View {
    @EnvironmentObject var vm: SpendSenseViewModel
    @Binding var showWishlist: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Wishlist", systemImage: "heart.fill")
                    .font(SSFont.display(16, weight: .bold))
                    .foregroundColor(.ssTextPrimary)
                Spacer()
                Button("View all") { showWishlist = true }
                    .font(SSFont.body(13, weight: .medium))
                    .foregroundColor(.ssAccent)
            }

            ForEach(vm.wishlist.prefix(2)) { item in
                WishlistRow(item: item, vm: vm)
            }
        }
    }
}

// Wishlist Row  (compact – shown on dashboard)
struct WishlistRow: View {
    var item: WishlistItemModel
    var vm: SpendSenseViewModel

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(item.category.color.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: item.isReadyToPurchase ? "checkmark.circle.fill" : "clock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(item.isReadyToPurchase ? .ssAccent : .ssWarning)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(SSFont.body(14, weight: .semibold))
                        .foregroundColor(.ssTextPrimary)
                    if item.isReadyToPurchase {
                        Text("Fully saved — Ready to purchase!")
                            .font(SSFont.body(12))
                            .foregroundColor(.ssAccent)
                    } else {
                        Text("\(vm.formatCurrency(item.savedAmount)) / \(vm.formatCurrency(item.amount))  •  \(item.daysRemaining)d left")
                            .font(SSFont.body(12))
                            .foregroundColor(.ssTextSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(vm.formatCurrency(item.amountRemaining))
                        .font(SSFont.mono(14, weight: .bold))
                        .foregroundColor(item.isReadyToPurchase ? .ssAccent : .ssTextPrimary)
                    Text("left")
                        .font(SSFont.body(10))
                        .foregroundColor(.ssTextTertiary)
                }
            }

            // Savings progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ssBorder).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color.ssViolet, Color.ssAccent],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * item.savingsProgress, height: 5)
                        .animation(.easeOut(duration: 0.6), value: item.savingsProgress)
                }
            }
            .frame(height: 5)
        }
        .padding(14)
        .background(Color.ssSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ssBorder, lineWidth: 1))
    }
}
#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {

        // Dummy data setup for preview
        let vm = SpendSenseViewModel()
        let appState = AppStateViewModel()

        // mock user for UI preview
        vm.userProfile.name = "Yulani"

        return Group {
            MainTabView()
                .environmentObject(vm)
                .environmentObject(appState)
                .preferredColorScheme(.dark)

            MainTabView()
                .environmentObject(vm)
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}
#endif

// WishlistSheet

struct WishlistSheet: View {
    @EnvironmentObject var vm: SpendSenseViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.ssBackground.ignoresSafeArea()

                if vm.wishlist.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.ssTextTertiary)
                        Text("Wishlist is empty")
                            .font(SSFont.display(18, weight: .bold))
                            .foregroundColor(.ssTextSecondary)
                        Text("Add items here to pause impulse purchases\nand reflect before you buy.")
                            .font(SSFont.body(14))
                            .foregroundColor(.ssTextTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.ssViolet)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Savings Plan Active")
                                        .font(SSFont.body(14, weight: .semibold))
                                        .foregroundColor(.ssTextPrimary)
                                    Text("Daily savings are auto-deducted from your budget to help you save for wishlist items.")
                                        .font(SSFont.body(12))
                                        .foregroundColor(.ssTextSecondary)
                                }
                            }
                            .padding(14)
                            .background(Color.ssVioletDim)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ssViolet.opacity(0.3), lineWidth: 1))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 20)

                            ForEach(vm.wishlist) { item in
                                WishlistDetailRow(item: item, vm: vm)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 12)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.ssAccent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// WishlistDetailRow

struct WishlistDetailRow: View {
    var item: WishlistItemModel
    var vm: SpendSenseViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(item.category.color.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: item.category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(item.category.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(SSFont.body(15, weight: .semibold))
                        .foregroundColor(.ssTextPrimary)
                    Text(item.category.rawValue)
                        .font(SSFont.body(12))
                        .foregroundColor(.ssTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(vm.formatCurrency(item.amount))
                        .font(SSFont.mono(15, weight: .bold))
                        .foregroundColor(.ssTextPrimary)
                    Text(item.isReadyToPurchase ? "Saved!" : "\(item.daysRemaining)d left")
                        .font(SSFont.body(12, weight: .semibold))
                        .foregroundColor(item.isReadyToPurchase ? .ssAccent : .ssWarning)
                }
            }

            // Savings progress section
            VStack(alignment: .leading, spacing: 8) {
                // Money progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Saved")
                            .font(SSFont.body(11))
                            .foregroundColor(.ssTextTertiary)
                        Spacer()
                        Text("\(vm.formatCurrency(item.savedAmount)) / \(vm.formatCurrency(item.amount))")
                            .font(SSFont.mono(12, weight: .semibold))
                            .foregroundColor(.ssTextSecondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.ssBorder).frame(height: 6)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color.ssViolet, Color.ssAccent],
                                    startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * item.savingsProgress, height: 6)
                                .animation(.easeOut(duration: 0.6), value: item.savingsProgress)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.top, 12)

                // Time progress bar
                if !item.isReadyToPurchase {
                    let totalDays = max(Double(item.savingsDays), 1)
                    let elapsed = Double(item.daysElapsed)
                    let timeProgress = min(elapsed / totalDays, 1.0)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Time")
                                .font(SSFont.body(11))
                                .foregroundColor(.ssTextTertiary)
                            Spacer()
                            Text("\(item.daysElapsed) / \(item.savingsDays) days")
                                .font(SSFont.mono(12, weight: .semibold))
                                .foregroundColor(.ssTextSecondary)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.ssBorder).frame(height: 4)
                                Capsule()
                                    .fill(Color.ssWarning.opacity(0.7))
                                    .frame(width: geo.size.width * timeProgress, height: 4)
                                    .animation(.easeOut(duration: 0.6), value: timeProgress)
                            }
                        }
                        .frame(height: 4)
                    }
                }

                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily saving")
                            .font(SSFont.body(10))
                            .foregroundColor(.ssTextTertiary)
                        Text(vm.formatCurrency(item.dailySavingsAmount))
                            .font(SSFont.mono(13, weight: .bold))
                            .foregroundColor(.ssViolet)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(SSFont.body(10))
                            .foregroundColor(.ssTextTertiary)
                        Text(vm.formatCurrency(item.amountRemaining))
                            .font(SSFont.mono(13, weight: .bold))
                            .foregroundColor(item.isReadyToPurchase ? .ssAccent : .ssWarning)
                    }
                }
                .padding(.top, 4)

                // Status
                if item.isReadyToPurchase {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.ssAccent)
                        Text("Fully saved — make a mindful purchase decision")
                            .font(SSFont.body(12))
                            .foregroundColor(.ssAccent)
                        Spacer()
                    }
                    .padding(.top, 4)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.ssViolet)
                            .font(.system(size: 12))
                        Text("Unlocks \(item.waitUntil.formatted(.dateTime.day().month(.abbreviated)))")
                            .font(SSFont.body(11))
                            .foregroundColor(.ssTextTertiary)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .background(Color.ssSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.isReadyToPurchase ? Color.ssAccent.opacity(0.4) : Color.ssBorder, lineWidth: 1)
        )
    }
}
