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

    let templateExercise: TemplateExercise

    struct SetRow: Identifiable {
        let id = UUID()
        var weight: Double
        var reps: Int
    }

    @State private var setRows: [SetRow]
    @State private var restSeconds: Int

    private let restOptions: [(label: String, seconds: Int)] = [
        ("30 sec", 30),
        ("1 min",  60),
        ("90 sec", 90),
        ("2 min",  120),
        ("3 min",  180),
        ("5 min",  300),
    ]

    init(templateExercise: TemplateExercise) {
        self.templateExercise = templateExercise
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
            Form {
                exerciseHeader

                setsSection

                restSection
            }
            .scrollContentBackground(.hidden)
            .background(AppStyle.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(setRows.isEmpty)
                }
            }
        }
    }

    // MARK: - Exercise Header

    private var exerciseHeader: some View {
        Section {
            VStack(alignment: .leading, spacing: 5) {
                Text(templateExercise.exercise?.name ?? "Exercise")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppStyle.Colors.text)
                if let muscles = templateExercise.exercise?.primaryMusclesDisplayString {
                    Text(muscles)
                        .font(.system(size: 14))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
                if let isCompound = templateExercise.exercise?.isCompound {
                    Text(isCompound ? "Compound" : "Isolation")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isCompound ? AppStyle.Colors.compound : AppStyle.Colors.isolation)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((isCompound ? AppStyle.Colors.compound : AppStyle.Colors.isolation).opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(AppStyle.Colors.surface1)
    }

    // MARK: - Sets Section

    private var setsSection: some View {
        Section {
            ForEach(Array(setRows.indices), id: \.self) { idx in
                setRowView(idx: idx)
            }

            Button {
                let last = setRows.last
                setRows.append(SetRow(weight: last?.weight ?? 0, reps: last?.reps ?? 10))
            } label: {
                Label("Add Set", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.brand)
            }
        } header: {
            Text("Sets").sectionHeader()
        }
        .listRowBackground(AppStyle.Colors.surface1)
        .listRowSeparatorTint(AppStyle.Colors.border)
    }

    private func setRowView(idx: Int) -> some View {
        HStack(spacing: 0) {
            Text("Set \(idx + 1)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.brand)
                .frame(width: 52, alignment: .leading)

            Spacer()

            TextField("0", value: $setRows[idx].weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .font(AppStyle.Typography.mono(15, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
                .padding(.vertical, 5)
                .background(AppStyle.Colors.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text("kg")
                .font(.system(size: 12))
                .foregroundStyle(AppStyle.Colors.textTertiary)
                .padding(.horizontal, 5)

            Text("×")
                .font(.system(size: 13))
                .foregroundStyle(AppStyle.Colors.textTertiary)
                .padding(.horizontal, 5)

            TextField("10", value: $setRows[idx].reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 44)
                .font(AppStyle.Typography.mono(15, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
                .padding(.vertical, 5)
                .background(AppStyle.Colors.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text("reps")
                .font(.system(size: 12))
                .foregroundStyle(AppStyle.Colors.textTertiary)
                .padding(.leading, 5)

            Spacer()

            Button {
                guard setRows.count > 1 else { return }
                setRows.remove(at: idx)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(setRows.count > 1 ? AppStyle.Colors.error : AppStyle.Colors.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(setRows.count <= 1)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Rest Section

    private var restSection: some View {
        Section {
            Picker("Rest between sets", selection: $restSeconds) {
                ForEach(restOptions, id: \.seconds) { option in
                    Text(option.label).tag(option.seconds)
                }
            }
            .foregroundStyle(AppStyle.Colors.text)
            .pickerStyle(.menu)
            .tint(AppStyle.Colors.brand)
        } header: {
            Text("Rest Between Sets").sectionHeader()
        }
        .listRowBackground(AppStyle.Colors.surface1)
    }

    // MARK: - Save

    private func save() {
        for existing in templateExercise.setTargets {
            modelContext.delete(existing)
        }

        for (idx, row) in setRows.enumerated() {
            let ts = TemplateSet(order: idx, targetWeight: row.weight, targetReps: row.reps)
            ts.templateExercise = templateExercise
            modelContext.insert(ts)
        }

        templateExercise.targetSets   = setRows.count
        templateExercise.targetReps   = setRows.first?.reps ?? 10
        templateExercise.targetWeight = setRows.first?.weight ?? 0
        templateExercise.restSeconds  = restSeconds
    }
}
