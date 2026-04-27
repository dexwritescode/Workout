//
//  ActiveWorkoutView.swift
//  Workout
//
//  Template detail: exercise list → active state with live timer → set tracking → summary.
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ActiveWorkoutViewModel
    @State private var showCancelConfirmation = false
    @State private var showSummary = false
    @State private var showExercisePicker = false
    @State private var selectedTrackingIndex: Int?

    let autoStart: Bool

    init(template: WorkoutTemplate, modelContext: ModelContext, autoStart: Bool = false) {
        _viewModel = State(initialValue: ActiveWorkoutViewModel(template: template, modelContext: modelContext))
        self.autoStart = autoStart
    }

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.state {
            case .notStarted:
                preWorkoutView
            case .inProgress:
                activeWorkoutView
            case .finished:
                finishedPlaceholder
            }
        }
        .background(AppStyle.Colors.background)
        .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        .onAppear {
            if autoStart && viewModel.state == .notStarted {
                viewModel.startWorkout()
            }
        }
        .navigationTitle(viewModel.template.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.state == .inProgress)
        .toolbar {
            if viewModel.state == .inProgress {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCancelConfirmation = true
                    }
                    .foregroundStyle(AppStyle.Colors.error)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showExercisePicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .confirmationDialog(
            "Cancel Workout?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Workout", role: .destructive) {
                viewModel.cancelWorkout()
                dismiss()
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress will be lost.")
        }
        .navigationDestination(item: $selectedTrackingIndex) { index in
            let exercises = viewModel.allTemplateExercises
            let completed = viewModel.sortedCompletedExercises
            if index < exercises.count, index < completed.count {
                ExerciseTrackingView(
                    completedExercise: completed[index],
                    templateExercise: exercises[index],
                    modelContext: modelContext,
                    onAllSetsComplete: { viewModel.markExerciseComplete(at: index) }
                )
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { exercise in
                viewModel.addExercise(exercise)
                showExercisePicker = false
            }
        }
        .fullScreenCover(isPresented: $showSummary) {
            if let summary = viewModel.summary {
                WorkoutSummaryView(
                    summary: summary,
                    templateName: viewModel.template.name,
                    onSave: { notes in
                        viewModel.updateNotes(notes)
                        viewModel.saveWorkout()
                        showSummary = false
                        dismiss()
                    },
                    onDiscard: {
                        viewModel.discardWorkout()
                        showSummary = false
                        dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Pre-Workout

    private var preWorkoutView: some View {
        VStack(spacing: 0) {
            exerciseList(highlight: false)

            // Start button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.startWorkout()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15))
                    Text("Start Workout")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Active Workout

    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            elapsedTimerBar
            exerciseList(highlight: true)

            // Finish button
            Button {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                viewModel.finishWorkout()
                showSummary = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                    Text("Finish Workout")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .buttonStyle(PrimaryActionButtonStyle(color: AppStyle.Colors.success))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var elapsedTimerBar: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = context.date.timeIntervalSince(viewModel.session?.startTime ?? .now)
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 15))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                Text(ActiveWorkoutViewModel.formatDuration(elapsed))
                    .font(AppStyle.Typography.mono(15, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.brand)
                    .contentTransition(.numericText())
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(AppStyle.Colors.surface2)
            .overlay(alignment: .bottom) {
                AppStyle.Colors.border.frame(height: 1)
            }
        }
    }

    // MARK: - Exercise List

    private func exerciseList(highlight: Bool) -> some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(Array(viewModel.allTemplateExercises.enumerated()), id: \.element.id) { index, templateExercise in
                    let completedExercise = viewModel.sortedCompletedExercises.count > index
                        ? viewModel.sortedCompletedExercises[index]
                        : nil

                    if highlight {
                        SwipeToRevealDelete(onDelete: { viewModel.removeExercise(at: index) }) {
                            Button {
                                selectedTrackingIndex = index
                            } label: {
                                exerciseRowContent(templateExercise: templateExercise, index: index, highlight: highlight)
                            }
                            .buttonStyle(.plain)
                        }
                    } else if !highlight, let exercise = templateExercise.exercise {
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            exerciseRowContent(templateExercise: templateExercise, index: index, highlight: highlight)
                        }
                        .buttonStyle(.plain)
                    } else {
                        exerciseRowContent(templateExercise: templateExercise, index: index, highlight: highlight)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func exerciseRowContent(templateExercise: TemplateExercise, index: Int, highlight: Bool) -> some View {
        let isCurrent = highlight && index == viewModel.currentExerciseIndex
        let completedExercise = viewModel.sortedCompletedExercises.count > index
            ? viewModel.sortedCompletedExercises[index]
            : nil
        let completedSetsCount = completedExercise?.sets.filter(\.isCompleted).count ?? 0
        let isExerciseDone = completedSetsCount >= templateExercise.targetSets

        return HStack(spacing: 14) {
            // Status circle
            ZStack {
                Circle()
                    .fill(isExerciseDone ? AppStyle.Colors.success : (isCurrent ? AppStyle.Colors.brand : AppStyle.Colors.surface3))
                    .frame(width: 32, height: 32)

                if isExerciseDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isCurrent ? .white : AppStyle.Colors.textTertiary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(templateExercise.exercise?.name ?? "Unknown Exercise")
                    .font(.system(size: 15, weight: isCurrent ? .bold : .medium))
                    .foregroundStyle(AppStyle.Colors.text)

                if highlight && completedSetsCount > 0 {
                    Text("\(completedSetsCount)/\(templateExercise.targetSets) sets logged")
                        .font(.system(size: 13))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                } else {
                    let weightText = templateExercise.targetWeight > 0
                        ? " · \(String(format: "%.1f", templateExercise.targetWeight)) kg"
                        : ""
                    Text("\(templateExercise.targetSets) sets × \(templateExercise.targetReps) reps\(weightText)")
                        .font(.system(size: 13))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }

                if highlight && isCurrent && !isExerciseDone {
                    Text("Tap to track sets →")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.brand)
                        .padding(.top, 1)
                }
            }

            Spacer()

            if let muscle = templateExercise.exercise?.primaryMusclesDisplayString {
                Text(muscle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(AppStyle.Colors.textSecondary.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(AppStyle.Colors.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(isCurrent ? AppStyle.Colors.brand.opacity(0.07) : AppStyle.Colors.surface1)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.medium)
                .stroke(isCurrent ? AppStyle.Colors.brand.opacity(0.2) : AppStyle.Colors.border, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: isExerciseDone)
        .animation(.easeInOut(duration: 0.3), value: isCurrent)
    }

    // MARK: - Finished

    private var finishedPlaceholder: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: AppStyle.IconSize.hero))
                .foregroundStyle(AppStyle.Colors.success)
            Text("Workout Complete!")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppStyle.Colors.text)
        }
    }
}

// MARK: - Preview

private struct ActiveWorkoutPreview: View {
    @Environment(\.modelContext) private var modelContext
    @State private var template: WorkoutTemplate?

    var body: some View {
        NavigationStack {
            if let template {
                ActiveWorkoutView(template: template, modelContext: modelContext)
            } else {
                ProgressView()
                    .onAppear { seedPreviewData() }
            }
        }
    }

    private func seedPreviewData() {
        let t = WorkoutTemplate(name: "Push Day A", description: "Chest, Shoulders, Triceps")
        modelContext.insert(t)

        let ex1 = Exercise(
            name: "Barbell Bench Press",
            description: "Compound chest exercise",
            instructions: ["Lie on bench", "Press the bar"],
            equipment: ["Barbell", "Flat Bench"],
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders],
            difficultyLevel: .intermediate
        )
        let ex2 = Exercise(
            name: "Overhead Press",
            description: "Compound shoulder exercise",
            instructions: ["Press overhead"],
            equipment: ["Barbell"],
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.triceps],
            difficultyLevel: .intermediate
        )
        modelContext.insert(ex1)
        modelContext.insert(ex2)

        let te1 = TemplateExercise(order: 0, targetSets: 4, targetReps: 8)
        te1.exercise = ex1
        te1.template = t
        modelContext.insert(te1)

        let te2 = TemplateExercise(order: 1, targetSets: 3, targetReps: 10)
        te2.exercise = ex2
        te2.template = t
        modelContext.insert(te2)

        template = t
    }
}

#Preview("Pre-Workout") {
    ActiveWorkoutPreview()
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}
