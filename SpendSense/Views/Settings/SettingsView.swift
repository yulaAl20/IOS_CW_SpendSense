//
//  SettingsView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-15.
//

import SwiftUI
import MessageUI
import Combine

struct SettingsView: View {
    @EnvironmentObject var vm: SpendSenseViewModel
    @EnvironmentObject var appState: AppStateViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showProfile       = false
    @State private var showWishlist      = false
    @State private var showSyncBackups   = false
    @State private var showEditBudget    = false
    @State private var showChangePass    = false
    @State private var showMail          = false

    // Alerts
    @State private var showLogoutAlert   = false
    @State private var showDeleteAlert   = false
    @State private var isSyncing         = false

    // Security
    @State private var biometricEnabled: Bool = false

    // Notifications
    @State private var pushNotificationsOn: Bool   = true
    @State private var budgetWarningsOn: Bool       = true
    @State private var smartInsightsOn: Bool        = true
    @State private var budgetWarningPercent: Double = 80.0

    // Accessibility
    @State private var selectedCurrency: String      = "USD"
    @State private var textSizeMultiplier: Double    = 1.0

    private let currencies = ["USD", "EUR", "GBP", "LKR", "AUD", "CAD", "INR", "JPY", "SGD"]
    private var previewFontSize: CGFloat { CGFloat(14) * textSizeMultiplier }

