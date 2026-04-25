//
//  SpendSenseWidgetLiveActivity.swift
//  SpendSenseWidget
//
//  Created by Yulani Alwis on 2026-04-15.
//
//
//  SpendSenseWidgetLiveActivity.swift
//  SpendSenseWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

// Activity Attributes

// Defines the static and dynamic data for the SpendSense Live Activity.
struct SpendSenseActivityAttributes: ActivityAttributes {

    // Non-changing data set when the activity is started.
    public struct ContentState: Codable, Hashable {
        // Budget remaining for today (dynamic — updates on every transaction).
        var remainingBudget: Double
        // The user's total daily budget limit (used to compute progress).
        var dailyBudget: Double
        // Raw risk level string: "Low", "Moderate", or "High".
        var riskLevel: String
        // Amount spent today.
        var spentToday: Double

        // MARK: Derived helpers (not stored — computed from the above)

        var progress: Double {
            guard dailyBudget > 0 else { return 0 }
            return min(spentToday / dailyBudget, 1.0)
        }

        var riskColor: Color {
            switch riskLevel {
            case "High":     return Color(hex_la: "#FF4D6D")
            case "Moderate": return Color(hex_la: "#FFB830")
            default:         return Color(hex_la: "#00E5B0")
            }
        }

        var riskIcon: String {
            switch riskLevel {
            case "High":     return "xmark.octagon.fill"
            case "Moderate": return "exclamationmark.triangle.fill"
            default:         return "checkmark.shield.fill"
            }
        }
    }

    // The user's display name — fixed for the lifetime of the activity.
    var userName: String
}

//Hex colour helper (widget-scoped to avoid clashing with the main app)

private extension Color {
    init(hex_la: String) {
        let hex = hex_la.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// Currency formatter

private func formatCurrency(_ value: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencySymbol = "Rs."
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: value)) ?? "Rs.\(Int(value))"
}

//Live Activity Widget

struct SpendSenseWidgetLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpendSenseActivityAttributes.self) { context in

    
            lockScreenView(context: context)
                .activityBackgroundTint(Color(hex_la: "#0A0E1A"))
                .activitySystemActionForegroundColor(Color(hex_la: "#00E5B0"))

        } dynamicIsland: { context in

            // Dynamic Island
       
            DynamicIsland {

                // Expanded view (long-press)
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(formatCurrency(context.state.remainingBudget))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } icon: {
                        Image(systemName: "wallet.pass.fill")
                            .foregroundColor(Color(hex_la: "#00E5B0"))
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text(context.state.riskLevel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(context.state.riskColor)
                    } icon: {
                        Image(systemName: context.state.riskIcon)
                            .foregroundColor(context.state.riskColor)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(context.state.riskColor)
                                    .frame(width: geo.size.width * context.state.progress, height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("Spent: \(formatCurrency(context.state.spentToday))")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("Budget: \(formatCurrency(context.state.dailyBudget))")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 4)
                }

            } compactLeading: {
                // Compact leading: wallet icon + remaining amount
                Label {
                    Text(formatCurrency(context.state.remainingBudget))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "wallet.pass.fill")
                        .foregroundColor(Color(hex_la: "#00E5B0"))
                }

            } compactTrailing: {
                // Compact trailing: risk icon coloured by level
                Image(systemName: context.state.riskIcon)
                    .foregroundColor(context.state.riskColor)
                    .font(.system(size: 13))

            } minimal: {
                // Minimal (when two activities compete): just the risk icon
                Image(systemName: context.state.riskIcon)
                    .foregroundColor(context.state.riskColor)
            }
            .widgetURL(URL(string: "spendsense://home"))
            .keylineTint(Color(hex_la: "#00E5B0"))
        }
    }

    // Lock-screen banner

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<SpendSenseActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            // Left: icon + risk indicator
            ZStack {
                Circle()
                    .fill(context.state.riskColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: context.state.riskIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(context.state.riskColor)
            }

            // Centre: amounts + progress bar
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatCurrency(context.state.remainingBudget))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("left today")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(context.state.riskColor)
                            .frame(width: geo.size.width * context.state.progress, height: 5)
                    }
                }
                .frame(height: 5)

                Text("Spent \(formatCurrency(context.state.spentToday)) of \(formatCurrency(context.state.dailyBudget))")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            // Right: user initials badge
            Text(String(context.attributes.userName.prefix(1)).uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

//Previews

extension SpendSenseActivityAttributes {
    fileprivate static var preview: SpendSenseActivityAttributes {
        SpendSenseActivityAttributes(userName: "Yulani")
    }
}

extension SpendSenseActivityAttributes.ContentState {
    fileprivate static var low: SpendSenseActivityAttributes.ContentState {
        .init(remainingBudget: 3200, dailyBudget: 4000, riskLevel: "Low", spentToday: 800)
    }
    fileprivate static var moderate: SpendSenseActivityAttributes.ContentState {
        .init(remainingBudget: 700, dailyBudget: 4000, riskLevel: "Moderate", spentToday: 3300)
    }
    fileprivate static var high: SpendSenseActivityAttributes.ContentState {
        .init(remainingBudget: 0, dailyBudget: 4000, riskLevel: "High", spentToday: 4200)
    }
}

#Preview("Lock Screen — Low",     as: .content,            using: SpendSenseActivityAttributes.preview) { SpendSenseWidgetLiveActivity() } contentStates: { SpendSenseActivityAttributes.ContentState.low }
#Preview("Lock Screen — Moderate", as: .content,            using: SpendSenseActivityAttributes.preview) { SpendSenseWidgetLiveActivity() } contentStates: { SpendSenseActivityAttributes.ContentState.moderate }
#Preview("Lock Screen — High",     as: .content,            using: SpendSenseActivityAttributes.preview) { SpendSenseWidgetLiveActivity() } contentStates: { SpendSenseActivityAttributes.ContentState.high }
#Preview("Dynamic Island",         as: .dynamicIsland(.expanded), using: SpendSenseActivityAttributes.preview) { SpendSenseWidgetLiveActivity() } contentStates: { SpendSenseActivityAttributes.ContentState.moderate }
