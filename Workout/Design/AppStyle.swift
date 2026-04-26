//
//  AppStyle.swift
//  Workout
//
//  Centralized design tokens for the Workout app.
//

import SwiftUI

/// Central namespace for all design tokens.
/// Usage: AppStyle.Colors.brand, AppStyle.Spacing.md, AppStyle.Radius.card
enum AppStyle {

    // MARK: - Colors

    enum Colors {
        // Surfaces (dark theme)
        static let background = Color(hex: 0x0C0C0E)
        static let surface1 = Color(hex: 0x141416)
        static let surface2 = Color(hex: 0x1C1C1F)
        static let surface3 = Color(hex: 0x252528)

        // Text
        static let text = Color(hex: 0xF0F0F3)
        static let textSecondary = Color(hex: 0x86868F)
        static let textTertiary = Color(hex: 0x55555C)

        // Borders
        static let border = Color.white.opacity(0.07)
        static let borderStrong = Color.white.opacity(0.12)

        // Brand / Accent (dynamic — driven by ThemeManager)
        static var brand: Color { ThemeManager.shared.brandColor }

        // Semantic status
        static let success = Color(hex: 0x34C76A)
        static let error = Color(hex: 0xFF4444)
        static let warning = Color(hex: 0xF5A623)
        static let caution = Color(hex: 0xF5A623)

        // Exercise type badges
        static let compound = Color(hex: 0x50A0FF)
        static let isolation = Color(hex: 0xA070FF)

        // Legacy compatibility aliases
        static let cardBackground = surface1
        static let primaryBackground = background
        static let inactive = Color(.systemGray4)
        static let track = surface3

        // MARK: Tint Helpers

        /// Very subtle tint for status card backgrounds (0.05)
        static func statusTint(_ color: Color) -> Color {
            color.opacity(0.05)
        }

        /// Light tint for row highlights, active states (0.08)
        static func subtleTint(_ color: Color) -> Color {
            color.opacity(0.08)
        }

        /// Standard tint for badges, pills, numbered circles (0.12)
        static func badgeTint(_ color: Color) -> Color {
            color.opacity(0.12)
        }

        /// Ring/stroke background tint (0.2)
        static func ringTrack(_ color: Color) -> Color {
            color.opacity(0.2)
        }
    }

    // MARK: - Accent Themes

    enum AccentTheme: String, CaseIterable {
        case forge
        case carbon
        case pulse

        var name: String {
            switch self {
            case .forge: return "Forge"
            case .carbon: return "Carbon"
            case .pulse: return "Pulse"
            }
        }

        var color: Color {
            switch self {
            case .forge: return Color(hex: 0xFF8C32)
            case .carbon: return Color(hex: 0x50A0FF)
            case .pulse: return Color(hex: 0x32D278)
            }
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum Radius {
        /// Small inner elements (8pt)
        static let small: CGFloat = 8
        /// Medium elements (12pt)
        static let medium: CGFloat = 12
        /// Primary cards, containers (14pt)
        static let card: CGFloat = 14
        /// Large cards, gradient hero cards (16pt)
        static let large: CGFloat = 16
    }

    // MARK: - Icon Sizes

    enum IconSize {
        /// Large hero icons — checkmarks, empty states (48pt)
        static let hero: CGFloat = 48
        /// Extra-large hero — summary screen (56pt)
        static let heroLarge: CGFloat = 56
    }

    // MARK: - Typography

    enum Typography {
        static func mono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        static let largeTitle: Font = .system(size: 26, weight: .heavy)
        static let sectionHeader: Font = .system(size: 11, weight: .semibold)
        static let statValue: Font = .system(size: 28, weight: .black)
    }

    // MARK: - Section Header Style

    /// Uppercase section header style matching the design prototype
    struct SectionHeaderStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.7)
        }
    }

    // MARK: - Shared Color Functions

    /// Color for difficulty level: beginner=green, intermediate=orange, advanced=red
    static func difficultyColor(_ level: DifficultyLevel) -> Color {
        switch level {
        case .beginner: return Colors.success
        case .intermediate: return Colors.warning
        case .advanced: return Colors.error
        }
    }

    /// Color for recovery percentage: green > yellow > orange > red
    static func recoveryColor(_ percentage: Double) -> Color {
        switch percentage {
        case 0.75...1.0: return Colors.success
        case 0.50..<0.75: return Colors.caution
        case 0.25..<0.50: return Colors.warning
        default: return Colors.error
        }
    }

    /// Color for fatigue level: red (high), orange (medium), yellow (low)
    static func fatigueColor(_ fatigue: Double) -> Color {
        switch fatigue {
        case 0.6...1.0: return Colors.error
        case 0.3..<0.6: return Colors.warning
        default: return Colors.caution
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
