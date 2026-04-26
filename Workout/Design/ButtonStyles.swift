//
//  ButtonStyles.swift
//  Workout
//
//  Shared button styles for the Workout app.
//

import SwiftUI

// MARK: - Scale Button Style

/// Primary CTA button style with subtle scale-down effect on press.
struct ScaleButtonStyle: ButtonStyle {
    var color: Color = AppStyle.Colors.brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Primary Action Button Style

/// Full-width CTA: accent background, 52pt height, rounded 14, glow shadow
struct PrimaryActionButtonStyle: ButtonStyle {
    var color: Color = AppStyle.Colors.brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .shadow(color: color.opacity(0.35), radius: 12, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

/// Bordered button: transparent background, border, accent text
struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = AppStyle.Colors.brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppStyle.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
