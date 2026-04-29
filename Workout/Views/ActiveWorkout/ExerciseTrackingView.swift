//
//  ExerciseTrackingView.swift
//  Workout
//
//  Set tracking: inline weight/reps input in the sets table, rest timer banner.
//

import SwiftUI
import SwiftData

struct ExerciseTrackingView: View {
    @Bindable var completedExercise: CompletedExercise
    let templateExercise: TemplateExercise
    let modelContext: ModelContext
    let onAllSetsComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var weight: Double = 0
    @State private var reps: Double = 10
    @State private var showRestTimer = false
    @State private var restTimerEndDate: Date?
    @State private var editingSet: ExerciseSet?
    @State private var extraSets: Int = 0
    @State private var lastSession: (date: Date, sets: [(weight: Double, reps: Int)])? = nil
    @State private var showPlateCalculator = false
    @State private var editingOriginalWeight: Double = 0
    @State private var editingOriginalReps: Int = 0

    private static let restTimerKey = "activeRestTimerEndDate"

    private var completedSets: [ExerciseSet] {
        completedExercise.sets
            .filter(\.isCompleted)
            .sorted { $0.setNumber < $1.setNumber }
    }

    private var targetSets: Int {
        max(max(1, completedSets.count), templateExercise.targetSets + extraSets)
    }

    private var currentSetNumber: Int {
        completedSets.count + 1
    }

    private var allSetsComplete: Bool {
        completedSets.count >= targetSets
    }