    var body: some View {
        NavigationView {
            ZStack {
                Color.ssBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {

                        
                        profileHeroCard
                            .padding(.horizontal, 20)
                            .padding(.top, 6)

                        SSSettingsSection(title: "Profile") {
                            SSNavRow(icon: "pencil.circle.fill", iconColor: .ssAccent,
                                     label: "Edit Profile", detail: vm.userProfile.name) {
                                showProfile = true
                            }
                            SSRowDivider()
                            SSNavRow(icon: "heart.fill", iconColor: .ssWarning,
                                     label: "Wishlist",
                                     detail: "\(vm.wishlist.count) items") {
                                showWishlist = true
                            }
                            SSRowDivider()
                            SSNavRow(icon: "arrow.triangle.2.circlepath.icloud.fill",
                                     iconColor: .ssInfo,
                                     label: "Sync & Backups",
                                     detail: "Up to date") {
                                showSyncBackups = true
                            }
                        }
                        .padding(.horizontal, 20)

                        SSSettingsSection(title: "Budget") {
                            SSNavRow(icon: "dollarsign.circle.fill", iconColor: .ssAccent,
                                     label: "Monthly Budget",
                                     detail: vm.formatCurrency(vm.monthlyBudget)) {
                                showEditBudget = true
                            }
                            SSRowDivider()
                            let catCount = vm.budgets.filter { $0.category != nil && $0.period == .monthly }.count
                            SSNavRow(icon: "square.grid.2x2.fill", iconColor: .ssViolet,
                                     label: "Categories & Amounts",
                                     detail: "\(catCount) categories") {
                                showEditBudget = true
                            }
                        }
                        .padding(.horizontal, 20)

                        SSSettingsSection(title: "Security") {
                            SSToggleRow(icon: "faceid", iconColor: .ssAccent,
                                        label: "Face ID / Touch ID",
                                        isOn: $biometricEnabled)
                            SSRowDivider()
                            SSNavRow(icon: "key.fill", iconColor: .ssDanger,
                                     label: "Change Password", detail: "") {
                                showChangePass = true
                            }
                        }
                        .padding(.horizontal, 20)

                        SSSettingsSection(title: "Notifications") {
                            SSToggleRow(icon: "bell.badge.fill", iconColor: .ssWarning,
                                        label: "Push Notifications",
                                        isOn: $pushNotificationsOn)
                            SSRowDivider()
                            SSToggleRow(icon: "exclamationmark.triangle.fill", iconColor: .ssDanger,
                                        label: "Budget Warnings",
                                        isOn: $budgetWarningsOn)
                            if budgetWarningsOn {
                                SSRowDivider()
                                budgetWarningSlider
                            }
                            SSRowDivider()
                            SSToggleRow(icon: "chart.line.uptrend.xyaxis", iconColor: .ssInfo,
                                        label: "Smart Insights (Daily Reports)",
                                        isOn: $smartInsightsOn)
                        }
                        .padding(.horizontal, 20)

                        SSSettingsSection(title: "Accessibility") {
                            currencyRow
                            SSRowDivider()
                            appearanceRow
                            SSRowDivider()
                            textSizeRow
                        }
                        .padding(.horizontal, 20)

                        SSSettingsSection(title: "About") {
                            SSNavRow(icon: "star.fill", iconColor: Color(hex: "#FFD700"),
                                     label: "Rate on App Store", detail: "") {
                                if let url = URL(string: "itms-apps://itunes.apple.com/app/id000000000") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            SSRowDivider()
                            SSNavRow(icon: "envelope.fill", iconColor: .ssInfo,
                                     label: "Contact Support",
                                     detail: "support@spendsense.app") {
                                showMail = true
                            }
                            SSRowDivider()
                            SSNavRow(icon: "doc.text.fill", iconColor: .ssTextSecondary,
                                     label: "Privacy Policy", detail: "") {
                                if let url = URL(string: "https://spendsense.app/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            SSRowDivider()
                            SSInfoRow(icon: "info.circle.fill", iconColor: .ssTextTertiary,
                                      label: "Version", value: appVersion)
                        }
                        .padding(.horizontal, 20)

                        dangerZone
                            .padding(.horizontal, 20)

                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .environment(\.sizeCategory, textSizeCategoryFor(textSizeMultiplier))
            // Sheets
            .sheet(isPresented: $showProfile) {
                ProfileSettingsView().environmentObject(vm)
            }
            .sheet(isPresented: $showWishlist) {
                WishlistSheet().environmentObject(vm)
            }
            .sheet(isPresented: $showSyncBackups) {
                SyncBackupsSheet()
            }
            .sheet(isPresented: $showEditBudget) {
                EditBudgetSheet(
                    monthly: vm.monthlyBudget,
                    categories: vm.budgets.filter { $0.category != nil && $0.period == .monthly }
                ) { newBudget, newCats in
                    upsertBudgets(monthly: newBudget, categories: newCats)
                    showEditBudget = false
                }
            }
            .sheet(isPresented: $showChangePass) {
                ChangePasswordSheet { showChangePass = false }
            }
            .sheet(isPresented: $showMail) {
                MailComposerView(recipient: "support@spendsense.app",
                                 subject: "SpendSense Support")
            }
            // Alerts
            .alert("Log Out?", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    Task { await performLogout() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your data will be synced to the cloud before logging out.")
            }
            .alert("Delete All Data?", isPresented: $showDeleteAlert) {
                Button("Delete Everything", role: .destructive) { performDeleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all transactions, budgets, wishlist, and settings. This action cannot be undone.")
            }
        }
    }


    private var profileHeroCard: some View {
        Button { showProfile = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.ssAccentGradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: .ssAccentGlow, radius: 10, x: 0, y: 4)
                    Text(String(vm.userProfile.name.prefix(1)).uppercased())
                        .font(SSFont.display(26, weight: .bold))
                        .foregroundColor(.black.opacity(0.7))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.userProfile.name.isEmpty ? "Tap to set up profile" : vm.userProfile.name)
                        .font(SSFont.display(18, weight: .bold))
                        .foregroundColor(.ssTextPrimary)
                    Text("SpendSense Member")
                        .font(SSFont.body(13))
                        .foregroundColor(.ssTextSecondary)
                    HStack(spacing: 5) {
                        Image(systemName: vm.currentRiskLevel.icon)
                            .font(.system(size: 11))
                        Text("\(vm.currentRiskLevel.rawValue) Risk · This Month")
                            .font(SSFont.body(12))
                    }
                    .foregroundColor(vm.currentRiskLevel.color)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.ssTextTertiary)
            }
            .padding(18)
            .background(Color.ssSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.ssBorder, lineWidth: colorScheme == .dark ? 0.5 : 1)
            )
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.07),
                radius: colorScheme == .dark ? 0 : 10, x: 0, y: 3
            )
        }
        .buttonStyle(.plain)
    }

    // Budget Warning Slider

