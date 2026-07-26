// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  RestTimePickerField.swift
//  Workout
//
//  Shared rest-time control: a tappable field that presents a native wheel picker in a popover
//  anchored to the field, instead of a fixed-preset menu Picker or a permanently-inline wheel.
//  POC — exact sizing/placement is expected to be tuned after on-device iteration.
//

import SwiftUI

struct RestTimePickerField: View {
    @Binding var seconds: Int

    /// Non-nil enables "inherit global default" behavior: `seconds == 0` displays this value with
    /// a "Default" label and the popover gets a "Use Default" button. Nil (e.g. SettingsView's own
    /// global-default field) means this field *is* the baseline — nothing to inherit from.
    var defaultSeconds: Int?

    @State private var isPresented = false
    @State private var wheelSelection: Int = 90

    private var isShowingDefault: Bool {
        seconds == 0 && defaultSeconds != nil
    }

    private var displayLabel: String {
        if isShowingDefault, let defaultSeconds {
            return "Default (\(Self.format(defaultSeconds)))"
        }
        return Self.format(seconds)
    }

    var body: some View {
        Button {
            wheelSelection = isShowingDefault ? (defaultSeconds ?? 90) : seconds
            isPresented = true
        } label: {
            Text(displayLabel)
                .frame(maxWidth: .infinity)
                .setValueFieldStyle()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("restTimeField")
        .popover(isPresented: $isPresented) {
            VStack(spacing: 8) {
                Picker("Rest time", selection: $wheelSelection) {
                    ForEach(Array(stride(from: 5, through: 300, by: 5)), id: \.self) { value in
                        Text(Self.format(value)).tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .onChange(of: wheelSelection) { _, newValue in
                    seconds = newValue
                }

                if defaultSeconds != nil {
                    Button("Use Default") {
                        seconds = 0
                        isPresented = false
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.brand)
                }
            }
            .padding(16)
            .frame(width: 220)
            .presentationCompactAdaptation(.popover)
        }
    }

    private static func format(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
