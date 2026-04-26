//
//  TemplateEditorView.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import SwiftUI
import SwiftData

/// Form for creating or editing a workout template.
/// Allows setting name, description, and managing exercises with sets/reps.
struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var templateDescription: String
    @State private var exerciseEntries: [ExerciseEntry]
    @State private var showExercisePicker = false

    private let existingTemplate: WorkoutTemplate?

    /// Tracks an exercise to be added to the template with configurable sets/reps
    struct ExerciseEntry: Identifiable {
        let id = UUID()
        let exercise: Exercise
        var targetSets: Int
        var targetReps: Int
        var targetWeight: Double
        var restSeconds: Int
    }

    // MARK: - Create Mode

    init() {
        self.existingTemplate = nil
        _name = State(initialValue: "")
        _templateDescription = State(initialValue: "")
        _exerciseEntries = State(initialValue: [])
    }

    // MARK: - Edit Mode

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

    private var isEditing: Bool {
        existingTemplate != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    Text(isEditing ? "Edit Template" : "New Template")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(AppStyle.Colors.text)
                        .padding(.bottom, 20)

                    // Details
                    cardSection("Details") {
                        VStack(spacing: 0) {
                            TextField("Template Name", text: $name)
                                .font(.system(size: 16))
                                .foregroundStyle(AppStyle.Colors.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)

                            AppStyle.Colors.border.frame(height: 1).padding(.leading, 16)

                            TextField("Description (optional)", text: $templateDescription)
                                .font(.system(size: 16))
                                .foregroundStyle(AppStyle.Colors.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                        }
                    }

                    // Exercises
                    cardSection("Exercises") {
                        if exerciseEntries.isEmpty {
                            Text("No exercises added yet")
                                .font(.system(size: 15))
                                .foregroundStyle(AppStyle.Colors.textTertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        } else {
                            ForEach(Array(exerciseEntries.enumerated()), id: \.element.id) { index, _ in
                                if index > 0 {
                                    AppStyle.Colors.border.frame(height: 1).padding(.leading, 16)
                                }
                                exerciseEntryRow(entry: $exerciseEntries[index], index: index)
                            }
                        }
                    }

                    // Add Exercise button
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
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppStyle.Colors.brand.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                                .stroke(AppStyle.Colors.brand.opacity(0.25), lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 16)

                    // Save button
                    Button {
                        save()
                    } label: {
                        Text("Save Template")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isValid ? AppStyle.Colors.text : AppStyle.Colors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isValid ? AppStyle.Colors.brand : AppStyle.Colors.surface3)
                            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
                    }
                    .disabled(!isValid)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
            }
            .background(AppStyle.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppStyle.Colors.textSecondary)
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

    // MARK: - Card Section

    private func cardSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .sectionHeader()
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(AppStyle.Colors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                    .stroke(AppStyle.Colors.border, lineWidth: 1)
            )
        }
        .padding(.bottom, 20)
    }

    // MARK: - Exercise Entry Row

    private func exerciseEntryRow(entry: Binding<ExerciseEntry>, index: Int) -> some View {
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
                    exerciseEntries.remove(at: index)
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

            // Weight input
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .animation(.easeInOut(duration: 0.2), value: exerciseEntries.count)
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

    // MARK: - Actions

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

        // Remove old template exercises
        for te in template.exercises {
            modelContext.delete(te)
        }

        // Create new ones in current order
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
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}
