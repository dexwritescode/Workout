//
//  WorkoutSummaryView.swift
//  Workout
//
//  Post-workout summary: stats grid, muscles trained pills, save/discard.
//

import SwiftUI

struct WorkoutSummaryView: View {
    let summary: ActiveWorkoutViewModel.WorkoutSummary
    let templateName: String
    let onSave: (String) -> Void
    let onDiscard: () -> Void

    @State private var notes: String = ""
    @State private var showDiscardConfirmation = false
    @State private var showContent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Trophy
                        trophyIcon
                            .padding(.top, 32)
                            .padding(.bottom, 16)
                            .scaleEffect(showContent ? 1 : 0.6)
                            .opacity(showContent ? 1 : 0)

                        Text("Workout Complete!")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(AppStyle.Colors.text)
                            .padding(.bottom, 6)

                        Text(templateName)
                            .font(.system(size: 15))
                            .foregroundStyle(AppStyle.Colors.textSecondary)
                            .padding(.bottom, 28)

                        // Stats grid
                        statsGrid
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1 : 0)

                        // Muscles trained
                        if !summary.musclesWorked.isEmpty {
                            musclesSection
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                                .offset(y: showContent ? 0 : 20)
                                .opacity(showContent ? 1 : 0)
                        }

                        // Exercise breakdown
                        exerciseBreakdownSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1 : 0)
                    }
                }

                // Bottom buttons
                VStack(spacing: 8) {
                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        onSave(notes)
                    } label: {
                        Text("Save Workout")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    Button {
                        showDiscardConfirmation = true
                    } label: {
                        Text("Discard")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(AppStyle.Colors.background)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showContent = true
                }
            }
            .confirmationDialog(
                "Discard Workout?",
                isPresented: $showDiscardConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard Workout", role: .destructive) {
                    onDiscard()
                }
                Button("Keep", role: .cancel) {}
            } message: {
                Text("This workout will be permanently deleted.")
            }
        }
    }

    // MARK: - Trophy Icon

    private var trophyIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(AppStyle.Colors.success.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppStyle.Colors.success.opacity(0.25), lineWidth: 2)
                )
                .shadow(color: AppStyle.Colors.success.opacity(0.2), radius: 16)

            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppStyle.Colors.success)
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            statCard(value: ActiveWorkoutViewModel.formatDuration(summary.duration), label: "Duration")
            statCard(value: "\(summary.totalSets)", label: "Sets")
            statCard(value: "\(summary.exercisesCompleted)", label: "Exercises")
            statCard(value: formatVolume(summary.totalVolume), label: "Volume")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(AppStyle.Colors.brand)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppStyle.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Muscles Trained

    private var musclesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muscles Trained")
                .sectionHeader()

            FlowLayout(spacing: 8) {
                ForEach(summary.musclesWorked.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { muscle in
                    Text(muscle.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.brand)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(AppStyle.Colors.brand.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Exercise Breakdown

    private var exerciseBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Breakdown")
                .sectionHeader()

            ForEach(Array(summary.exerciseBreakdowns.enumerated()), id: \.offset) { index, breakdown in
                VStack(alignment: .leading, spacing: 6) {
                    Text(breakdown.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.text)

                    ForEach(breakdown.sets, id: \.setNumber) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                                .font(.system(size: 13))
                                .foregroundStyle(AppStyle.Colors.textTertiary)
                                .frame(width: 44, alignment: .leading)

                            Text(String(format: "%.1f kg × %d", set.weight, set.reps))
                                .font(.system(size: 13))
                                .foregroundStyle(AppStyle.Colors.textSecondary)

                            Spacer()
                        }
                    }
                }
                .padding(14)
                .background(AppStyle.Colors.surface1)
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.Radius.medium)
                        .stroke(AppStyle.Colors.border, lineWidth: 1)
                )
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.08),
                    value: showContent
                )
            }
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

#Preview {
    WorkoutSummaryView(
        summary: ActiveWorkoutViewModel.WorkoutSummary(
            duration: 2745,
            exercisesCompleted: 3,
            totalExercises: 4,
            totalSets: 10,
            totalVolume: 8500,
            exerciseBreakdowns: [
                .init(name: "Barbell Bench Press", sets: [
                    .init(setNumber: 1, weight: 100, reps: 8),
                    .init(setNumber: 2, weight: 100, reps: 8),
                    .init(setNumber: 3, weight: 95, reps: 7),
                ]),
            ],
            musclesWorked: [
                .chest: 0.65,
                .shoulders: 0.45,
                .triceps: 0.35,
            ]
        ),
        templateName: "Push Day A",
        onSave: { _ in },
        onDiscard: {}
    )
}
