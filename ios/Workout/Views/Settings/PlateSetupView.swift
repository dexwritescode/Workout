//
//  PlateSetupView.swift
//  Workout
//
//  Lets the user select which plates they have available and set their
//  barbell weight. Settings are stored per unit (kg / lbs) independently.
//

import SwiftUI
import SwiftData

struct PlateSetupView: View {
    @Bindable var settings: UserSettings

    private var isKg: Bool { settings.unit == .kg }

    private var allPlates: [Double] {
        isKg ? UserSettings.standardPlatesKg : UserSettings.standardPlatesLbs
    }

    private var availablePlates: Binding<[Double]> {
        isKg ? $settings.availablePlatesKg : $settings.availablePlatesLbs
    }

    private var barbellWeight: Binding<Double> {
        isKg ? $settings.barbellWeightKg : $settings.barbellWeightLbs
    }

    private var unitLabel: String { isKg ? "kg" : "lbs" }

    var body: some View {
        Form {
            // Bar weight
            Section {
                HStack {
                    Text("Barbell weight")
                        .foregroundStyle(AppStyle.Colors.text)
                    Spacer()
                    Stepper(
                        "\(formatWeight(barbellWeight.wrappedValue)) \(unitLabel)",
                        value: barbellWeight,
                        in: isKg ? 10...30 : 20...65,
                        step: isKg ? 2.5 : 5
                    )
                    .fixedSize()
                    .foregroundStyle(AppStyle.Colors.text)
                }
            } header: {
                Text("Barbell").sectionHeader()
            } footer: {
                Text("Standard Olympic bar is \(isKg ? "20 kg" : "45 lbs").")
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
            .listRowBackground(AppStyle.Colors.surface1)
            .listRowSeparatorTint(AppStyle.Colors.border)

            // Available plates
            Section {
                ForEach(allPlates, id: \.self) { plate in
                    let isOn = availablePlates.wrappedValue.contains(plate)
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if isOn {
                                availablePlates.wrappedValue.removeAll { $0 == plate }
                            } else {
                                availablePlates.wrappedValue.append(plate)
                                availablePlates.wrappedValue.sort(by: >)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isOn ? AppStyle.Colors.brand : AppStyle.Colors.textTertiary)
                                .font(.system(size: 20))
                            Text("\(formatWeight(plate)) \(unitLabel)")
                                .foregroundStyle(AppStyle.Colors.text)
                            Spacer()
                            RoundedRectangle(cornerRadius: 3)
                                .fill(plateColor(plate))
                                .frame(width: 10, height: 28)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Plates you have").sectionHeader()
            } footer: {
                Text("The calculator will only use selected plates.")
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
            .listRowBackground(AppStyle.Colors.surface1)
            .listRowSeparatorTint(AppStyle.Colors.border)
        }
        .scrollContentBackground(.hidden)
        .background(AppStyle.Colors.background)
        .navigationTitle("Plate Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.2g", value)
    }

    private func plateColor(_ kg: Double) -> Color {
        // Matches PlateCalculatorView colours; lbs plates use same visual mapping by index
        let kgRef: Double = isKg ? kg : kg * 0.453592
        switch kgRef {
        case 11.0...: return Color(red: 0.85, green: 0.15, blue: 0.15) // red  — 25 kg / 45 lbs
        case 9.0..<11.0: return Color(red: 0.10, green: 0.45, blue: 0.85) // blue — 20 kg / ≈35 lbs
        case 6.0..<9.0: return Color(red: 0.90, green: 0.70, blue: 0.10)  // yellow — 15 kg / 25 lbs
        case 4.0..<6.0: return Color(red: 0.20, green: 0.65, blue: 0.30)  // green — 10 kg
        case 2.0..<4.0: return Color(red: 0.55, green: 0.55, blue: 0.60)  // grey — 5 kg
        default:        return Color(red: 0.80, green: 0.75, blue: 0.70)  // light — 2.5 / 1.25
        }
    }
}
