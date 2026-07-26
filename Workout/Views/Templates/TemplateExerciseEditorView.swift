// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  TemplateExerciseEditorView.swift
//  Workout
//
//  Per-exercise settings within a template: per-set weight/reps and rest time.
//  Loads existing TemplateSet rows; creates new ones on save.
//

import SwiftUI
import SwiftData

struct TemplateExerciseEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [UserSettings]
    private var userUnit: WeightUnit { allSettings.first?.unit ?? .kg }

    let templateExercise: TemplateExercise
    let onSave: () -> Void

    struct SetRow: Identifiable, Equatable {
        let id = UUID()
        var weight: Double
        var reps: Int
    }

    @State private var setRows: [SetRow]
    @State private var restSeconds: Int

    private var globalDefaultRestSeconds: Int {
        allSettings.first?.defaultRestTime ?? 90
    }

    init(templateExercise: TemplateExercise, onSave: @escaping () -> Void = {}) {
        self.templateExercise = templateExercise
        self.onSave = onSave
        _restSeconds = State(initialValue: templateExercise.restSeconds)

        let rows: [SetRow]
        if templateExercise.setTargets.isEmpty {
            rows = (0..<max(1, templateExercise.targetSets)).map { _ in
                SetRow(weight: templateExercise.targetWeight, reps: templateExercise.targetReps)
            }
        } else {
            rows = templateExercise.setTargets
                .sorted { $0.order < $1.order }
                .map { SetRow(weight: $0.targetWeight, reps: $0.targetReps) }
        }
        _setRows = State(initialValue: rows)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroImage

                    exerciseHeader

                    setsSection

                    restSection
                }
                .padding(16)
            }
            .background(AppStyle.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: setRows) { oldRows, newRows in
                // Find which index changed and cascade independently per field
                for i in oldRows.indices where i < newRows.count {
                    let old = oldRows[i]; let new = newRows[i]
                    if abs(new.weight - old.weight) > 0.001 {
                        for j in (i + 1)..<setRows.count {
                            if abs(setRows[j].weight - old.weight) < 0.001 { setRows[j].weight = new.weight } else { break }
                        }
                    }
                    if new.reps != old.reps {
                        for j in (i + 1)..<setRows.count {
                            if setRows[j].reps == old.reps { setRows[j].reps = new.reps } else { break }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        save()
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(setRows.isEmpty)
                }
            }
        }
    }

    // MARK: - Hero Image

    @ViewBuilder
    private var heroImage: some View {
        if templateExercise.exercise?.mediaFileName != nil {
            ExerciseImageView(
                mediaFileName: templateExercise.exercise?.mediaFileName,
                animated: true,
                cornerRadius: AppStyle.Radius.card,
                contentMode: .fit
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Exercise Header

    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(templateExercise.exercise?.name ?? "Exercise")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppStyle.Colors.text)

            if let exercise = templateExercise.exercise {
                HStack(spacing: 6) {
                    Text(exercise.difficulty.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppStyle.difficultyColor(exercise.difficulty))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppStyle.difficultyColor(exercise.difficulty).opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(exercise.primaryMusclesDisplayString)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppStyle.Colors.textSecondary.opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Text(exercise.equipmentDisplayString)
                    .font(.system(size: 14))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
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

    // MARK: - Sets Section

    private var setsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sets").sectionHeader()

            SetsListCard(rowCount: setRows.count, rowContent: { idx in
                setRowView(idx: idx)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if setRows.count > 1 {
                            Button(role: .destructive) {
                                setRows.remove(at: idx)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
            }, onAddSet: {
                let last = setRows.last
                setRows.append(SetRow(weight: last?.weight ?? 0, reps: last?.reps ?? 10))
            })
        }
    }

    private func setRowView(idx: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(idx + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppStyle.Colors.brand)
                .frame(width: 32, alignment: .leading)

            TextField("0", value: $setRows[idx].weight, format: .number)
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity)
                .setValueFieldStyle()
                .accessibilityIdentifier("templateSetWeightField")

            TextField("10", value: $setRows[idx].reps, format: .number)
                .keyboardType(.numberPad)
                .frame(maxWidth: .infinity)
                .setValueFieldStyle()
        }
        .padding(.horizontal, 16)
        .frame(height: SetsListRowMetrics.height)
    }

    // MARK: - Rest Section

    private var restSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rest Between Sets").sectionHeader()

            RestTimePickerField(seconds: $restSeconds, defaultSeconds: globalDefaultRestSeconds)
                .frame(width: 140)
        }
    }

    // MARK: - Save

    private func save() {
        for existing in templateExercise.setTargets {
            modelContext.delete(existing)
        }

        for (idx, row) in setRows.enumerated() {
            let ts = TemplateSet(order: idx, targetWeight: row.weight, targetReps: row.reps)
            ts.targetWeightUnit = userUnit.rawValue
            ts.templateExercise = templateExercise
            modelContext.insert(ts)
        }

        templateExercise.targetSets   = setRows.count
        templateExercise.targetReps   = setRows.first?.reps ?? 10
        templateExercise.targetWeight = setRows.first?.weight ?? 0
        templateExercise.targetWeightUnit = userUnit.rawValue
        templateExercise.restSeconds  = restSeconds
    }
}
