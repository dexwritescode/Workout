//
//  TemplateEditorView.swift
//  Workout
//
//  Create or edit a workout template.
//  Each exercise shows per-set rows (weight × reps) so you can plan
//  warm-up sets, working sets, and drop sets independently.
//

import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var templateDescription: String
    @State private var exerciseEntries: [ExerciseEntry]
    @State private var showExercisePicker = false

    private let existingTemplate: WorkoutTemplate?

    // MARK: - Local data types

    struct SetRow: Identifiable {
        let id = UUID()
        var weight: Double = 0
        var reps: Int = 10
    }

    struct ExerciseEntry: Identifiable {
        let id = UUID()
        let exercise: Exercise
        var setRows: [SetRow]
        var restSeconds: Int = 90
    }

    // MARK: - Init

    init() {
        self.existingTemplate = nil
        _name = State(initialValue: "")
        _templateDescription = State(initialValue: "")
        _exerciseEntries = State(initialValue: [])
    }

    init(template: WorkoutTemplate) {
        self.existingTemplate = template
        _name = State(initialValue: template.name)
        _templateDescription = State(initialValue: template.templateDescription)

        let entries: [ExerciseEntry] = template.exercises
            .sorted { $0.order < $1.order }
            .compactMap { te in
                guard let exercise = te.exercise else { return nil }
                let rows: [SetRow]
                if te.setTargets.isEmpty {
                    rows = (0..<max(1, te.targetSets)).map { _ in
                        SetRow(weight: te.targetWeight, reps: te.targetReps)
                    }
                } else {
                    rows = te.setTargets
                        .sorted { $0.order < $1.order }
                        .map { SetRow(weight: $0.targetWeight, reps: $0.targetReps) }
                }
                return ExerciseEntry(exercise: exercise, setRows: rows, restSeconds: te.restSeconds)
            }
        _exerciseEntries = State(initialValue: entries)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !exerciseEntries.isEmpty &&
        exerciseEntries.allSatisfy { !$0.setRows.isEmpty }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Details
                Section {
                    TextField("Template Name", text: $name)
                        .foregroundStyle(AppStyle.Colors.text)
                    TextField("Description (optional)", text: $templateDescription)
                        .foregroundStyle(AppStyle.Colors.text)
                } header: {
                    Text("Details").sectionHeader()
                }
                .listRowBackground(AppStyle.Colors.surface1)
                .listRowSeparatorTint(AppStyle.Colors.border)

                // One section per exercise
                ForEach(Array(exerciseEntries.indices), id: \.self) { idx in
                    exerciseSection(idx: idx)
                }

                // Add Exercise
                Section {
                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .foregroundStyle(AppStyle.Colors.brand)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .listRowBackground(AppStyle.Colors.surface1)
            }
            .scrollContentBackground(.hidden)
            .background(AppStyle.Colors.background)
            .navigationTitle(existingTemplate != nil ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    let defaultRows = [SetRow(), SetRow(), SetRow()]
                    exerciseEntries.append(ExerciseEntry(exercise: exercise, setRows: defaultRows))
                }
            }
        }
    }

    // MARK: - Exercise Section

    @ViewBuilder
    private func exerciseSection(idx: Int) -> some View {
        let entry = exerciseEntries[idx]

        Section {
            // Per-set rows
            ForEach(Array(entry.setRows.indices), id: \.self) { setIdx in
                setRowView(exerciseIdx: idx, setIdx: setIdx)
            }

            // Add Set
            Button {
                let last = exerciseEntries[idx].setRows.last
                exerciseEntries[idx].setRows.append(
                    SetRow(weight: last?.weight ?? 0, reps: last?.reps ?? 10)
                )
            } label: {
                Label("Add Set", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.brand)
            }

            // Rest picker
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 13))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                Text("Rest")
                    .font(.system(size: 14))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                Spacer()
                Picker("", selection: $exerciseEntries[idx].restSeconds) {
                    Text("30 sec").tag(30)
                    Text("1 min").tag(60)
                    Text("90 sec").tag(90)
                    Text("2 min").tag(120)
                    Text("3 min").tag(180)
                    Text("5 min").tag(300)
                }
                .pickerStyle(.menu)
                .tint(AppStyle.Colors.brand)
            }
        } header: {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.exercise.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.text)
                        .textCase(nil)
                    Text(entry.exercise.primaryMusclesDisplayString)
                        .font(.system(size: 11))
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                        .textCase(nil)
                }
                Spacer()
                Button {
                    exerciseEntries.remove(at: idx)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(AppStyle.Colors.error)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)
        }
        .listRowBackground(AppStyle.Colors.surface1)
        .listRowSeparatorTint(AppStyle.Colors.border)
    }

    // MARK: - Set Row

    private func setRowView(exerciseIdx: Int, setIdx: Int) -> some View {
        HStack(spacing: 0) {
            Text("Set \(setIdx + 1)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.brand)
                .frame(width: 52, alignment: .leading)

            Spacer()

            // Weight
            TextField("0", value: $exerciseEntries[exerciseIdx].setRows[setIdx].weight, format: .number)
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

            // Reps
            TextField("10", value: $exerciseEntries[exerciseIdx].setRows[setIdx].reps, format: .number)
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
                guard exerciseEntries[exerciseIdx].setRows.count > 1 else { return }
                exerciseEntries[exerciseIdx].setRows.remove(at: setIdx)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(exerciseEntries[exerciseIdx].setRows.count > 1
                        ? AppStyle.Colors.error
                        : AppStyle.Colors.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(exerciseEntries[exerciseIdx].setRows.count <= 1)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Save

    private func save() {
        if let existing = existingTemplate {
            updateExisting(existing)
        } else {
            createNew()
        }
        dismiss()
    }

    private func createNew() {
        let template = WorkoutTemplate(
            name: name.trimmingCharacters(in: .whitespaces),
            description: templateDescription.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(template)
        insertExercises(for: template)
    }

    private func updateExisting(_ template: WorkoutTemplate) {
        template.name = name.trimmingCharacters(in: .whitespaces)
        template.templateDescription = templateDescription.trimmingCharacters(in: .whitespaces)
        for te in template.exercises { modelContext.delete(te) }
        insertExercises(for: template)
    }

    private func insertExercises(for template: WorkoutTemplate) {
        for (idx, entry) in exerciseEntries.enumerated() {
            let te = TemplateExercise(
                order: idx,
                targetSets: entry.setRows.count,
                targetReps: entry.setRows.first?.reps ?? 10,
                restSeconds: entry.restSeconds
            )
            te.targetWeight = entry.setRows.first?.weight ?? 0
            te.exercise = entry.exercise
            te.template = template
            modelContext.insert(te)

            for (setIdx, row) in entry.setRows.enumerated() {
                let ts = TemplateSet(order: setIdx, targetWeight: row.weight, targetReps: row.reps)
                ts.templateExercise = te
                modelContext.insert(ts)
            }
        }
    }
}

#Preview("Create") {
    TemplateEditorView()
        .modelContainer(for: [WorkoutTemplate.self, Exercise.self, TemplateSet.self], inMemory: true)
}
