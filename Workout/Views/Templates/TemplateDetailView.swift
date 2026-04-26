//
//  TemplateDetailView.swift
//  Workout
//
//  Preview and launch point for a workout template.
//  Houses Edit and Delete so the picker row stays clean.
//

import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let template: WorkoutTemplate

    @State private var showEdit = false
    @State private var showDeleteConfirmation = false
    @State private var showActiveWorkout = false

    private var sortedExercises: [TemplateExercise] {
        template.exercises.sorted { $0.order < $1.order }
    }

    private var estimatedMinutes: Int {
        let totalSets = template.exercises.reduce(0) { $0 + $1.targetSets }
        return max(20, totalSets * 2 + template.exercises.count * 2)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statsRow
                        .padding(.horizontal, 16)

                    if !template.templateDescription.isEmpty {
                        Text(template.templateDescription)
                            .font(.system(size: 14))
                            .foregroundStyle(AppStyle.Colors.textSecondary)
                            .padding(.horizontal, 16)
                    }

                    if sortedExercises.isEmpty {
                        emptyExercises
                    } else {
                        VStack(spacing: 6) {
                            ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, te in
                                exerciseRow(te, index: index)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .background(AppStyle.Colors.background)

            Divider()
                .overlay(AppStyle.Colors.border)

            Button {
                showActiveWorkout = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15))
                    Text("Start Workout")
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(sortedExercises.isEmpty)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppStyle.Colors.background)
        }
        .background(AppStyle.Colors.background)
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit Template", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Template", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            TemplateEditorView(template: template)
        }
        .confirmationDialog(
            "Delete \"\(template.name)\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Template", role: .destructive) {
                modelContext.delete(template)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .fullScreenCover(isPresented: $showActiveWorkout) {
            NavigationStack {
                ActiveWorkoutView(template: template, modelContext: modelContext, autoStart: true)
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 8) {
            statPill(icon: "square.grid.2x2", label: "\(template.exercises.count) exercises")
            statPill(icon: "clock", label: "~\(estimatedMinutes) min")
            if let lastUsed = template.lastUsedDate {
                statPill(icon: "calendar", label: lastUsed.formatted(.relative(presentation: .named)))
            }
        }
    }

    private func statPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(label)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(AppStyle.Colors.textSecondary)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(AppStyle.Colors.surface2)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.medium))
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ te: TemplateExercise, index: Int) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppStyle.Colors.brand.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppStyle.Colors.brand)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(te.exercise?.name ?? "Unknown")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.text)

                let weightText = te.targetWeight > 0
                    ? " · \(String(format: "%.1f", te.targetWeight)) kg"
                    : ""
                Text("\(te.targetSets) sets × \(te.targetReps) reps\(weightText)")
                    .font(.system(size: 13))
                    .foregroundStyle(AppStyle.Colors.textTertiary)
            }

            Spacer()

            if let muscle = te.exercise?.primaryMusclesDisplayString {
                Text(muscle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(AppStyle.Colors.textSecondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
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

    // MARK: - Empty State

    private var emptyExercises: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack")
                .font(.system(size: 36))
                .foregroundStyle(AppStyle.Colors.textTertiary)
            Text("No exercises yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
            Button("Edit Template") { showEdit = true }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.brand)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

#Preview {
    NavigationStack {
        TemplateDetailView(template: {
            let t = WorkoutTemplate(name: "Push Day A", description: "Chest, shoulders, triceps")
            return t
        }())
    }
    .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}
