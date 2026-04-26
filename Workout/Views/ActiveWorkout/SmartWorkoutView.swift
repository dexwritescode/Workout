//
//  SmartWorkoutView.swift
//  Workout
//
//  Smart workout generation with split selector, exercise preview, and start.
//

import SwiftUI
import SwiftData

struct SmartWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var recoveryStates: [MuscleRecoveryState]
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted },
        sort: \WorkoutSession.startTime,
        order: .reverse
    ) private var recentSessions: [WorkoutSession]
    @Query private var settings: [UserSettings]

    @State private var generatedWorkout: WorkoutEngine.GeneratedWorkout?
    @State private var selectedSplit: SplitType = .pushPullLegs
    @State private var createdTemplate: WorkoutTemplate?
    @State private var showActiveWorkout = false

    private var currentSplit: SplitType {
        settings.first?.splitType ?? .pushPullLegs
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    splitPicker
                        .padding(.horizontal, 16)

                    if let workout = generatedWorkout {
                        workoutPreview(workout)
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    } else {
                        generatePrompt
                            .padding(.horizontal, 16)
                            .transition(.opacity)
                    }
                }
                .padding(.top, 16)
            }
            .background(AppStyle.Colors.background)

            if let workout = generatedWorkout {
                Button {
                    startWorkout(workout)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15))
                        Text("Start Workout")
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(AppStyle.Colors.background)
        .navigationTitle("Smart Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedSplit = currentSplit
            withAnimation(.easeInOut(duration: 0.3)) {
                generateWorkout()
            }
        }
        .fullScreenCover(isPresented: $showActiveWorkout) {
            if let template = createdTemplate {
                NavigationStack {
                    ActiveWorkoutView(template: template, modelContext: modelContext, autoStart: true)
                }
            }
        }
    }

    // MARK: - Split Picker

    private var splitPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Training Split")
                .sectionHeader()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(SplitType.allCases) { split in
                        Button {
                            selectedSplit = split
                            withAnimation(.easeInOut(duration: 0.3)) {
                                generateWorkout()
                            }
                        } label: {
                            Text(split.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selectedSplit == split ? AppStyle.Colors.brand : AppStyle.Colors.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedSplit == split ? AppStyle.Colors.brand.opacity(0.12) : AppStyle.Colors.surface2)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(selectedSplit == split ? AppStyle.Colors.brand : AppStyle.Colors.borderStrong, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Generate Prompt

    private var generatePrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: AppStyle.IconSize.hero))
                .foregroundStyle(AppStyle.Colors.textTertiary)

            Text("Tap Generate to create a workout\nbased on your recovery status.")
                .font(.system(size: 15))
                .foregroundStyle(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                generateWorkout()
            } label: {
                Label("Generate Workout", systemImage: "sparkles")
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
        .padding(.vertical, 32)
    }

    // MARK: - Workout Preview

    private func workoutPreview(_ workout: WorkoutEngine.GeneratedWorkout) -> some View {
        VStack(spacing: 16) {
            // Header card
            VStack(spacing: 6) {
                Text(workout.name)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(AppStyle.Colors.text)

                HStack(spacing: 16) {
                    Label("\(workout.exercises.count) exercises", systemImage: "square.grid.2x2")
                    Label("~\(workout.estimatedDuration) min", systemImage: "clock")
                }
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)

                HStack(spacing: 6) {
                    ForEach(workout.targetMuscles) { muscle in
                        Text(muscle.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppStyle.Colors.brand)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(AppStyle.Colors.brand.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )

            // Exercise list
            VStack(spacing: 6) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, suggestion in
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppStyle.Colors.brand.opacity(0.1))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(AppStyle.Colors.brand)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.exercise.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppStyle.Colors.text)
                            Text("\(suggestion.targetSets) sets × \(suggestion.targetReps) reps · \(suggestion.exercise.primaryMusclesDisplayString)")
                                .font(.system(size: 13))
                                .foregroundStyle(AppStyle.Colors.textTertiary)
                        }

                        Spacer()

                        Text(suggestion.exercise.isCompound ? "compound" : "isolation")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(suggestion.exercise.isCompound ? AppStyle.Colors.compound : AppStyle.Colors.isolation)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background((suggestion.exercise.isCompound ? AppStyle.Colors.compound : AppStyle.Colors.isolation).opacity(0.13))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppStyle.Colors.surface1)
                    .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.Radius.medium)
                            .stroke(AppStyle.Colors.border, lineWidth: 1)
                    )
                }
            }

            // Regenerate
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    generateWorkout()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                    Text("Regenerate")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(AppStyle.Colors.brand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppStyle.Colors.borderStrong, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Actions

    private func generateWorkout() {
        generatedWorkout = WorkoutEngine.generateWorkout(
            splitType: selectedSplit,
            recoveryStates: recoveryStates,
            allExercises: allExercises,
            recentSessions: Array(recentSessions.prefix(10))
        )
    }

    private func startWorkout(_ workout: WorkoutEngine.GeneratedWorkout) {
        let template = WorkoutEngine.createTemplate(from: workout, modelContext: modelContext)
        createdTemplate = template
        showActiveWorkout = true
    }
}

#Preview {
    NavigationStack {
        SmartWorkoutView()
    }
    .modelContainer(for: [
        MuscleRecoveryState.self,
        Exercise.self,
        WorkoutSession.self,
        UserSettings.self,
        WorkoutTemplate.self
    ], inMemory: true)
}
