//
//  TransactionsView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-15.
//
import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var vm: SpendSenseViewModel
    @State private var searchText = ""
    @State private var selectedCategory: SpendingCategory? = nil
    @State private var selectedTransaction: TransactionModel? = nil

    var filtered: [TransactionModel] {
        vm.transactions.filter { t in
            let matchesSearch = searchText.isEmpty ||
                t.note.localizedCaseInsensitiveContains(searchText) ||
                t.category.rawValue.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || t.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var totalFiltered: Double { filtered.reduce(0) { $0 + $1.amount } }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.ssTextTertiary)
                TextField("Search transactions...", text: $searchText)
                    .font(SSFont.body(15))
                    .foregroundColor(.ssTextPrimary)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.ssTextTertiary)
                    }
                }
            }
            .padding(12)
            .background(Color.ssSurfaceElevated)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ssBorder, lineWidth: 1))
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Spacer().frame(width: 12)
                    FilterChip(label: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(SpendingCategory.allCases) { cat in
                        FilterChip(
                            label: cat.rawValue.components(separatedBy: " ").first ?? "",
                            icon: cat.icon,
                            color: cat.color,
                            isSelected: selectedCategory == cat
                        ) {
                            selectedCategory = selectedCategory == cat ? nil : cat
                        }
                    }
                    Spacer().frame(width: 12)
                }
            }
            .padding(.bottom, 8)

            // Summary
            HStack {
                Text("\(filtered.count) transaction\(filtered.count == 1 ? "" : "s")")
                    .font(SSFont.body(13))
                    .foregroundColor(.ssTextSecondary)
                Spacer()
                Text("Total: \(vm.formatCurrency(totalFiltered))")
                    .font(SSFont.mono(13, weight: .semibold))
                    .foregroundColor(.ssDanger)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            Divider().background(Color.ssBorder)

            // List
            if filtered.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.ssTextTertiary)
                    Text("No transactions found")
                        .font(SSFont.display(16, weight: .semibold))
                        .foregroundColor(.ssTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedTransactions, id: \.0) { (dateKey, transactions) in
                        Section {
                            ForEach(transactions) { t in
                                TransactionRow(transaction: t, vm: vm)
                                    .listRowBackground(Color.ssSurface)
                                    .listRowSeparatorTint(Color.ssBorder)
                                    .listRowInsets(EdgeInsets())
                            }
                        } header: {
                            Text(dateKey)
                                .font(SSFont.body(12, weight: .semibold))
                                .foregroundColor(.ssTextTertiary)
                                .textCase(nil)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.ssBackground)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.ssBackground)
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
    }

    var groupedTransactions: [(String, [TransactionModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filtered) { t -> String in
            if calendar.isDateInToday(t.date) { return "Today" }
            if calendar.isDateInYesterday(t.date) { return "Yesterday" }
            return t.date.formatted(.dateTime.day().month(.wide).year())
        }
        return grouped.sorted { a, b in
            // Sort by date descending
            let aDate = a.1.first?.date ?? Date.distantPast
            let bDate = b.1.first?.date ?? Date.distantPast
            return aDate > bDate
        }
    }
}

// Filter Chip
struct FilterChip: View {
    var label: String
    var icon: String? = nil
    var color: Color = .ssAccent
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(SSFont.body(12, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .ssBackground : .ssTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? (icon != nil ? color.cornerRadius(20) : Color.ssAccent.cornerRadius(20))
                    : Color.ssSurfaceElevated.cornerRadius(20)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#if DEBUG
struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
            .environmentObject(SpendSenseViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif
