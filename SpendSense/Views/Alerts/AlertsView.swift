//
//  AlertsView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-10.
//
import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var vm: SpendSenseViewModel

    var body: some View {
        NavigationView {
            Group {
                if vm.alerts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.ssTextTertiary)
                        Text("No alerts yet")
                            .font(SSFont.display(18, weight: .bold))
                            .foregroundColor(.ssTextSecondary)
                        Text("We'll notify you when something needs\nyour attention.")
                            .font(SSFont.body(14))
                            .foregroundColor(.ssTextTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.ssBackground)
                } else {
                    List {
                        ForEach(vm.alerts) { alert in
                            AlertRow(alert: alert)
                                .onTapGesture { vm.markAlertRead(alert.id) }
                                .listRowBackground(Color.ssSurface)
                                .listRowSeparatorTint(Color.ssBorder)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.ssBackground)
                }
            }
            .background(Color.ssBackground)
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if vm.unreadAlertsCount > 0 {
                        Button("Mark all read") {
                            for alert in vm.alerts {
                                vm.markAlertRead(alert.id)
                            }
                        }
                        .font(SSFont.body(13))
                        .foregroundColor(.ssAccent)
                    }
                }
            }
        }
    }
}

// Alert Row
struct AlertRow: View {
    var alert: AlertItemModel

    var timeAgo: String {
        let diff = Date().timeIntervalSince(alert.date)
        if diff < 60 { return "Just now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Unread dot
            Circle()
                .fill(alert.isRead ? Color.clear : alert.type.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            // Icon
            ZStack {
                Circle()
                    .fill(alert.type.color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: alert.type.icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(alert.type.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(alert.title)
                        .font(SSFont.body(14, weight: alert.isRead ? .regular : .semibold))
                        .foregroundColor(.ssTextPrimary)
                    Spacer()
                    Text(timeAgo)
                        .font(SSFont.body(11))
                        .foregroundColor(.ssTextTertiary)
                }
                Text(alert.message)
                    .font(SSFont.body(13))
                    .foregroundColor(.ssTextSecondary)
                    .lineSpacing(3)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(alert.isRead ? Color.ssSurface : Color.ssSurfaceElevated)
    }
}

#if DEBUG
struct AlertsView_Previews: PreviewProvider {
    static var previews: some View {
        AlertsView()
            .environmentObject(SpendSenseViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif
