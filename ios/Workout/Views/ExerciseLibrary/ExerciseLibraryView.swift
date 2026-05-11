//
//  ExerciseLibraryView.swift
//  Workout
//
//  Searchable grouped exercise list with filter support.
//

import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup?
    @State private var selectedDifficulty: DifficultyLevel?

    private var filteredExercises: [Exercise] {
        var result = allExercises

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { exercise in
                exercise.name.lowercased().contains(query) ||
                exercise.primaryMuscleGroups.contains { $0.rawValue.lowercased().contains(query) } ||
                exercise.equipment.contains { $0.lowercased().contains(query) }
            }
        }

        if let muscle = selectedMuscle {
            result = result.filter { $0.works(muscle: muscle) }
        }

        if let difficulty = selectedDifficulty {
            result = result.filter { $0.difficulty == difficulty }
        }

        return result
    }

    private var groupedExercises: [(String, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { exercise in
            exercise.primaryMuscleGroups.first?.rawValue ?? "Other"
        }
        return grouped.sorted { $0.key < $1.key }
    }

    private var hasActiveFilter: Bool {
        selectedMuscle != nil || selectedDifficulty != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header + Search
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Library")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.6)
                        Text("Exercises")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(AppStyle.Colors.text)
                    }

                    Spacer()

                    filterMenu
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(AppStyle.Colors.textTertiary)

                    TextField("Search exercises...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundStyle(AppStyle.Colors.text)
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(AppStyle.Colors.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppStyle.Colors.border, lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // Exercise list
            ScrollView {
                if groupedExercises.isEmpty {
                    if allExercises.isEmpty {
                        emptyState("No Exercises", subtitle: "Exercise database is empty.")
                    } else {
                        emptyState("No Results", subtitle: "No exercises match your search.")
                    }
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(groupedExercises, id: \.0) { muscleName, exercises in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(muscleName)
                                    .sectionHeader()
                                    .padding(.leading, 4)

                                VStack(spacing: 0) {
                                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                                        NavigationLink {
                                            ExerciseDetailView(exercise: exercise)
                                        } label: {
                                            exerciseRow(exercise, group: muscleName)
                                        }
                                        .buttonStyle(.plain)

                                        if index < exercises.count - 1 {
                                            AppStyle.Colors.border.frame(height: 1).padding(.leading, 14)
                                        }
                                    }
                                }
                                .background(AppStyle.Colors.surface1)
                                .clipShape(RoundedRectangle(cornerRadius: AppStyle.Radius.card))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppStyle.Radius.card)
                                        .stroke(AppStyle.Colors.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(AppStyle.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: searchText)
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            Menu("Muscle Group") {
                Button("All Muscles") { selectedMuscle = nil }
                Divider()
                ForEach(MuscleCategory.allCases, id: \.self) { category in
                    Section(category.rawValue) {
                        ForEach(category.muscles) { muscle in
                            Button {
                                selectedMuscle = (selectedMuscle == muscle) ? nil : muscle
                            } label: {
                                HStack {
                                    Text(muscle.rawValue)
                                    if selectedMuscle == muscle {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Menu("Difficulty") {
                Button("All Levels") { selectedDifficulty = nil }
                Divider()
                ForEach(DifficultyLevel.allCases) { level in
                    Button {
                        selectedDifficulty = (selectedDifficulty == level) ? nil : level
                    } label: {
                        HStack {
                            Text(level.rawValue)
                            if selectedDifficulty == level {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            if hasActiveFilter {
                Divider()
                Button("Clear Filters", role: .destructive) {
                    selectedMuscle = nil
                    selectedDifficulty = nil
                }
            }
        } label: {
            Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppStyle.Colors.textSecondary)
                .frame(width: 36, height: 36)
                .background(AppStyle.Colors.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppStyle.Colors.borderStrong, lineWidth: 1)
                )
                .contentTransition(.symbolEffect(.replace))
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise, group: String) -> some View {
        HStack(spacing: 12) {
            ExerciseImageView(
                mediaFileName: exercise.mediaFileName,
                animated: false,
                cornerRadius: 8
            )
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppStyle.Colors.text)

                HStack(spacing: 8) {
                    Text(group)
                        .font(.system(size: 13))
                        .foregroundStyle(AppStyle.Colors.textTertiary)

                    Text("·")
                        .foregroundStyle(AppStyle.Colors.textTertiary)

                    Text(exercise.difficulty.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppStyle.difficultyColor(exercise.difficulty))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppStyle.difficultyColor(exercise.difficulty).opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    if exercise.requiresEquipment {
                        Text("·")
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                        Text(exercise.equipmentDisplayString)
                            .font(.system(size: 13))
                            .foregroundStyle(AppStyle.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(AppStyle.Colors.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private func emptyState(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundStyle(AppStyle.Colors.textTertiary)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppStyle.Colors.text)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(AppStyle.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryView()
    }
    .modelContainer(for: Exercise.self, inMemory: true)
}
