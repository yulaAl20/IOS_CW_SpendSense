//
//  Theme.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-02.
//
import SwiftUI

//SpendSense Adaptive Color Palette (Light + Dark)
extension Color {
    // Backgrounds – auto-adapt to color scheme
    static let ssBackground      = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "#0A0E1A"))
            : UIColor(Color(hex: "#F2F4F8")) })

    static let ssSurface         = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "#111827"))
            : UIColor(Color(hex: "#FFFFFF")) })

    static let ssSurfaceElevated = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "#1C2535"))
            : UIColor(Color(hex: "#FFFFFF")) })

    static let ssBorder          = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "#2A3448"))
            : UIColor(Color(hex: "#DDE2EE")) })

    // Text – adaptive
    static let ssTextPrimary     = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "#F0F4FF"))
            : UIColor(Color(hex: "#0D1526")) })

    static let ssTextSecondary   = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "#8A95B0"))
            : UIColor(Color(hex: "#5A6480")) })

    static let ssTextTertiary    = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "#4A5568"))
            : UIColor(Color(hex: "#9AA3B8")) })

    // Accent (same both modes)
    static let ssAccent          = Color(hex: "#00E5B0")
    static let ssAccentDim       = Color(hex: "#00E5B0").opacity(0.15)
    static let ssAccentGlow      = Color(hex: "#00E5B0").opacity(0.4)

    // Secondary accent
    static let ssViolet          = Color(hex: "#7C6FFF")
    static let ssVioletDim       = Color(hex: "#7C6FFF").opacity(0.15)

    // Status
    static let ssSuccess         = Color(hex: "#00E5B0")
    static let ssWarning         = Color(hex: "#FFB830")
    static let ssDanger          = Color(hex: "#FF4D6D")
    static let ssInfo            = Color(hex: "#4DA6FF")
}

// MARK: - Hex Color Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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

// Typography
struct SSFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func scaled(_ base: CGFloat, multiplier: CGFloat) -> CGFloat {
        base * multiplier
    }
}

//  Gradient Presets
extension LinearGradient {
    static let ssAccentGradient = LinearGradient(
        colors: [Color(hex: "#00E5B0"), Color(hex: "#00B8FF")],
        startPoint: .leading, endPoint: .trailing)
    static let ssDangerGradient = LinearGradient(
        colors: [Color(hex: "#FF4D6D"), Color(hex: "#FF8C42")],
        startPoint: .leading, endPoint: .trailing)
    static let ssWarningGradient = LinearGradient(
        colors: [Color(hex: "#FFB830"), Color(hex: "#FF8C42")],
        startPoint: .leading, endPoint: .trailing)
    static let ssCardGradient = LinearGradient(
        colors: [Color(hex: "#1C2535"), Color(hex: "#111827")],
        startPoint: .topLeading, endPoint: .bottomTrailing)
    static let ssHeroGradient = LinearGradient(
        colors: [Color(hex: "#0A0E1A"), Color(hex: "#0D1526"), Color(hex: "#0A0E1A")],
        startPoint: .top, endPoint: .bottom)
}

// iOS 26 Glass Card Modifier
struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) var scheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(scheme == .dark
                          ? Color.white.opacity(0.06)
                          : Color.white.opacity(0.80))
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.ssSurface)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        scheme == .dark
                            ? Color.white.opacity(0.10)
                            : Color.black.opacity(0.06),
                        lineWidth: 0.5)
            )
            .shadow(color: scheme == .dark
                    ? Color.black.opacity(0.4)
                    : Color.black.opacity(0.08),
                    radius: 12, x: 0, y: 4)
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}