    var body: some View {
        VStack(spacing: 0) {
            // Nav subtitle
            HStack(spacing: 6) {
                Text("\(completedSets.count > 0 ? completedSets.count : 1) of \(targetSets) sets")
                    .font(.system(size: 11))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                Text("·")
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                Text(completedExercise.exercise?.primaryMusclesDisplayString ?? "")
                    .font(.system(size: 11))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                Spacer()
                if allSetsComplete {
                    Text("Done")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.success)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppStyle.Colors.success.opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 16) {
                    // Exercise hero
                    if completedExercise.exercise?.mediaFileName != nil {
                        ExerciseImageView(
                            mediaFileName: completedExercise.exercise?.mediaFileName,
                            animated: true,
                            cornerRadius: AppStyle.Radius.card,
                            contentMode: .fit
                        )
                        .frame(maxWidth: .infinity)
                    }

                    // Rest timer banner
                    if showRestTimer, let endDate = restTimerEndDate {
                        RestTimerView(
                            endDate: endDate,
                            onComplete: { clearRestTimer() },
                            onSkip: { clearRestTimer() }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Last session banner
                    lastSessionBanner

                    // Interactive sets table
                    setsTable

                    // All complete banner
                    if allSetsComplete && editingSet == nil {
                        allCompleteBanner
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(16)
                .animation(.easeInOut(duration: 0.3), value: showRestTimer)
                .animation(.easeInOut(duration: 0.3), value: allSetsComplete)
                .animation(.easeInOut(duration: 0.3), value: editingSet?.id)
            }

            // Bottom button
            bottomButton
        }
        .background(AppStyle.Colors.background)
        .navigationTitle(completedExercise.exercise?.name ?? "Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let exercise = completedExercise.exercise {
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showPlateCalculator = true
                } label: {
                    Image(systemName: "scalemass")
                }
                .disabled(weight <= 0)
            }
        }
        .sheet(isPresented: $showPlateCalculator) {
            PlateCalculatorView(targetWeight: weight)
        }
        .onAppear {
            restoreState()
        }
    }

    // MARK: - Last Session Banner

    @ViewBuilder
    private var lastSessionBanner: some View {
        if let info = lastSession {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                Text(info.date.formatted(.relative(presentation: .named)))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                Text("·")
                    .foregroundStyle(AppStyle.Colors.textTertiary)
                    .font(.system(size: 12))
                Text(info.sets.map { s in
                    let w = s.weight.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", s.weight)
                        : String(format: "%.1f", s.weight)
                    return "\(w)×\(s.reps)"
                }.joined(separator: "  "))
                    .font(AppStyle.Typography.mono(12, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
                overloadBadge(lastWeight: info.sets.first?.weight)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.medium)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.easeInOut(duration: 0.2), value: weight)
        }
    }

    @ViewBuilder
    private func overloadBadge(lastWeight: Double?) -> some View {
        if let lastWeight, lastWeight > 0, weight > 0, editingSet == nil {
            let delta = weight - lastWeight
            let isUp = delta > 0.001
            let isDown = delta < -0.001
            let label = isUp
                ? "+\(formatWeight(abs(delta)))"
                : isDown ? "−\(formatWeight(abs(delta)))" : "="
            let color: Color = isUp ? AppStyle.Colors.success : isDown ? AppStyle.Colors.error : AppStyle.Colors.textTertiary
            let icon = isUp ? "arrow.up" : isDown ? "arrow.down" : "equal"

            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                Text(label)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    // MARK: - Rest Timer

    private func clearRestTimer() {
        showRestTimer = false
        restTimerEndDate = nil
        UserDefaults.standard.removeObject(forKey: Self.restTimerKey)
    }

    // MARK: - Sets Table

    private var setsTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Sets — \(completedSets.count)/\(targetSets)")
                    .sectionHeader()
                if editingSet != nil {
                    Spacer()
                    Button("Cancel") { cancelEditing() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 10)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("SET")
                        .frame(width: 32, alignment: .leading)
                    Text("WEIGHT")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("REPS")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer().frame(width: 40)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.textTertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) {
                    AppStyle.Colors.border.frame(height: 1)
                }

                // Rows
                ForEach(0..<targetSets, id: \.self) { i in
                    let done = i < completedSets.count
                    let s = done ? completedSets[i] : nil
                    let isCurrent = i == completedSets.count && !allSetsComplete
                    let isEditing = editingSet != nil && editingSet?.id == s?.id
                    let isActiveInput = isCurrent || isEditing

                    if isActiveInput {
                        inputRow(index: i, isEditing: isEditing)
                    } else if done {
                        SwipeToRevealDelete(onDelete: { deleteSet(s!) }) {
                            Button { beginEditing(s!) } label: {
                                completedRow(index: i, set: s!)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        SwipeToRevealDelete(onDelete: { deleteExtraRow() }) {
                            futureRow(index: i)
                        }
                    }

                    if i < targetSets - 1 {
                        AppStyle.Colors.border.frame(height: 1).padding(.leading, 16)
                    }
                }
            }
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )

            Button {
                extraSets += 1
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                    Text("Add Set")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.brand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppStyle.Colors.brand.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                        .stroke(AppStyle.Colors.brand.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Row Types

    private func completedRow(index: Int, set: ExerciseSet) -> some View {
        HStack {
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppStyle.Colors.text)
                .frame(width: 32, alignment: .leading)

            Text("\(String(format: "%.1f", set.weight)) kg")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppStyle.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(set.reps)")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppStyle.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppStyle.Colors.success)
                .frame(width: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func inputRow(index: Int, isEditing: Bool) -> some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isEditing ? AppStyle.Colors.brand : AppStyle.Colors.brand)
                .frame(width: 32, alignment: .leading)

            // Weight input
            TextField("0", value: $weight, format: .number)
                .keyboardType(.decimalPad)
                .font(AppStyle.Typography.mono(14, weight: .bold))
                .foregroundStyle(AppStyle.Colors.text)
                .multilineTextAlignment(.center)
                .frame(height: 36)
                .background(AppStyle.Colors.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppStyle.Colors.brand.opacity(0.4), lineWidth: 1)
                )
                .frame(maxWidth: .infinity)

            // Reps input
            TextField("0", value: $reps, format: .number)
                .keyboardType(.numberPad)
                .font(AppStyle.Typography.mono(14, weight: .bold))
                .foregroundStyle(AppStyle.Colors.text)
                .multilineTextAlignment(.center)
                .frame(height: 36)
                .background(AppStyle.Colors.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppStyle.Colors.brand.opacity(0.4), lineWidth: 1)
                )
                .frame(maxWidth: .infinity)

            Spacer().frame(width: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppStyle.Colors.brand.opacity(0.05))
    }

    private func futureRow(index: Int) -> some View {
        HStack {
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppStyle.Colors.textTertiary)
                .frame(width: 32, alignment: .leading)

            Text(weight > 0 ? "\(formatWeight(weight)) kg" : "— kg")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppStyle.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(Int(reps))")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppStyle.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(width: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    // MARK: - All Complete

    private var allCompleteBanner: some View {
        VStack(spacing: 8) {
            Text("All sets complete!")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppStyle.Colors.success)
            Text("Head back to continue your workout.")
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppStyle.Colors.success.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                .stroke(AppStyle.Colors.success.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Bottom Button

    @ViewBuilder
    private var bottomButton: some View {
        if let editing = editingSet {
            Button {
                saveEdit(editing)
            } label: {
                Text("Update Set \(editing.setNumber)")
                    .font(.system(size: 16, weight: .bold))
            }
            .buttonStyle(PrimaryActionButtonStyle(color: AppStyle.Colors.brand))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else if !allSetsComplete {
            Button {
                completeCurrentSet()
            } label: {
                Text("Log Set \(currentSetNumber)")
                    .font(.system(size: 16, weight: .bold))
            }
            .buttonStyle(PrimaryActionButtonStyle(color: weight > 0 ? AppStyle.Colors.brand : AppStyle.Colors.surface3))
            .disabled(weight <= 0)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else {
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .bold))
            }
            .buttonStyle(PrimaryActionButtonStyle(color: AppStyle.Colors.success))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Editing

    private func beginEditing(_ set: ExerciseSet) {
        editingSet = set
        editingOriginalWeight = set.weight
        editingOriginalReps = set.reps
        weight = set.weight
        reps = Double(set.reps)
    }

    private func cancelEditing() {
        editingSet = nil
        if let lastSet = completedSets.last {
            weight = lastSet.weight
            reps = Double(lastSet.reps)
        }
    }

    private func deleteExtraRow() {
        guard targetSets > max(1, completedSets.count) else { return }
        extraSets -= 1
    }

    private func deleteSet(_ set: ExerciseSet) {
        completedExercise.sets.removeAll { $0 === set }
        modelContext.delete(set)
        let remaining = completedSets.sorted { $0.setNumber < $1.setNumber }
        for (i, s) in remaining.enumerated() {
            s.setNumber = i + 1
        }
    }

    private func saveEdit(_ set: ExerciseSet) {
        set.weight = weight
        set.reps = Int(reps)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        editingSet = nil
    }

    // MARK: - Actions

    private func completeCurrentSet() {
        let newSet = ExerciseSet(
            setNumber: currentSetNumber,
            weight: weight,
            reps: Int(reps),
            isCompleted: true,
            rpe: nil
        )
        newSet.completedAt = Date()
        newSet.completedExercise = completedExercise
        modelContext.insert(newSet)
        completedExercise.sets.append(newSet)

        if completedSets.count >= targetSets {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            clearRestTimer()
            onAllSetsComplete()
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            let endDate = Date().addingTimeInterval(Double(templateExercise.restSeconds))
            restTimerEndDate = endDate
            showRestTimer = true
            UserDefaults.standard.set(endDate.timeIntervalSince1970, forKey: Self.restTimerKey)
        }
    }

    // MARK: - State Restoration

    private func loadLastSession() {
        guard let exercise = completedExercise.exercise else { return }
        let exerciseID = exercise.id
        let currentSessionID = completedExercise.session?.id

        do {
            let all = try modelContext.fetch(FetchDescriptor<CompletedExercise>())
            let previous = all
                .filter { ce in
                    ce.exercise?.id == exerciseID &&
                    ce.session?.isCompleted == true &&
                    (currentSessionID == nil || ce.session?.id != currentSessionID)
                }
                .sorted { ($0.session?.startTime ?? .distantPast) > ($1.session?.startTime ?? .distantPast) }

            guard let last = previous.first, let date = last.session?.startTime else { return }
            let sets = last.sets
                .filter(\.isCompleted)
                .sorted { $0.setNumber < $1.setNumber }
                .map { (weight: $0.weight, reps: $0.reps) }
            guard !sets.isEmpty else { return }
            lastSession = (date: date, sets: sets)
        } catch {}
    }

    private func restoreState() {
        loadLastSession()

        // Restore rest timer from UserDefaults
        let savedEnd = UserDefaults.standard.double(forKey: Self.restTimerKey)
        if savedEnd > 0 {
            let endDate = Date(timeIntervalSince1970: savedEnd)
            if endDate > Date() {
                restTimerEndDate = endDate
                showRestTimer = true
            } else {
                UserDefaults.standard.removeObject(forKey: Self.restTimerKey)
            }
        }

        // Pre-fill: current session's last set > last session's first set > template target
        if let lastSet = completedSets.last {
            weight = lastSet.weight
            reps = Double(lastSet.reps)
        } else if let firstSet = lastSession?.sets.first {
            weight = firstSet.weight
            reps = Double(firstSet.reps)
        } else if templateExercise.targetWeight > 0 {
            weight = templateExercise.targetWeight
            reps = Double(templateExercise.targetReps)
        }
    }
}


private struct ExerciseTrackingPreview: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var data: (CompletedExercise, TemplateExercise)?

    var body: some View {
        NavigationStack {
            if let data {
                ExerciseTrackingView(
                    completedExercise: data.0,
                    templateExercise: data.1,
                    modelContext: modelContext,
                    onAllSetsComplete: {}
                )
            } else {
                ProgressView()
                    .onAppear { seedData() }
            }
        }
    }

    private func seedData() {
        let exercise = Exercise(
            name: "Barbell Bench Press",
            description: "Compound chest exercise",
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders]
        )
        modelContext.insert(exercise)

        let te = TemplateExercise(order: 0, targetSets: 4, targetReps: 8, restSeconds: 90)
        te.targetWeight = 80
        te.exercise = exercise
        modelContext.insert(te)

        let ce = CompletedExercise(order: 0)
        ce.exercise = exercise
        modelContext.insert(ce)

        data = (ce, te)
    }
}

#Preview {
    ExerciseTrackingPreview()
        .modelContainer(for: CompletedExercise.self, inMemory: true)
}
