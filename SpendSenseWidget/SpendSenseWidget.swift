//
//  SpendSenseWidget.swift
//  SpendSenseWidget
//
//  Created by Yulani Alwis on 2026-04-15.
//

import WidgetKit
import SwiftUI

// Color Palette (mirrors Theme.swift)

extension Color {
    static let wBackground      = Color(hex_w: "#0A0E1A")
    static let wSurface         = Color(hex_w: "#111827")
    static let wSurfaceElevated = Color(hex_w: "#1C2535")
    static let wBorder          = Color(hex_w: "#2A3448")
    static let wTextPrimary     = Color(hex_w: "#F0F4FF")
    static let wTextSecondary   = Color(hex_w: "#8A95B0")
    static let wTextTertiary    = Color(hex_w: "#4A5568")
    static let wAccent          = Color(hex_w: "#00E5B0")
    static let wViolet          = Color(hex_w: "#7C6FFF")
    static let wWarning         = Color(hex_w: "#FFB830")
    static let wDanger          = Color(hex_w: "#FF4D6D")

    init(hex_w: String) {
        let hex = hex_w.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255, int>>16, int>>8 & 0xFF, int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24, int>>16 & 0xFF, int>>8 & 0xFF, int & 0xFF)
        default: (a,r,g,b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// Widget Data Snapshot

struct SpendSenseEntry: TimelineEntry {
    let date: Date
    let todaySpent: Double
    let monthlySpent: Double
    let monthlyBudget: Double
    let dailyBudget: Double
    let remainingDaily: Double
    let riskLevel: String
    let lastCategory: String
    let userName: String

    var dailyProgress: Double {
        guard dailyBudget > 0 else { return 0 }
        return min(todaySpent / dailyBudget, 1.0)
    }

    var monthlyProgress: Double {
        guard monthlyBudget > 0 else { return 0 }
        return min(monthlySpent / monthlyBudget, 1.0)
    }

    var riskColor: Color {
        switch riskLevel {
        case "High":     return .wDanger
        case "Moderate": return .wWarning
        default:         return .wAccent
        }
    }

    var riskIcon: String {
        switch riskLevel {
        case "High":     return "xmark.octagon.fill"
        case "Moderate": return "exclamationmark.triangle.fill"
        default:         return "checkmark.shield.fill"
        }
    }

    static var placeholder: SpendSenseEntry {
        SpendSenseEntry(date: .now, todaySpent: 850, monthlySpent: 24500,
                        monthlyBudget: 60000, dailyBudget: 2000,
                        remainingDaily: 1150, riskLevel: "Low",
                        lastCategory: "Food & Dining", userName: "Spender")
    }
}

//  Timeline Provider

struct SpendSenseProvider: TimelineProvider {

    func placeholder(in context: Context) -> SpendSenseEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendSenseEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendSenseEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh every 30 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> SpendSenseEntry {
        let d = UserDefaults(suiteName: "group.com.spendsense.app") ?? .standard
        return SpendSenseEntry(
            date:           Date(),
            todaySpent:     d.double(forKey: "widget_todaySpent"),
            monthlySpent:   d.double(forKey: "widget_monthlySpent"),
            monthlyBudget:  d.double(forKey: "widget_monthlyBudget"),
            dailyBudget:    d.double(forKey: "widget_dailyBudget"),
            remainingDaily: d.double(forKey: "widget_remainingDaily"),
            riskLevel:      d.string(forKey: "widget_riskLevel") ?? "Low",
            lastCategory:   d.string(forKey: "widget_lastCategory") ?? "--",
            userName:       d.string(forKey: "widget_userName") ?? ""
        )
    }
}

// Currency Formatter

private func fmtCurrency(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencySymbol = "Rs."
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: v)) ?? "Rs.\(Int(v))"
}

// Small Widget View

struct SmallWidgetView: View {
    let entry: SpendSenseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // App branding
            HStack(spacing: 5) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.wAccent)
                Text("SpendSense")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.wTextSecondary)
                Spacer()
            }

            Spacer()

            // "Available Today" amount
            Text("Available Today")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.wTextSecondary)

            Text(fmtCurrency(max(0, entry.remainingDaily)))
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(entry.remainingDaily > 0 ? .wAccent : .wDanger)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.wBorder)
                        .frame(height: 5)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [entry.riskColor, entry.riskColor.opacity(0.6)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * entry.dailyProgress, height: 5)
                }
            }
            .frame(height: 5)

            // Risk badge
            HStack(spacing: 4) {
                Image(systemName: entry.riskIcon)
                    .font(.system(size: 9))
                Text("\(entry.riskLevel) Risk")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(entry.riskColor)
        }
        .padding(14)
    }
}

// Medium Widget View

struct MediumWidgetView: View {
    let entry: SpendSenseEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side – Daily budget ring
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.wBorder, lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: entry.dailyProgress)
                        .stroke(
                            LinearGradient(
                                colors: [entry.riskColor, entry.riskColor.opacity(0.5)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 1) {
                        Text("\(Int(entry.dailyProgress * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.wTextPrimary)
                        Text("spent")
                            .font(.system(size: 9))
                            .foregroundColor(.wTextSecondary)
                    }
                }

                // Risk badge
                HStack(spacing: 3) {
                    Image(systemName: entry.riskIcon)
                        .font(.system(size: 9))
                    Text(entry.riskLevel)
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(entry.riskColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(entry.riskColor.opacity(0.15))
                .cornerRadius(10)
            }

            // Right side – Stats
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 5) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.wAccent)
                    Text("SpendSense")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.wTextSecondary)
                    Spacer()
                }

                // Available today
                VStack(alignment: .leading, spacing: 2) {
                    Text("Available Today")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.wTextSecondary)
                    Text(fmtCurrency(max(0, entry.remainingDaily)))
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(entry.remainingDaily > 0 ? .wAccent : .wDanger)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                Divider().background(Color.wBorder)

                // Monthly & Today row
                HStack(spacing: 16) {
                    StatPill(label: "Today", value: fmtCurrency(entry.todaySpent),
                             icon: "sun.max.fill", color: .wWarning)
                    StatPill(label: "Monthly", value: "\(Int(entry.monthlyProgress * 100))%",
                             icon: "calendar", color: entry.riskColor)
                }
            }
        }
        .padding(14)
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.wTextSecondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.wTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

// Widget Definition

struct SpendSenseWidget: Widget {
    let kind: String = "SpendSenseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendSenseProvider()) { entry in
            Group {
                if #available(iOSApplicationExtension 17.0, *) {
                    WidgetContent(entry: entry)
                        .containerBackground(for: .widget) {
                            Color.wBackground
                        }
                } else {
                    WidgetContent(entry: entry)
                        .background(Color.wBackground)
                }
            }
        }
        .configurationDisplayName("Daily Budget")
        .description("See how much you can spend today at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetContent: View {
    @Environment(\.widgetFamily) var family
    let entry: SpendSenseEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// Previews

#Preview("Small", as: .systemSmall) {
    SpendSenseWidget()
} timeline: {
    SpendSenseEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    SpendSenseWidget()
} timeline: {
    SpendSenseEntry.placeholder
}