    private var budgetWarningSlider: some View {
        let estimatedRemaining = vm.monthlyBudget * (1.0 - budgetWarningPercent / 100.0)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Warn at", systemImage: "bell.fill")
                    .font(SSFont.body(13))
                    .foregroundColor(.ssTextPrimary)
                Spacer()
                Text("\(Int(budgetWarningPercent))%")
                    .font(SSFont.mono(14, weight: .bold))
                    .foregroundColor(.ssAccent)
            }
            Slider(value: $budgetWarningPercent, in: 1...100, step: 1)
                .tint(.ssAccent)
            Text("You'll be notified when \(Int(budgetWarningPercent))% of your budget is used. Estimated remaining at this threshold: **\(vm.formatCurrency(estimatedRemaining))**")
                .font(SSFont.body(11))
                .foregroundColor(.ssTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // Currency Row

    private var currencyRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.ssAccent.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.ssAccent)
            }
            Text("Currency")
                .font(SSFont.body(15))
                .foregroundColor(.ssTextPrimary)
            Spacer()
            Menu {
                ForEach(currencies, id: \.self) { c in
                    Button(c) { selectedCurrency = c }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedCurrency)
                        .font(SSFont.mono(14))
                        .foregroundColor(.ssTextSecondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.ssTextTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    //  Appearance Row

    private var appearanceRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.ssViolet.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: appState.selectedAppearance == .dark
                      ? "moon.stars.fill"
                      : appState.selectedAppearance == .light
                      ? "sun.max.fill"
                      : "circle.lefthalf.filled")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.ssViolet)
            }
            Text("Appearance")
                .font(SSFont.body(15))
                .foregroundColor(.ssTextPrimary)
            Spacer()
            Menu {
                ForEach(AppearanceMode.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            appState.selectedAppearance = mode
                        }
                    } label: {
                        Label(mode.label, systemImage: mode.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(appState.selectedAppearance.label)
                        .font(SSFont.mono(14))
                        .foregroundColor(.ssTextSecondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.ssTextTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    //  Text Size Row

    private var textSizeRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.ssInfo.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "textformat.size")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ssInfo)
                }
                Text("Text Size")
                    .font(SSFont.body(15))
                    .foregroundColor(.ssTextPrimary)
                Spacer()
                Text(textSizeLabel)
                    .font(SSFont.mono(13))
                    .foregroundColor(.ssTextSecondary)
            }
            HStack(spacing: 10) {
                Image(systemName: "textformat.size.smaller")
                    .font(.system(size: 12))
                    .foregroundColor(.ssTextTertiary)
                Slider(value: $textSizeMultiplier, in: 0.8...1.5, step: 0.1)
                    .tint(.ssInfo)
                Image(systemName: "textformat.size.larger")
                    .font(.system(size: 16))
                    .foregroundColor(.ssTextTertiary)
            }
            // Live preview
            Text("Preview: The quick brown fox jumps over the lazy dog.")
                .font(.system(size: previewFontSize))
                .foregroundColor(.ssTextSecondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    //  Danger Zone

    private var dangerZone: some View {
        VStack(spacing: 12) {
            Button { showLogoutAlert = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                    Text("Log Out")
                }
                .font(SSFont.body(15, weight: .semibold))
                .foregroundColor(.ssWarning)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.ssWarning.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.ssWarning.opacity(0.25), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            Button { showDeleteAlert = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash.fill")
                    Text("Delete All Data")
                }
                .font(SSFont.body(15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.ssDanger)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var textSizeLabel: String {
        switch textSizeMultiplier {
        case ..<0.9: return "XS"
        case ..<1.0: return "Small"
        case ..<1.1: return "Default"
        case ..<1.2: return "Medium"
        case ..<1.3: return "Large"
        case ..<1.4: return "XL"
        default:     return "XXL"
        }
    }

    private func textSizeCategoryFor(_ m: Double) -> ContentSizeCategory {
        switch m {
        case ..<0.85: return .small
        case ..<0.95: return .medium
        case ..<1.05: return .large
        case ..<1.15: return .extraLarge
        case ..<1.25: return .extraExtraLarge
        default:      return .extraExtraExtraLarge
        }
    }

    private func upsertBudgets(monthly: Double, categories: [BudgetModel]) {
        if let idx = vm.budgets.firstIndex(where: { $0.category == nil && $0.period == .monthly }) {
            vm.budgets[idx].limit = monthly
        } else {
            vm.budgets.insert(BudgetModel(category: nil, limit: monthly, period: .monthly), at: 0)
        }
        for nb in categories {
            guard let cat = nb.category else { continue }
            if let i = vm.budgets.firstIndex(where: { $0.category == cat && $0.period == .monthly }) {
                vm.budgets[i].limit = nb.limit
            } else {
                vm.budgets.append(BudgetModel(category: cat, limit: nb.limit, period: .monthly))
            }
        }
    }

    private func performLogout() async {
        isSyncing = true
        await vm.syncToFirebaseThenClear()   // sync Core Data → Firebase, then wipe local
        try? FirebaseService.shared.signOut()
        isSyncing = false
        appState.logout()
    }

    private func performDeleteAll() {
        Task {
            isSyncing = true
            vm.deleteAllData()                   // wipe local + Firestore permanently
            try? FirebaseService.shared.signOut()
            isSyncing = false
            appState.logout()
        }
    }
}

//  Reusable Settings Components

struct SSRowDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.ssBorder)
            .padding(.leading, 64)
    }
}

