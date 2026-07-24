// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ViewModifiers.swift
//  Workout
//
//  Reusable ViewModifiers and View extensions for common UI patterns.
//

import SwiftUI

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

// MARK: - Set Value Field

struct SetValueFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppStyle.Typography.mono(16, weight: .semibold))
            .foregroundStyle(AppStyle.Colors.text)
            .multilineTextAlignment(.center)
            .frame(height: 44)
            .background(AppStyle.Colors.surface2)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.small)
                    .stroke(AppStyle.Colors.brand.opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Uppercase section header style
    func sectionHeader() -> some View {
        modifier(SectionHeaderModifier())
    }

    /// Canonical chrome for a weight/reps set-value box (tracking + template editing screens):
    /// mono font, bordered surface, consistent corner radius and tap-target height. Width is left
    /// to the caller since flexible vs. fixed-width layouts differ between screens.
    func setValueFieldStyle() -> some View {
        modifier(SetValueFieldModifier())
    }
}
