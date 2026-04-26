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

    @State private var weight: Double = 0
    @State private var reps: Double = 10
    @State private var showRestTimer = false
    @State private var restTimerEndDate: Date?
    @State private var editingSet: ExerciseSet?
    @State private var extraSets: Int = 0

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
            HStack {
                Text("\(completedSets.count > 0 ? completedSets.count : 1) of \(targetSets)")
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
                    // Rest timer banner
                    if showRestTimer, let endDate = restTimerEndDate {
                        RestTimerView(
                            endDate: endDate,
                            onComplete: { clearRestTimer() },
                            onSkip: { clearRestTimer() }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

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
        .onAppear {
            restoreState()
        }
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

            Text("— kg")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppStyle.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(templateExercise.targetReps)")
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
        }
    }

    // MARK: - Editing

    private func beginEditing(_ set: ExerciseSet) {
        editingSet = set
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

    private func restoreState() {
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

        // Pre-fill weight/reps: last completed set > template target weight > default
        if let lastSet = completedSets.last {
            weight = lastSet.weight
            reps = Double(lastSet.reps)
        } else if templateExercise.targetWeight > 0 {
            weight = templateExercise.targetWeight
            reps = Double(templateExercise.targetReps)
        }
    }
}

private struct SwipeToRevealDelete<Content: View>: View {
    let onDelete: () -> Void
    let content: Content

    @State private var offset: CGFloat = 0
    private let revealWidth: CGFloat = 68

    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(role: .destructive, action: {
                withAnimation(.spring(response: 0.25)) { offset = 0 }
                onDelete()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: revealWidth)
                    .frame(maxHeight: .infinity)
                    .background(.red)
            }
            .buttonStyle(.plain)

            content
                .background(AppStyle.Colors.surface1)
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 15)
                        .onChanged { v in
                            guard abs(v.translation.width) > abs(v.translation.height) else { return }
                            offset = min(0, v.translation.width)
                        }
                        .onEnded { v in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                offset = v.translation.width < -(revealWidth / 2) ? -revealWidth : 0
                            }
                        }
                )
        }
        .clipped()
    }
}

private struct ExerciseTrackingPreview: View {
    @Environment(\.modelContext) private var modelContext
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