struct SSSettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.ssTextTertiary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(Color.ssSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.ssBorder, lineWidth: scheme == .dark ? 0.5 : 1)
            )
            .shadow(
                color: scheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.06),
                radius: scheme == .dark ? 0 : 8, x: 0, y: 2
            )
        }
    }
}

struct SSNavRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(iconColor)
                }
                Text(label)
                    .font(SSFont.body(15))
                    .foregroundColor(.ssTextPrimary)
                Spacer()
                if !detail.isEmpty {
                    Text(detail)
                        .font(SSFont.body(13))
                        .foregroundColor(.ssTextSecondary)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.ssTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

struct SSToggleRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(iconColor)
            }
            Text(label)
                .font(SSFont.body(15))
                .foregroundColor(.ssTextPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(.ssAccent)
                .scaleEffect(0.9)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SSInfoRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(iconColor)
            }
            Text(label)
                .font(SSFont.body(15))
                .foregroundColor(.ssTextPrimary)
            Spacer()
            Text(value)
                .font(SSFont.mono(13))
                .foregroundColor(.ssTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

//Mail Composer (UIKit bridge)

struct MailComposerView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        guard MFMailComposeViewController.canSendMail() else {
            if let url = URL(string: "mailto:\(recipient)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                UIApplication.shared.open(url)
            }
            let vc = UIViewController()
            DispatchQueue.main.async { self.dismiss() }
            return vc
        }
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setToRecipients([recipient])
        mail.setSubject(subject)
        return mail
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) { dismiss() }
    }
}

// Edit Budget Sheet

