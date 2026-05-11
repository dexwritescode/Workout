//
//  RecoveryDashboardView.swift
//  Workout
//
//  Recovery tab: stats row + body diagram placeholder + muscle list by group.
//

import SwiftUI
import SwiftData

struct RecoveryDashboardView: View {
    @Query(sort: \MuscleRecoveryState.muscleGroup) private var recoveryStates: [MuscleRecoveryState]

    private var upperBodyStates: [MuscleRecoveryState] {
        recoveryStates.filter { $0.muscle?.category == .upperBody }
            .sorted { ($0.muscle?.rawValue ?? "") < ($1.muscle?.rawValue ?? "") }
    }

    private var lowerBodyStates: [MuscleRecoveryState] {
        recoveryStates.filter { $0.muscle?.category == .lowerBody }
            .sorted { ($0.muscle?.rawValue ?? "") < ($1.muscle?.rawValue ?? "") }
    }

    private var overallRecovery: Double {
        guard !recoveryStates.isEmpty else { return 1.0 }
        let total = recoveryStates.reduce(0.0) { $0 + $1.currentRecoveryPercentage }
        return total / Double(recoveryStates.count)
    }

    private var daysSinceLastWorkout: Int? {
        let dates = recoveryStates.compactMap(\.lastWorkedDate)
        guard let latest = dates.max() else { return nil }
        return Calendar.current.dateComponents([.day], from: latest, to: Date()).day
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.6)
                        Text("Recovery")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(AppStyle.Colors.text)
                    }
                    .padding(.bottom, 16)

                    if recoveryStates.isEmpty {
                        emptyState
                    } else {
                        // Stats row
                        statsRow
                            .padding(.bottom, 16)

                        // Muscle lists
                        if !upperBodyStates.isEmpty {
                            muscleGroupSection(title: "Upper Body", states: upperBodyStates)
                        }
                        if !lowerBodyStates.isEmpty {
                            muscleGroupSection(title: "Lower Body", states: lowerBodyStates)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(AppStyle.Colors.background)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            // Days since last workout
            VStack(alignment: .leading, spacing: 4) {
                Text("\(daysSinceLastWorkout ?? 0)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(AppStyle.Colors.text)
                Text("Days since last\nworkout")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )

            // Overall recovery
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(overallRecovery * 100))%")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(AppStyle.recoveryColor(overallRecovery))
                Text("Overall\nrecovery")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Muscle Group Section

    private func muscleGroupSection(title: String, states: [MuscleRecoveryState]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .sectionHeader()

            VStack(spacing: 0) {
                ForEach(Array(states.enumerated()), id: \.element.muscleGroup) { index, state in
                    let pct = state.currentRecoveryPercentage
                    let pctInt = Int(pct * 100)
                    let color = AppStyle.recoveryColor(pct)
                    let statusLabel = pct >= 0.75 ? "Recovered" : pct >= 0.50 ? "Recovering" : "Fatigued"

                    HStack(spacing: 12) {
                        Text("\(pctInt)%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppStyle.Colors.textSecondary)
                            .frame(width: 36, alignment: .leading)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(state.muscle?.rawValue ?? state.muscleGroup)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppStyle.Colors.text)
                                Spacer()
                                Text(statusLabel)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(color)
                            }

                            // Recovery bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(AppStyle.Colors.surface3)
                                        .frame(height: 4)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(color)
                                        .frame(width: geo.size.width * pct, height: 4)
                                        .animation(.easeInOut(duration: 0.8), value: pct)
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)

                    if index < states.count - 1 {
                        AppStyle.Colors.border.frame(height: 1).padding(.leading, 64)
                    }
                }
            }
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
        }
        .padding(.bottom, 20)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.circle")
                .font(.system(size: 40))
                .foregroundStyle(AppStyle.Colors.textTertiary)
            Text("No Recovery Data")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
            Text("Complete a workout to start tracking muscle recovery.")
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationStack {
        RecoveryDashboardView()
    }
    .modelContainer(for: MuscleRecoveryState.self, inMemory: true)
}
