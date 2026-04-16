//
//  SpendSenseWidget.swift
//  SpendSenseWidget
//
//  Created by Yulani Alwis on 2026-04-15.
//
import WidgetKit
import SwiftUI

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
    static let wSuccess         = Color(hex_w: "#22C55E")

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
                  blue:  Double(b)/255, opacity: Double(a)/255)
    }
}

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
    let monthlyIncome: Double
    let todayIncome: Double

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

    var hasData: Bool { monthlyBudget > 0 || todaySpent > 0 }

    static var placeholder: SpendSenseEntry {
        SpendSenseEntry(date: .now, todaySpent: 850, monthlySpent: 24500,
                        monthlyBudget: 60000, dailyBudget: 2000,
                        remainingDaily: 1150, riskLevel: "Low",
                        lastCategory: "Food & Dining", userName: "Spender",
                        monthlyIncome: 5000, todayIncome: 0)
    }
}

struct SpendSenseProvider: TimelineProvider {

    func placeholder(in context: Context) -> SpendSenseEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (SpendSenseEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendSenseEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> SpendSenseEntry {
        let d = WidgetDataStore.defaults
        return SpendSenseEntry(
            date:           Date(),
            todaySpent:     d.double(forKey: "widget_todaySpent"),
            monthlySpent:   d.double(forKey: "widget_monthlySpent"),
            monthlyBudget:  d.double(forKey: "widget_monthlyBudget"),
            dailyBudget:    d.double(forKey: "widget_dailyBudget"),
            remainingDaily: d.double(forKey: "widget_remainingDaily"),
            riskLevel:      d.string(forKey: "widget_riskLevel") ?? "Low",
            lastCategory:   d.string(forKey: "widget_lastCategory") ?? "--",
            userName:       d.string(forKey: "widget_userName") ?? "",
            monthlyIncome:  d.double(forKey: "widget_monthlyIncome"),
            todayIncome:    d.double(forKey: "widget_todayIncome")
        )
    }
}

private func fmt(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencySymbol = "Rs."
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: v)) ?? "Rs.\(Int(v))"
}

struct SmallWidgetView: View {
    let entry: SpendSenseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.wAccent)
                Text("SpendSense")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.wTextSecondary)
                Spacer()
                Image(systemName: entry.riskIcon)
                    .font(.system(size: 10))
                    .foregroundColor(entry.riskColor)
            }

            Spacer()

            Text("Available Today")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.wTextSecondary)

            Text(fmt(max(0, entry.remainingDaily)))
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(entry.remainingDaily > 0 ? .wAccent : .wDanger)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.wBorder).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [entry.riskColor, entry.riskColor.opacity(0.6)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * entry.dailyProgress, height: 5)
                }
            }
            .frame(height: 5)

            HStack(spacing: 4) {
                Image(systemName: entry.riskIcon).font(.system(size: 9))
                Text("\(entry.riskLevel) Risk").font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(entry.riskColor)
        }
        .padding(14)
    }
}

struct MediumWidgetView: View {
    let entry: SpendSenseEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().stroke(Color.wBorder, lineWidth: 8).frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: entry.dailyProgress)
                        .stroke(
                            LinearGradient(colors: [entry.riskColor, entry.riskColor.opacity(0.5)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text("\(Int(entry.dailyProgress * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.wTextPrimary)
                        Text("used")
                            .font(.system(size: 9))
                            .foregroundColor(.wTextSecondary)
                    }
                }

                HStack(spacing: 3) {
                    Image(systemName: entry.riskIcon).font(.system(size: 9))
                    Text(entry.riskLevel).font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(entry.riskColor)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(entry.riskColor.opacity(0.15)).cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.wAccent)
                    Text("SpendSense")
                        .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(.wTextSecondary)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Available Today")
                        .font(.system(size: 10, weight: .medium)).foregroundColor(.wTextSecondary)
                    Text(fmt(max(0, entry.remainingDaily)))
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(entry.remainingDaily > 0 ? .wAccent : .wDanger)
                        .lineLimit(1).minimumScaleFactor(0.6)
                }

                Divider().background(Color.wBorder)

                HStack(spacing: 16) {
                    StatPill(label: "Today",   value: fmt(entry.todaySpent),
                             icon: "sun.max.fill",  color: .wWarning)
                    StatPill(label: "Monthly", value: "\(Int(entry.monthlyProgress * 100))%",
                             icon: "calendar",       color: entry.riskColor)

                    if entry.todayIncome > 0 {
                        StatPill(label: "Income",  value: fmt(entry.todayIncome),
                                 icon: "banknote",  color: .wSuccess)
                    }
                }
            }
        }
        .padding(14)
    }
}