struct EditBudgetSheet: View {
    @State var monthly: Double
    @State var categories: [BudgetModel]
    var onSave: (Double, [BudgetModel]) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    var body: some View {
        NavigationView {
            ZStack {
                Color.ssBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // Monthly total card
                        VStack(spacing: 8) {
                            Text("Monthly Budget")
                                .font(SSFont.body(13, weight: .medium))
                                .foregroundColor(.ssTextSecondary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("$")
                                    .font(SSFont.display(24, weight: .bold))
                                    .foregroundColor(.ssAccent)
                                TextField("0", value: $monthly, formatter: NumberFormatter.currencyFormatter)
                                    .font(SSFont.display(38, weight: .bold))
                                    .foregroundColor(.ssTextPrimary)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 220)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.ssSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.ssBorder, lineWidth: scheme == .dark ? 0.5 : 1))
                        .shadow(color: scheme == .dark ? .clear : Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Category budgets
                        SSSettingsSection(title: "Categories") {
                            ForEach($categories) { $cat in
                                if let category = cat.category {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                                .fill(category.color.opacity(0.15))
                                                .frame(width: 34, height: 34)
                                            Image(systemName: category.icon)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(category.color)
                                        }
                                        Text(category.rawValue)
                                            .font(SSFont.body(14))
                                            .foregroundColor(.ssTextPrimary)
                                        Spacer()
                                        HStack(spacing: 2) {
                                            Text("$")
                                                .font(SSFont.mono(13))
                                                .foregroundColor(.ssTextTertiary)
                                            TextField("0", value: $cat.limit,
                                                      formatter: NumberFormatter.currencyFormatter)
                                                .font(SSFont.mono(14, weight: .semibold))
                                                .foregroundColor(.ssTextPrimary)
                                                .keyboardType(.decimalPad)
                                                .multilineTextAlignment(.trailing)
                                                .frame(width: 90)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    if categories.last?.id != cat.id {
                                        SSRowDivider()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.ssTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { onSave(monthly, categories) }
                        .font(SSFont.body(15, weight: .semibold))
                        .foregroundColor(.ssAccent)
                }
            }
        }
    }
}

// Change Password Sheet

struct ChangePasswordSheet: View {
    @State private var current     = ""
    @State private var newPassword = ""
    @State private var confirm     = ""
    @State private var showError   = false
    @State private var errorMsg    = ""
    var onClose: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.ssBackground.ignoresSafeArea()
                VStack(spacing: 22) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(LinearGradient.ssAccentGradient)
                        .padding(.top, 24)

                    SSSettingsSection(title: "Current Password") {
                        SecureField("Enter current password", text: $current)
                            .font(SSFont.body(15))
                            .foregroundColor(.ssTextPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }

                    SSSettingsSection(title: "New Password") {
                        SecureField("New password", text: $newPassword)
                            .font(SSFont.body(15))
                            .foregroundColor(.ssTextPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        SSRowDivider()
                        SecureField("Confirm new password", text: $confirm)
                            .font(SSFont.body(15))
                            .foregroundColor(.ssTextPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }

                    if showError {
                        Text(errorMsg)
                            .font(SSFont.body(13))
                            .foregroundColor(.ssDanger)
                            .padding(.horizontal, 20)
                    }

                    Button {
                        guard !current.isEmpty else { errorMsg = "Enter your current password."; showError = true; return }
                        guard newPassword.count >= 6 else { errorMsg = "New password must be at least 6 characters."; showError = true; return }
                        guard newPassword == confirm else { errorMsg = "Passwords don't match."; showError = true; return }
                        showError = false
                        onClose()
                    } label: {
                        Text("Change Password")
                            .font(SSFont.body(15, weight: .semibold))
                            .foregroundColor(.black.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.ssAccentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.ssTextSecondary)
                }
            }
        }
    }
}

//  NumberFormatter
extension NumberFormatter {
    static var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle           = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
                .environmentObject(SpendSenseViewModel())
                .environmentObject(AppStateViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Settings – Dark")

            SettingsView()
                .environmentObject(SpendSenseViewModel())
                .environmentObject(AppStateViewModel())
                .preferredColorScheme(.light)
                .previewDisplayName("Settings – Light")

            ProfileSettingsView()
                .environmentObject(SpendSenseViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Profile – Dark")

            ProfileSettingsView()
                .environmentObject(SpendSenseViewModel())
                .preferredColorScheme(.light)
                .previewDisplayName("Profile – Light")
        }
    }
}
#endif

//  ProfileSettingsView

struct ProfileSettingsView: View {
    @EnvironmentObject var vm: SpendSenseViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var name: String  = ""
    @State private var email: String = ""
    @State private var monthlyIncome: String = ""
    @State private var savingsGoalPercent: String = ""

    @State private var showSaved     = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.ssBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        avatarSection
                        editSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Personal Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.ssTextSecondary)
                            .padding(8)
                            .background(scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.07))
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveProfile() }
                        .font(SSFont.body(15, weight: .semibold))
                        .foregroundColor(.ssAccent)
                }
            }
            .overlay(alignment: .top) {
                if showSaved {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.ssAccent)
                        Text("Profile saved")
                            .font(SSFont.body(14, weight: .medium))
                            .foregroundColor(.ssTextPrimary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Color.ssSurface)
                    .glassCard()
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                }
            }
            .onAppear {
                name  = vm.userProfile.name
                email = vm.userProfile.email
                monthlyIncome = vm.userProfile.monthlyIncome == 0 ? "" : String(vm.userProfile.monthlyIncome)
                savingsGoalPercent = String(vm.userProfile.savingsGoalPercent)
            }
            .alert("Invalid details", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient.ssAccentGradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: .ssAccentGlow, radius: 16, x: 0, y: 6)
                Text(String(vm.userProfile.name.prefix(1)).uppercased())
                    .font(SSFont.display(36, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
                Circle()
                    .fill(Color.ssSurface)
                    .frame(width: 28, height: 28)
                    .overlay(Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.ssTextSecondary))
                    .overlay(Circle().stroke(Color.ssBorder, lineWidth: 1))
            }
            Text(vm.userProfile.name.isEmpty ? "Your Name" : vm.userProfile.name)
                .font(SSFont.display(22, weight: .bold))
                .foregroundColor(.ssTextPrimary)
            Text("SpendSense Member")
                .font(SSFont.body(13))
                .foregroundColor(.ssTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var editSection: some View {
        SSSettingsSection(title: "Personal Details") {
            ProfileInputRow(icon: "person.fill", iconColor: .ssAccent,
                            label: "Name", placeholder: "Your name", text: $name)
            SSRowDivider()
            ProfileInputRow(icon: "envelope.fill", iconColor: .ssInfo,
                            label: "Email", placeholder: "your@email.com", text: $email, keyboardType: .emailAddress)
            SSRowDivider()
            ProfileInputRow(icon: "banknote.fill", iconColor: .ssSuccess,
                            label: "Monthly Income", placeholder: "0", text: $monthlyIncome, keyboardType: .decimalPad)
            SSRowDivider()
            ProfileInputRow(icon: "target", iconColor: .ssViolet,
                            label: "Savings Goal (%)", placeholder: "20", text: $savingsGoalPercent, keyboardType: .numberPad)
        }
    }

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIncome = monthlyIncome.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGoal = savingsGoalPercent.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = "Name can’t be empty."
            showValidationAlert = true
            return
        }

        guard !trimmedEmail.isEmpty else {
            validationMessage = "Email can’t be empty."
            showValidationAlert = true
            return
        }

        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            validationMessage = "Please enter a valid email address."
            showValidationAlert = true
            return
        }

        var updated = vm.userProfile
        updated.name = trimmedName
        updated.email = trimmedEmail

        if !trimmedIncome.isEmpty {
            let cleanedIncome = trimmedIncome.replacingOccurrences(of: ",", with: "")
            guard let incomeValue = Double(cleanedIncome), incomeValue >= 0 else {
                validationMessage = "Monthly income must be a number greater than or equal to 0."
                showValidationAlert = true
                return
            }
            updated.monthlyIncome = incomeValue
        }

        if !trimmedGoal.isEmpty {
            let cleanedGoal = trimmedGoal.replacingOccurrences(of: "%", with: "")
            guard let goalValue = Double(cleanedGoal), (0.0...100.0).contains(goalValue) else {
                validationMessage = "Savings goal must be between 0 and 100."
                showValidationAlert = true
                return
            }
            updated.savingsGoalPercent = goalValue
        }

        vm.updateUserProfile(updated)
        withAnimation(.spring(response: 0.4)) { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }
}

