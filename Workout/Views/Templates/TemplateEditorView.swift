//
//  TemplateEditorView.swift
//  Workout
//
//  Create or edit a workout template: name, description,
//  and an exercise list with drag-to-reorder support.
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

    struct ExerciseEntry: Identifiable {
        let id = UUID()
        let exercise: Exercise
        var targetSets: Int
        var targetReps: Int
        var targetWeight: Double
        var restSeconds: Int
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

        let entries = template.exercises
            .sorted { $0.order < $1.order }
            .compactMap { te -> ExerciseEntry? in
                guard let exercise = te.exercise else { return nil }
                return ExerciseEntry(
                    exercise: exercise,
                    targetSets: te.targetSets,
                    targetReps: te.targetReps,
                    targetWeight: te.targetWeight,
                    restSeconds: te.restSeconds
                )
            }
        _exerciseEntries = State(initialValue: entries)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !exerciseEntries.isEmpty
    }

    private var isEditing: Bool { existingTemplate != nil }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Details
                Section {
                    TextField("Template Name", text: $name)
                        .font(.system(size: 16))
                        .foregroundStyle(AppStyle.Colors.text)

                    TextField("Description (optional)", text: $templateDescription)
                        .font(.system(size: 16))
                        .foregroundStyle(AppStyle.Colors.text)
                } header: {
                    Text("Details").sectionHeader()
                }
                .listRowBackground(AppStyle.Colors.surface1)
                .listRowSeparatorTint(AppStyle.Colors.border)

                // Exercises
                Section {
                    if exerciseEntries.isEmpty {
                        Text("No exercises added yet")
                            .font(.system(size: 15))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .listRowBackground(AppStyle.Colors.surface1)
                    } else {
                        ForEach($exerciseEntries) { $entry in
                            exerciseEntryRow(entry: $entry)
                                .listRowBackground(AppStyle.Colors.surface1)
                                .listRowSeparatorTint(AppStyle.Colors.border)
                        }
                        .onMove { from, to in
                            exerciseEntries.move(fromOffsets: from, toOffset: to)
                        }
                    }
                } header: {
                    Text("Exercises").sectionHeader()
                }

                // Add Exercise
                Section {
                    Button {
                        showExercisePicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Exercise")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(AppStyle.Colors.brand)
                    }
                    .listRowBackground(AppStyle.Colors.surface1)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppStyle.Colors.background)
            .environment(\.editMode, .constant(.active))
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
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
                    exerciseEntries.append(ExerciseEntry(
                        exercise: exercise,
                        targetSets: 3,
                        targetReps: 10,
                        targetWeight: 0,
                        restSeconds: 90
                    ))
                }
            }
        }
    }

    // MARK: - Exercise Entry Row

    private func exerciseEntryRow(entry: Binding<ExerciseEntry>, index: Int? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.wrappedValue.exercise.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppStyle.Colors.text)
                    Text(entry.wrappedValue.exercise.primaryMusclesDisplayString)
                        .font(.system(size: 13))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }
                Spacer()
                Button {
                    if let idx = exerciseEntries.firstIndex(where: { $0.id == entry.id }) {
                        exerciseEntries.remove(at: idx)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(AppStyle.Colors.error)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                stepperControl(label: "Sets", value: entry.targetSets, range: 1...10)
                stepperControl(label: "Reps", value: entry.targetReps, range: 1...30)
            }

            HStack(spacing: 8) {
                Text("Weight")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.textSecondary)

                TextField("0", value: entry.targetWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .font(AppStyle.Typography.mono(14, weight: .bold))
                    .foregroundStyle(AppStyle.Colors.text)
                    .multilineTextAlignment(.center)
                    .frame(width: 60, height: 32)
                    .background(AppStyle.Colors.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.small))

                Text("kg")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppStyle.Colors.surface2)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.small))
        }
        .padding(.vertical, 4)
    }

    private func stepperControl(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppStyle.Colors.textSecondary)

            Button {
                if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue <= range.lowerBound)

            Text("\(value.wrappedValue)")
                .font(AppStyle.Typography.mono(16, weight: .bold))
                .foregroundStyle(AppStyle.Colors.text)
                .frame(minWidth: 24)
                .contentTransition(.numericText())

            Button {
                if value.wrappedValue < range.upperBound { value.wrappedValue += 1 }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppStyle.Colors.brand)
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue >= range.upperBound)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppStyle.Colors.surface2)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.small))
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

        for (index, entry) in exerciseEntries.enumerated() {
            let te = TemplateExercise(
                order: index,
                targetSets: entry.targetSets,
                targetReps: entry.targetReps,
                restSeconds: entry.restSeconds
            )
            te.targetWeight = entry.targetWeight
            te.exercise = entry.exercise
            te.template = template
            modelContext.insert(te)
        }
    }

    private func updateExisting(_ template: WorkoutTemplate) {
        template.name = name.trimmingCharacters(in: .whitespaces)
        template.templateDescription = templateDescription.trimmingCharacters(in: .whitespaces)

        for te in template.exercises {
            modelContext.delete(te)
        }

        for (index, entry) in exerciseEntries.enumerated() {
            let te = TemplateExercise(
                order: index,
                targetSets: entry.targetSets,
                targetReps: entry.targetReps,
                restSeconds: entry.restSeconds
            )
            te.targetWeight = entry.targetWeight
            te.exercise = entry.exercise
            te.template = template
            modelContext.insert(te)
        }
    }
}

#Preview("Create") {
    TemplateEditorView()
        .modelContainer(for: [WorkoutTemplate.self, Exercise.self], inMemory: true)
}
