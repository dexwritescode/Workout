// SPDX-License-Identifier: AGPL-3.0-or-later
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
    @Environment(ActiveWorkoutCoordinator.self) private var coordinator
    @Query private var allSettings: [UserSettings]
    private var userUnit: WeightUnit { allSettings.first?.unit ?? .kg }
    @State private var showCancelConfirmation = false
    @State private var showSummary = false
    @State private var showExercisePicker = false
    @State private var selectedTrackingIndex: Int?

    /// How long the post-save checkmark confirmation stays up before auto-dismissing.
    /// Overridable via UITEST_SAVE_CONFIRMATION_DELAY so UI tests can reliably observe it
    /// despite XCUITest's ~1s accessibility-snapshot polling interval.
    private static var confirmationDismissDelay: Double {
        ProcessInfo.processInfo.environment["UITEST_SAVE_CONFIRMATION_DELAY"].flatMap(Double.init) ?? 1.0
    }

    var body: some View {
        Group {
            if let viewModel = coordinator.viewModel {
                content(viewModel: viewModel)
            } else {
                Color.clear
            }
        }
    }

    @ViewBuilder
    private func content(viewModel: ActiveWorkoutViewModel) -> some View {
        VStack(spacing: 0) {
            switch viewModel.state {
            case .notStarted:
                // ActiveWorkoutCoordinator.start() always calls viewModel.startWorkout() before
                // this view can observe a non-nil coordinator.viewModel, so this branch never
                // actually renders. WorkoutState still needs the case for the ViewModel's own
                // bookkeeping (see cancelWorkout()), so the switch keeps a trivial fallback here.
                Color.clear
            case .inProgress:
                activeWorkoutView(viewModel: viewModel)
            case .finished:
                finishedPlaceholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppStyle.Colors.background.ignoresSafeArea())
        .toolbarBackground(AppStyle.Colors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle(viewModel.sessionName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    coordinator.minimize()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .semibold))
                }
                .accessibilityLabel("Minimize Workout")
            }
            if viewModel.state == .inProgress {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCancelConfirmation = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .accessibilityLabel("Cancel Workout")
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
                coordinator.clear()
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
        .navigationDestination(isPresented: $showSummary) {
            if let summary = viewModel.summary {
                WorkoutSummaryView(
                    summary: summary,
                    templateName: viewModel.sessionName,
                    onSave: { notes in
                        viewModel.updateNotes(notes)
                        viewModel.saveWorkout()
                        showSummary = false
                        Task {
                            try? await Task.sleep(for: .seconds(Self.confirmationDismissDelay))
                            coordinator.clear()
                        }
                    },
                    onDiscard: {
                        viewModel.discardWorkout()
                        coordinator.clear()
                    }
                )
                .navigationBarBackButtonHidden(true)
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { exercise in
                viewModel.addExercise(exercise)
                showExercisePicker = false
            }
        }
    }

    // MARK: - Active Workout

    private func activeWorkoutView(viewModel: ActiveWorkoutViewModel) -> some View {
        VStack(spacing: 0) {
            elapsedTimerBar(viewModel: viewModel)
            exerciseList(viewModel: viewModel)

            AddExerciseButton {
                showExercisePicker = true
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

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

    private func elapsedTimerBar(viewModel: ActiveWorkoutViewModel) -> some View {
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

    private func exerciseList(viewModel: ActiveWorkoutViewModel) -> some View {
        List {
            ForEach(Array(viewModel.allTemplateExercises.enumerated()), id: \.element.id) { index, templateExercise in
                Button {
                    selectedTrackingIndex = index
                } label: {
                    exerciseRowContent(viewModel: viewModel, templateExercise: templateExercise, index: index)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("activeWorkoutExerciseRow")
                .listRowInsets(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.removeExercise(at: index)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .contentMargins(.vertical, 12, for: .scrollContent)
    }

    private func exerciseRowContent(viewModel: ActiveWorkoutViewModel, templateExercise: TemplateExercise, index: Int) -> some View {
        let isCurrent = index == viewModel.currentExerciseIndex
        let completedExercise = viewModel.sortedCompletedExercises.count > index
            ? viewModel.sortedCompletedExercises[index]
            : nil
        let completedSetsCount = completedExercise?.sets.filter(\.isCompleted).count ?? 0
        let isExerciseDone = completedSetsCount >= templateExercise.targetSets

        return HStack(spacing: 14) {
            // Status circle with exercise thumbnail
            ZStack {
                ExerciseImageView(
                    mediaFileName: templateExercise.exercise?.mediaFileName,
                    animated: false,
                    cornerRadius: 18
                )
                .frame(width: 36, height: 36)
                .opacity(isExerciseDone ? 0.35 : 1.0)

                if isExerciseDone {
                    Circle()
                        .fill(AppStyle.Colors.success.opacity(0.75))
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(isCurrent ? AppStyle.Colors.brand : Color.clear, lineWidth: 2.5)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(templateExercise.exercise?.name ?? "Unknown Exercise")
                    .font(.system(size: 15, weight: isCurrent ? .bold : .medium))
                    .foregroundStyle(AppStyle.Colors.text)

                if completedSetsCount > 0 {
                    Text("\(completedSetsCount)/\(templateExercise.targetSets) sets logged")
                        .font(.system(size: 13))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                } else {
                    let weightText = templateExercise.targetWeight > 0
                        ? " · \(userUnit.display(templateExercise.targetWeight, storedIn: templateExercise.storedTargetWeightUnit))"
                        : ""
                    Text("\(templateExercise.targetSets) sets × \(templateExercise.targetReps) reps\(weightText)")
                        .font(.system(size: 13))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }

                if isCurrent && !isExerciseDone {
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
        .contentShape(Rectangle())
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

private struct ActiveWorkoutPreview: View {
    @Environment(\.modelContext) private var modelContext
    @State private var coordinator = ActiveWorkoutCoordinator()
    @State private var didSeed = false

    var body: some View {
        NavigationStack {
            ActiveWorkoutView()
        }
        .environment(coordinator)
        .onAppear {
            if !didSeed {
                didSeed = true
                seedPreviewData()
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

        coordinator.start(template: t, modelContext: modelContext)
    }
}

#Preview("Active Workout") {
    ActiveWorkoutPreview()
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}