// Profile Input Row

struct ProfileInputRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    @Environment(\.colorScheme) var scheme

    init(icon: String,
         iconColor: Color,
         label: String,
         placeholder: String,
         text: Binding<String>,
         keyboardType: UIKeyboardType = .default) {
        self.icon = icon
        self.iconColor = iconColor
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(iconColor.opacity(scheme == .dark ? 0.15 : 0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.ssTextTertiary)
                TextField(placeholder, text: $text)
                    .font(SSFont.body(15))
                    .foregroundColor(.ssTextPrimary)
                    .accentColor(.ssAccent)
                    .keyboardType(keyboardType)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// Sync & Backups Sheet

struct SyncBackupsSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme

    var body: some View {
        NavigationView {
            ZStack {
                Color.ssBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(LinearGradient.ssAccentGradient)

                    VStack(spacing: 6) {
                        Text("Sync & Backups")
                            .font(SSFont.display(22, weight: .bold))
                            .foregroundColor(.ssTextPrimary)
                        Text("Your data is backed up automatically.")
                            .font(SSFont.body(14))
                            .foregroundColor(.ssTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        BackupInfoRow(icon: "checkmark.icloud.fill", color: .ssAccent,
                                     title: "Last backup",
                                     value: "Today, \(Date().formatted(date: .omitted, time: .shortened))")
                        BackupInfoRow(icon: "arrow.up.icloud.fill", color: .ssInfo,
                                     title: "Storage used", value: "12 MB")
                        BackupInfoRow(icon: "lock.icloud.fill", color: .ssViolet,
                                     title: "Encryption", value: "AES-256")
                    }
                    .padding()
                    .background(Color.ssSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ssBorder, lineWidth: scheme == .dark ? 0.5 : 1))
                    .shadow(color: scheme == .dark ? .clear : Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)

                    Button { } label: {
                        Label("Backup Now", systemImage: "arrow.up.icloud")
                            .font(SSFont.body(15, weight: .semibold))
                            .foregroundColor(.black.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.ssAccentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
                .padding(.top, 32)
            }
            .navigationTitle("Sync & Backups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.ssAccent)
                }
            }
        }
    }
}

struct BackupInfoRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)
            Text(title)
                .font(SSFont.body(14))
                .foregroundColor(.ssTextSecondary)
            Spacer()
            Text(value)
                .font(SSFont.mono(14))
                .foregroundColor(.ssTextPrimary)
        }
    }
}


