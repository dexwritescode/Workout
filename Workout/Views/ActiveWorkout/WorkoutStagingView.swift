// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  WorkoutStagingView.swift
//  Workout
//
//  Unified workout-starting flow: generate, load a template, edit freely, start — all against
//  the single draft WorkoutTemplate.
//

import SwiftUI
import SwiftData

struct WorkoutStagingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ActiveWorkoutCoordinator.self) private var coordinator

    @Query private var recoveryStates: [MuscleRecoveryState]
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted },
        sort: \WorkoutSession.startTime,
        order: .reverse
    ) private var recentSessions: [WorkoutSession]
    @Query private var settings: [UserSettings]
    @Query private var dayAssignments: [DayTemplateAssignment]

    @State private var draft: WorkoutTemplate?
    @State private var isDirty = false
    @State private var selectedSplit: SplitType = .pushPullLegs
    @State private var showLoadTemplate = false
    @State private var showManageTemplates = false
    @State private var showAddExercise = false
    @State private var exerciseToEdit: TemplateExercise?
    @State private var showRegenerateConfirm = false

    private var currentSplit: SplitType {
        settings.first?.splitType ?? .pushPullLegs
    }

    private var currentMode: WorkoutStartMode {
        settings.first?.workoutStartMode ?? .smart
    }

    private var todaysAssignment: DayTemplateAssignment? {
        let today = Weekday.today.rawValue
        return dayAssignments.first { $0.weekday == today }
    }

    private var sortedExercises: [TemplateExercise] {
        draft?.exercises.sorted { $0.order < $1.order } ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    if currentMode == .smart && draft?.sourceTemplateID == nil {
                        splitPicker
                            .padding(.horizontal, 16)
                    }

                    if sortedExercises.isEmpty {
                        generatePrompt
                            .padding(.horizontal, 16)
                            .transition(.opacity)
                    } else {
                        workoutPreview
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }
                }
                .padding(.top, 16)
            }
            .background(AppStyle.Colors.background)

            if !sortedExercises.isEmpty && !coordinator.isActive {
                Button {
                    startWorkout()
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
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    WorkoutSettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Workout Settings")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showManageTemplates = true
                } label: {
                    Image(systemName: "list.bullet.rectangle")
                }
            }
        }
        .onAppear {
            // Only seed from the saved default on the very first appear — onAppear refires on
            // every tab reselect now that this view is the tab root, and unconditionally
            // resetting here would silently discard whatever split the user picked this session.
            if self.draft == nil {
                selectedSplit = currentSplit
            }
            let draft = WorkoutTemplate.draft(in: modelContext)
            self.draft = draft
            refreshIfNeeded(draft)
        }
        .onChange(of: coordinator.isActive) { _, isActive in
            // This view never leaves the hierarchy while a workout is active (it's just covered
            // full-screen or minimized to the mini-bar), so onAppear alone won't refire once the
            // workout ends — e.g. saveWorkout() clearing the draft back to empty. Re-run the same
            // on-appear logic whenever a workout finishes, is cancelled, or is discarded.
            if !isActive, let draft {
                refreshIfNeeded(draft)
            }
        }
        .sheet(isPresented: $showManageTemplates) {
            TemplatePickerView()
        }
        .sheet(isPresented: $showLoadTemplate) {
            TemplatePickerView { template in
                draft?.loadExercises(from: template, context: modelContext)
                isDirty = false
            }
        }
        .sheet(isPresented: $showAddExercise) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .sheet(item: $exerciseToEdit) { te in
            TemplateExerciseEditorView(templateExercise: te, onSave: { isDirty = true })
        }
        .alert("Regenerate workout?", isPresented: $showRegenerateConfirm) {
            Button("Regenerate", role: .destructive) { generateAndRebuild() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This discards the current plan.")
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
                            regenerateTapped()
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
                        .accessibilityAddTraits(selectedSplit == split ? [.isSelected] : [])
                    }
                }
            }
        }
    }

    // MARK: - Generate Prompt

    private var emptyStateMessage: String {
        switch currentMode {
        case .smart:
            return "Tap Generate to create a workout\nbased on your recovery status."
        case .dayTemplate:
            return "No template scheduled for today.\nLoad one to get started."
        case .freeform:
            return "Load a template to get started."
        }
    }

    private var generatePrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: currentMode == .smart ? "sparkles" : "calendar")
                .font(.system(size: AppStyle.IconSize.hero))
                .foregroundStyle(AppStyle.Colors.textTertiary)

            Text(emptyStateMessage)
                .font(.system(size: 15))
                .foregroundStyle(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)

            if currentMode == .smart {
                Button {
                    generateAndRebuild()
                } label: {
                    Label("Generate Workout", systemImage: "sparkles")
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }

            Button {
                showLoadTemplate = true
            } label: {
                Text(currentMode == .smart ? "Load Template Instead" : "Load Template")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.vertical, 32)
    }

    // MARK: - Workout Preview

    private var targetMuscles: [MuscleGroup] {
        var seen = Set<MuscleGroup>()
        var result: [MuscleGroup] = []
        for te in sortedExercises {
            for muscle in te.exercise?.primaryMuscleGroups ?? [] where !seen.contains(muscle) {
                seen.insert(muscle)
                result.append(muscle)
            }
        }
        return result
    }

    private var estimatedMinutes: Int {
        let totalSets = sortedExercises.reduce(0) { $0 + $1.targetSets }
        return max(20, totalSets * 2 + sortedExercises.count * 2)
    }

    private var workoutPreview: some View {
        VStack(spacing: 16) {
            headerCard

            VStack(spacing: 6) {
                ForEach(sortedExercises, id: \.id) { te in
                    exerciseRow(te)
                }
            }

            Button {
                showAddExercise = true
            } label: {
                Label("Add Exercise", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.brand)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Button {
                    showLoadTemplate = true
                } label: {
                    Text("Load Template")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                if currentMode == .smart {
                    Button {
                        regenerateTapped()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                            Text("Regenerate")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 6) {
            Text(draft?.name ?? "Workout")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(AppStyle.Colors.text)

            HStack(spacing: 16) {
                Label("\(sortedExercises.count) exercises", systemImage: "square.grid.2x2")
                Label("~\(estimatedMinutes) min", systemImage: "clock")
            }
            .font(.system(size: 14))
            .foregroundStyle(AppStyle.Colors.textSecondary)

            HStack(spacing: 6) {
                ForEach(targetMuscles) { muscle in
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
    }

    private func exerciseRow(_ te: TemplateExercise) -> some View {
        HStack(spacing: 14) {
            ExerciseImageView(
                mediaFileName: te.exercise?.mediaFileName,
                animated: false,
                cornerRadius: 8
            )
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(te.exercise?.name ?? "Unknown")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.text)
                Text("\(te.targetSets) sets × \(te.targetReps) reps · \(te.exercise?.primaryMusclesDisplayString ?? "")")
                    .font(.system(size: 13))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }

            Spacer()

            Button {
                exerciseToEdit = te
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(AppStyle.Colors.surface2)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button {
                deleteExercise(te)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(AppStyle.Colors.error)
            }
            .buttonStyle(.plain)
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

    // MARK: - Actions

    /// Populates the draft on appear, branching on the user's chosen start mode.
    private func refreshIfNeeded(_ draft: WorkoutTemplate) {
        switch currentMode {
        case .smart:
            // Refreshes an untouched AI suggestion against live recovery — never touches a
            // template-sourced or user-edited draft.
            if draft.exercises.isEmpty {
                generateAndRebuild()
            } else if draft.sourceTemplateID == nil && !isDirty {
                generateAndRebuild()
            }

        case .dayTemplate:
            let today = Weekday.today.rawValue
            if let assigned = todaysAssignment?.template {
                if draft.autoLoadedForWeekday != today {
                    // A stale prior-day auto-load, or an empty draft, is safe to replace. If
                    // autoLoadedForWeekday is nil and the draft is non-empty, it's the user's
                    // manual override — leave it alone rather than clobbering it.
                    if draft.autoLoadedForWeekday != nil || draft.exercises.isEmpty {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            draft.loadExercises(from: assigned, context: modelContext)
                            draft.autoLoadedForWeekday = today
                            isDirty = false
                        }
                    }
                }
            } else if draft.autoLoadedForWeekday != nil, settings.first?.dayTemplateFallbackMode == .smart {
                // No assignment for today and a stale auto-loaded remnant is sitting in the
                // draft — the fallback says regenerate.
                generateAndRebuild()
            }
            // .freeform fallback, or a manual override/already-empty draft → always leave alone.

        case .freeform:
            break // No automation, regardless of draft state.
        }
    }

    private func generateAndRebuild() {
        guard let draft else { return }
        let workout = WorkoutEngine.generateWorkout(
            splitType: selectedSplit,
            recoveryStates: recoveryStates,
            allExercises: allExercises,
            recentSessions: Array(recentSessions.prefix(10))
        )
        withAnimation(.easeInOut(duration: 0.3)) {
            draft.rebuildExercises(from: workout, context: modelContext)
            isDirty = false
        }
    }

    /// Regenerate is always available; only confirms when discarding something other than a
    /// fresh, untouched generation — that includes a loaded template, even though loading one
    /// doesn't itself mark the draft dirty.
    private func regenerateTapped() {
        if isDirty || draft?.sourceTemplateID != nil {
            showRegenerateConfirm = true
        } else {
            generateAndRebuild()
        }
    }

    private func addExercise(_ exercise: Exercise) {
        guard let draft else { return }
        let te = TemplateExercise(order: draft.exercises.count, targetSets: 3, targetReps: 10, restSeconds: 90)
        te.exercise = exercise
        te.template = draft
        modelContext.insert(te)
        isDirty = true
    }

    private func deleteExercise(_ te: TemplateExercise) {
        modelContext.delete(te)
        isDirty = true
    }

    private func startWorkout() {
        guard let draft else { return }
        coordinator.start(template: draft, modelContext: modelContext)
    }
}

#Preview {
    NavigationStack {
        WorkoutStagingView()
    }
    .environment(ActiveWorkoutCoordinator())
    .modelContainer(for: [
        MuscleRecoveryState.self,
        Exercise.self,
        WorkoutSession.self,
        UserSettings.self,
        WorkoutTemplate.self,
        DayTemplateAssignment.self
    ], inMemory: true)
}