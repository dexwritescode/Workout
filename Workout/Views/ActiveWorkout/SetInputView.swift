//
//  SetInputView.swift
//  Workout
//
//  Reusable numeric input with +/- stepper buttons for weight and rep entry.
//

import SwiftUI

struct SetInputView: View {
    let label: String
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let format: String

    init(
        label: String,
        value: Binding<Double>,
        step: Double,
        range: ClosedRange<Double> = 0...999,
        format: String = "%.1f"
    ) {
        self.label = label
        self._value = value
        self.step = step
        self.range = range
        self.format = format
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.7)

            HStack(spacing: 16) {
                Button {
                    let newValue = value - step
                    value = max(range.lowerBound, newValue)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)

                Text(String(format: format, value))
                    .font(AppStyle.Typography.mono(24, weight: .bold))
                    .foregroundStyle(AppStyle.Colors.text)
                    .frame(minWidth: 70)
                    .contentTransition(.numericText())

                Button {
                    let newValue = value + step
                    value = min(range.upperBound, newValue)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppStyle.Colors.brand)
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
            }
        }
        .padding()
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        SetInputView(label: "Weight (kg)", value: .constant(80.0), step: 2.5)
        SetInputView(label: "Reps", value: .constant(10.0), step: 1, range: 0...100, format: "%.0f")
    }
    .padding()
    .background(AppStyle.Colors.background)
}
