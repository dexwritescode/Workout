//
//  PlateCalculatorView.swift
//  Workout
//
//  Shows which plates to load on each side of the bar for a target weight.
//  Uses a greedy algorithm with standard Olympic plate denominations.
//

import SwiftUI

struct PlateCalculatorView: View {
    let targetWeight: Double
    let barbellWeight: Double

    @Environment(\.dismiss) private var dismiss

    private let availablePlates: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    private var platesPerSide: [(plate: Double, count: Int)] {
        let perSide = max(0, targetWeight - barbellWeight) / 2
        var remaining = perSide
        var result: [(plate: Double, count: Int)] = []
        for plate in availablePlates {
            let count = Int(remaining / plate)
            if count > 0 {
                result.append((plate: plate, count: count))
                remaining -= Double(count) * plate
            }
        }
        return result
    }

    private var loadedWeight: Double {
        let perSide = platesPerSide.reduce(0.0) { $0 + $1.plate * Double($1.count) }
        return barbellWeight + perSide * 2
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                targetHeader
                    .padding(20)

                Divider().overlay(AppStyle.Colors.border)

                if platesPerSide.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            barVisualization
                                .padding(.horizontal, 20)
                                .padding(.top, 20)

                            plateList
                                .padding(.horizontal, 20)

                            if abs(loadedWeight - targetWeight) > 0.01 {
                                nearestNote
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(AppStyle.Colors.background)
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - Target Header

    private var targetHeader: some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text(formatWeight(targetWeight))
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(AppStyle.Colors.text)
                Text("target")
                    .font(.system(size: 12))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)

            Text("→")
                .font(.system(size: 20))
                .foregroundStyle(AppStyle.Colors.textTertiary)

            VStack(spacing: 2) {
                Text(formatWeight(loadedWeight))
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(abs(loadedWeight - targetWeight) < 0.01
                        ? AppStyle.Colors.brand
                        : AppStyle.Colors.textSecondary)
                Text("loaded")
                    .font(.system(size: 12))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Bar Visualization

    private var barVisualization: some View {
        HStack(spacing: 0) {
            // Left plates (reversed for visual symmetry)
            HStack(spacing: 2) {
                ForEach(Array(platesPerSide.reversed().enumerated()), id: \.offset) { _, entry in
                    ForEach(0..<entry.count, id: \.self) { _ in
                        plateSlice(entry.plate)
                    }
                }
            }

            // Bar
            RoundedRectangle(cornerRadius: 2)
                .fill(AppStyle.Colors.textTertiary.opacity(0.4))
                .frame(width: 40, height: 8)

            // Right plates
            HStack(spacing: 2) {
                ForEach(Array(platesPerSide.enumerated()), id: \.offset) { _, entry in
                    ForEach(0..<entry.count, id: \.self) { _ in
                        plateSlice(entry.plate)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .padding(16)
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }

    private func plateSlice(_ kg: Double) -> some View {
        let height: CGFloat = switch kg {
        case 25: 48
        case 20: 42
        case 15: 36
        case 10: 30
        case 5:  24
        default: 18
        }
        return RoundedRectangle(cornerRadius: 2)
            .fill(plateColor(kg))
            .frame(width: 10, height: height)
    }

    private func plateColor(_ kg: Double) -> Color {
        switch kg {
        case 25:   return Color(red: 0.85, green: 0.15, blue: 0.15) // red
        case 20:   return Color(red: 0.10, green: 0.45, blue: 0.85) // blue
        case 15:   return Color(red: 0.90, green: 0.70, blue: 0.10) // yellow
        case 10:   return Color(red: 0.20, green: 0.65, blue: 0.30) // green
        case 5:    return Color(red: 0.55, green: 0.55, blue: 0.60) // grey
        default:   return Color(red: 0.80, green: 0.75, blue: 0.70) // light
        }
    }

    // MARK: - Plate List

    private var plateList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Per side")
                    .sectionHeader()
                Spacer()
                Text("Bar: \(formatWeight(barbellWeight)) kg")
                    .font(.system(size: 12))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(platesPerSide.enumerated()), id: \.offset) { index, entry in
                    if index > 0 { AppStyle.Colors.border.frame(height: 1).padding(.leading, 16) }
                    HStack {
                        Circle()
                            .fill(plateColor(entry.plate))
                            .frame(width: 12, height: 12)
                        Text("\(formatWeight(entry.plate)) kg")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppStyle.Colors.text)
                        Spacer()
                        Text("× \(entry.count)")
                            .font(AppStyle.Typography.mono(15, weight: .medium))
                            .foregroundStyle(AppStyle.Colors.textSecondary)
                        Text("= \(formatWeight(entry.plate * Double(entry.count))) kg")
                            .font(.system(size: 13))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .frame(width: 72, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Nearest Note

    private var nearestNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 13))
                .foregroundStyle(AppStyle.Colors.textTertiary)
            Text("Nearest loadable weight is \(formatWeight(loadedWeight)) kg")
                .font(.system(size: 13))
                .foregroundStyle(AppStyle.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "scalemass")
                .font(.system(size: 36))
                .foregroundStyle(AppStyle.Colors.textTertiary)
            Text("Just the bar")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
            Text("Target weight equals the barbell — no plates needed.")
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.2g", value)
    }
}

#Preview("Standard load") {
    PlateCalculatorView(targetWeight: 102.5, barbellWeight: 20)
}

#Preview("Just the bar") {
    PlateCalculatorView(targetWeight: 20, barbellWeight: 20)
}
