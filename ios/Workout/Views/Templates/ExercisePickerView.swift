//
//  ExercisePickerView.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import SwiftUI
import SwiftData

/// Searchable list of exercises for adding to a workout template.
/// Groups exercises by primary muscle and supports search filtering.
struct ExercisePickerView: View {
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    let onSelect: (Exercise) -> Void

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return allExercises
        }
        let query = searchText.lowercased()
        return allExercises.filter { exercise in
            exercise.name.lowercased().contains(query) ||
            exercise.primaryMuscleGroups.contains { $0.rawValue.lowercased().contains(query) } ||
            exercise.equipment.contains { $0.lowercased().contains(query) }
        }
    }

    /// Groups filtered exercises by their first primary muscle
    private var groupedExercises: [(String, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { exercise in
            exercise.primaryMuscleGroups.first?.rawValue ?? "Other"
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                        TextField("Search exercises", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundStyle(AppStyle.Colors.text)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppStyle.Colors.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.Radius.medium)
                            .stroke(AppStyle.Colors.border, lineWidth: 1)
                    )
                    .padding(.bottom, 16)

                    if filteredExercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundStyle(AppStyle.Colors.textTertiary)
                            Text("No exercises found")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppStyle.Colors.text)
                            Text("Try a different search term.")
                                .font(.system(size: 14))
                                .foregroundStyle(AppStyle.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(groupedExercises, id: \.0) { muscleName, exercises in
                            muscleSection(muscleName, exercises: exercises)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(AppStyle.Colors.background)
            .animation(.easeInOut(duration: 0.2), value: searchText)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppStyle.Colors.textSecondary)
                }
            }
        }
    }

    private func muscleSection(_ name: String, exercises: [Exercise]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .sectionHeader()
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    if index > 0 {
                        AppStyle.Colors.border.frame(height: 1).padding(.leading, 16)
                    }
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        exerciseRow(exercise)
                    }
                    .buttonStyle(.plain)
                }
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

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppStyle.Colors.text)

                HStack(spacing: 6) {
                    Text(exercise.difficulty.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppStyle.difficultyColor(exercise.difficulty))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppStyle.difficultyColor(exercise.difficulty).opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                    if exercise.requiresEquipment {
                        Text(exercise.equipmentDisplayString)
                            .font(.system(size: 11))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppStyle.Colors.brand)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    ExercisePickerView { exercise in
        print("Selected: \(exercise.name)")
    }
    .modelContainer(for: Exercise.self, inMemory: true)
}
