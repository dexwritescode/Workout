// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  TemplateEditorView.swift
//  Workout
//
//  Create or edit a workout template. Exercises are staged against a real, persisted
//  WorkoutTemplate (draftKind == .templateStaging) rather than local structs, so tapping an
//  exercise can open the same TemplateExerciseEditorView used elsewhere in the app. Cancel clears
//  the staging row's exercises; Save copies them into the real target template.
//

import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var templateDescription: String
    @State private var stagingTemplate: WorkoutTemplate?
    @State private var showExercisePicker = false
    @State private var exerciseToEdit: TemplateExercise?

    private let existingTemplate: WorkoutTemplate?

    // MARK: - Init

    init() {
        self.existingTemplate = nil
        _name = State(initialValue: "")
        _templateDescription = State(initialValue: "")
    }

    init(template: WorkoutTemplate) {
        self.existingTemplate = template
        _name = State(initialValue: template.name)
        _templateDescription = State(initialValue: template.templateDescription)
    }

    private var sortedExercises: [TemplateExercise] {
        stagingTemplate?.exercises.sorted { $0.order < $1.order } ?? []
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !sortedExercises.isEmpty
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

                // Exercises
                Section {
                    ForEach(sortedExercises, id: \.id) { te in
                        exerciseRow(te)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteExercise(te)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                } header: {
                    Text("Exercises").sectionHeader()
                }
                .listRowBackground(AppStyle.Colors.surface1)
                .listRowSeparatorTint(AppStyle.Colors.border)

                // Add Exercise
                Section {
                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .foregroundStyle(AppStyle.Colors.brand)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .accessibilityIdentifier("addExerciseInTemplateEditor")
                }
                .listRowBackground(AppStyle.Colors.surface1)
            }
            .scrollContentBackground(.hidden)
            .background(AppStyle.Colors.background)
            .navigationTitle(existingTemplate != nil ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        stagingTemplate?.clearExercises(context: modelContext)
                        dismiss()
                    }
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(!isValid)
                }
            }
            .onAppear {
                guard stagingTemplate == nil else { return }
                if let existingTemplate {
                    let staging = WorkoutTemplate.stagingTemplate(kind: .templateStaging, in: modelContext)
                    staging.copyExercises(from: existingTemplate, context: modelContext)
                    stagingTemplate = staging
                } else {
                    if let stale = WorkoutTemplate.existingStagingTemplate(kind: .templateStaging, in: modelContext) {
                        modelContext.delete(stale)
                    }
                    stagingTemplate = WorkoutTemplate.stagingTemplate(kind: .templateStaging, in: modelContext)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    addExercise(exercise)
                }
            }
            .sheet(item: $exerciseToEdit) { te in
                TemplateExerciseEditorView(templateExercise: te)
            }
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ te: TemplateExercise) -> some View {
        Button {
            exerciseToEdit = te
        } label: {
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
                    Text("\(te.targetSets) sets · \(te.exercise?.primaryMusclesDisplayString ?? "")")
                        .font(.system(size: 13))
                        .foregroundStyle(AppStyle.Colors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func addExercise(_ exercise: Exercise) {
        guard let stagingTemplate else { return }
        let te = TemplateExercise(order: stagingTemplate.exercises.count, targetSets: 3, targetReps: 10, restSeconds: 0)
        te.exercise = exercise
        te.template = stagingTemplate
        modelContext.insert(te)
    }

    private func deleteExercise(_ te: TemplateExercise) {
        modelContext.delete(te)
    }

    // MARK: - Save

    private func save() {
        let target: WorkoutTemplate
        if let existingTemplate {
            target = existingTemplate
        } else {
            target = WorkoutTemplate(name: "")
            modelContext.insert(target)
        }

        target.name = name.trimmingCharacters(in: .whitespaces)
        target.templateDescription = templateDescription.trimmingCharacters(in: .whitespaces)

        if let stagingTemplate {
            target.copyExercises(from: stagingTemplate, context: modelContext)
            stagingTemplate.clearExercises(context: modelContext)
        }

        dismiss()
    }
}

#Preview("Create") {
    TemplateEditorView()
        .modelContainer(for: [WorkoutTemplate.self, Exercise.self, TemplateSet.self], inMemory: true)
}
