//
//  ViewModifiers.swift
//  Workout
//
//  Reusable ViewModifiers and View extensions for common UI patterns.
//

import SwiftUI

// MARK: - Card Style

/// Dark surface card: surface1 background + border + cornerRadius 14
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
    }
}

/// Status-tinted card: color.opacity(0.05) + cornerRadius 14
struct StatusCardModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .background(AppStyle.Colors.statusTint(color))
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
    }
}

// MARK: - Badge Pill

/// Capsule-shaped colored tag: tinted background + foreground color
struct BadgePillModifier: ViewModifier {
    let color: Color
    let font: Font

    func body(content: Content) -> some View {
        content
            .font(font)
            .padding(.horizontal, AppStyle.Spacing.sm)
            .padding(.vertical, AppStyle.Spacing.xs)
            .background(AppStyle.Colors.badgeTint(color))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Numbered Circle

/// Small circle with a number inside, used for step indicators
struct NumberedCircleModifier: ViewModifier {
    let color: Color
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.caption.bold())
            .frame(width: size, height: size)
            .background(AppStyle.Colors.badgeTint(color))
            .foregroundStyle(color)
            .clipShape(Circle())
    }
}

// MARK: - Dark Screen Background

struct DarkBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppStyle.Colors.background)
    }
}

// MARK: - Section Header

struct SectionHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppStyle.Colors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.7)
    }
}

// MARK: - View Extensions

extension View {
    /// Standard card background (surface1 + border + rounded 14)
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    /// Status-tinted card background (color.opacity(0.05) + rounded 14)
    func statusCardStyle(color: Color) -> some View {
        modifier(StatusCardModifier(color: color))
    }

    /// Capsule-shaped colored pill badge
    func badgePill(color: Color, font: Font = .caption) -> some View {
        modifier(BadgePillModifier(color: color, font: font))
    }

    /// Numbered circle indicator for steps/lists
    func numberedCircle(color: Color = AppStyle.Colors.brand, size: CGFloat = 24) -> some View {
        modifier(NumberedCircleModifier(color: color, size: size))
    }

    /// Dark screen background
    func darkBackground() -> some View {
        modifier(DarkBackgroundModifier())
    }

    /// Uppercase section header style
    func sectionHeader() -> some View {
        modifier(SectionHeaderModifier())
    }
}