struct LargeWidgetView: View {
    let entry: SpendSenseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.wAccent)
                    Text("SpendSense")
                        .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.wTextPrimary)
                }
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: entry.riskIcon).font(.system(size: 12))
                    Text("\(entry.riskLevel) Risk").font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(entry.riskColor)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(entry.riskColor.opacity(0.15)).cornerRadius(12)
            }

            Divider().background(Color.wBorder)

            VStack(alignment: .leading, spacing: 4) {
                Text("Available Today")
                    .font(.system(size: 11, weight: .medium)).foregroundColor(.wTextSecondary)
                Text(fmt(max(0, entry.remainingDaily)))
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(entry.remainingDaily > 0 ? .wAccent : .wDanger)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }

            VStack(spacing: 6) {
                progressRow(label: "Daily", progress: entry.dailyProgress,
                            spent: entry.todaySpent, budget: entry.dailyBudget,
                            color: entry.riskColor)
                progressRow(label: "Monthly", progress: entry.monthlyProgress,
                            spent: entry.monthlySpent, budget: entry.monthlyBudget,
                            color: entry.riskColor)
            }

            Divider().background(Color.wBorder)

            HStack(spacing: 0) {
                bigStat(label: "Today", value: fmt(entry.todaySpent), color: .wWarning)
                Spacer()
                bigStat(label: "Monthly", value: fmt(entry.monthlySpent), color: entry.riskColor)
                Spacer()
                bigStat(label: "Remaining", value: fmt(max(0, entry.monthlyBudget - entry.monthlySpent)),
                        color: .wAccent)
                if entry.monthlyIncome > 0 {
                    Spacer()
                    bigStat(label: "Income", value: fmt(entry.monthlyIncome), color: .wSuccess)
                }
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 10)).foregroundColor(.wTextTertiary)
                Text("Last: \(entry.lastCategory)")
                    .font(.system(size: 10)).foregroundColor(.wTextTertiary)
                Spacer()
                Text(entry.date.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.wTextTertiary)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private func progressRow(label: String, progress: Double,
                              spent: Double, budget: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(.wTextSecondary)
                Spacer()
                Text("\(Int(progress * 100))% · \(fmt(spent)) of \(fmt(budget))")
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.wTextTertiary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.wBorder).frame(height: 6)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [color, color.opacity(0.5)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    @ViewBuilder
    private func bigStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 10)).foregroundColor(.wTextSecondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

struct StatPill: View {
    let label: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 9, weight: .semibold)).foregroundColor(color)
                Text(label).font(.system(size: 9)).foregroundColor(.wTextSecondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.wTextPrimary).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

struct SpendSenseWidget: Widget {
    let kind: String = "SpendSenseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendSenseProvider()) { entry in
            Group {
                if #available(iOSApplicationExtension 17.0, *) {
                    WidgetContent(entry: entry)
                        .containerBackground(for: .widget) { Color.wBackground }
                } else {
                    WidgetContent(entry: entry)
                        .background(Color.wBackground)
                }
            }
        }
        .configurationDisplayName("SpendSense Budget")
        .description("Track your daily and monthly spending at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct WidgetContent: View {
    @Environment(\.widgetFamily) var family
    let entry: SpendSenseEntry

    var body: some View {
        Group {
            if !entry.hasData {
                emptyState
            } else {
                switch family {
                case .systemLarge:  LargeWidgetView(entry: entry)
                case .systemMedium: MediumWidgetView(entry: entry)
                default:            SmallWidgetView(entry: entry)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.wAccent)
            Text("Open SpendSense\nto get started")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.wTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

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

#Preview("Large", as: .systemLarge) {
    SpendSenseWidget()
} timeline: {
    SpendSenseEntry.placeholder
}
