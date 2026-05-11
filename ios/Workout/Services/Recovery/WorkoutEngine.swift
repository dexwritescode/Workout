//
//  WorkoutEngine.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation
import SwiftData

/// Generates smart workout suggestions based on muscle recovery states,
/// user preferences, and available exercises.
struct WorkoutEngine {
    
    /// A suggested exercise with recommended sets/reps
    struct SuggestedExercise: Identifiable {
        let id = UUID()
        let exercise: Exercise
        let targetSets: Int
        let targetReps: Int
        let suggestedWeight: Double  // most recent max weight, 0 if no history
        let reason: String
    }
    
    /// A complete generated workout
    struct GeneratedWorkout {
        let name: String
        let exercises: [SuggestedExercise]
        let targetMuscles: [MuscleGroup]
        let estimatedDuration: Int // minutes
    }
    
    // MARK: - Generate Workout
    
    /// Generates a workout targeting the most recovered muscles based on user's split preference.
    static func generateWorkout(
        splitType: SplitType,
        recoveryStates: [MuscleRecoveryState],
        allExercises: [Exercise],
        recentSessions: [WorkoutSession]
    ) -> GeneratedWorkout {
        let targetMuscles = selectTargetMuscles(
            splitType: splitType,
            recoveryStates: recoveryStates,
            recentSessions: recentSessions
        )
        
        let exercises = selectExercises(
            targetMuscles: targetMuscles,
            allExercises: allExercises,
            recentSessions: recentSessions
        )
        
        let name = workoutName(for: targetMuscles, splitType: splitType)
        let estimatedMinutes = exercises.reduce(0) { $0 + $1.targetSets * 2 } + exercises.count * 2 // rough: 2 min/set + 2 min rest between exercises
        
        return GeneratedWorkout(
            name: name,
            exercises: exercises,
            targetMuscles: targetMuscles,
            estimatedDuration: max(20, estimatedMinutes)
        )
    }
    
    // MARK: - Target Muscle Selection
    
    /// Picks which muscles to train based on split type and recovery.
    private static func selectTargetMuscles(
        splitType: SplitType,
        recoveryStates: [MuscleRecoveryState],
        recentSessions: [WorkoutSession]
    ) -> [MuscleGroup] {
        // Build recovery lookup
        let recoveryMap: [MuscleGroup: Double] = Dictionary(
            uniqueKeysWithValues: recoveryStates.compactMap { state in
                guard let muscle = state.muscle else { return nil }
                return (muscle, state.currentRecoveryPercentage)
            }
        )
        
        let muscleGroups: [[MuscleGroup]]
        
        switch splitType {
        case .pushPullLegs:
            muscleGroups = [
                [.chest, .shoulders, .triceps],       // Push
                [.lats, .traps, .biceps, .forearms],  // Pull
                [.quadriceps, .hamstrings, .glutes, .calves] // Legs
            ]
        case .upperLower:
            muscleGroups = [
                [.chest, .shoulders, .biceps, .triceps, .lats, .traps, .forearms], // Upper
                [.quadriceps, .hamstrings, .glutes, .calves] // Lower
            ]
        case .fullBody:
            // Just pick the most recovered muscles across all groups
            let recovered = MuscleGroup.allCases
                .filter { (recoveryMap[$0] ?? 1.0) >= 0.70 }
                .sorted { (recoveryMap[$0] ?? 1.0) > (recoveryMap[$1] ?? 1.0) }
            return Array(recovered.prefix(6))
        case .bodypartSplit:
            muscleGroups = [
                [.chest, .triceps],
                [.lats, .biceps, .forearms],
                [.shoulders, .traps],
                [.quadriceps, .hamstrings, .glutes, .calves]
            ]
        }
        
        // Score each group by average recovery percentage — pick the most recovered group
        let scored = muscleGroups.map { group -> (muscles: [MuscleGroup], score: Double) in
            let avgRecovery = group.reduce(0.0) { $0 + (recoveryMap[$1] ?? 1.0) } / Double(group.count)
            return (group, avgRecovery)
        }
        
        let best = scored.max(by: { $0.score < $1.score })
        return best?.muscles ?? muscleGroups.first ?? []
    }
    
    // MARK: - Exercise Selection
    
    /// Picks 4-6 exercises for the target muscles, prioritizing compound movements first.
    private static func selectExercises(
        targetMuscles: [MuscleGroup],
        allExercises: [Exercise],
        recentSessions: [WorkoutSession]
    ) -> [SuggestedExercise] {
        // Find recently used exercise IDs to add variety
        let recentExerciseIDs: Set<UUID> = {
            let cutoff = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            return Set(
                recentSessions
                    .filter { $0.startTime > cutoff }
                    .flatMap { $0.completedExercises }
                    .compactMap { $0.exercise?.id }
            )
        }()
        
        // Filter exercises that hit our target muscles
        let candidates = allExercises.filter { exercise in
            exercise.primaryMuscleGroups.contains { targetMuscles.contains($0) }
        }
        
        // Score exercises: compound > isolation, not-recent > recent
        let scored = candidates.map { exercise -> (exercise: Exercise, score: Double) in
            var score = 0.0
            
            // Compound movements get a bonus
            if exercise.isCompound { score += 2.0 }
            
            // Exercises not done recently get a bonus
            if !recentExerciseIDs.contains(exercise.id) { score += 1.5 }
            
            // Beginner-friendly exercises get a small bonus for accessibility
            if exercise.difficulty == .beginner { score += 0.3 }
            if exercise.difficulty == .intermediate { score += 0.5 }
            
            return (exercise, score)
        }
        .sorted { $0.score > $1.score }
        
        // Pick top 5 exercises, ensuring we cover all target muscles
        var selected: [Exercise] = []
        var coveredMuscles: Set<MuscleGroup> = []
        
        // First pass: ensure each target muscle has at least one exercise
        for muscle in targetMuscles {
            if coveredMuscles.contains(muscle) { continue }
            if let best = scored.first(where: { item in
                item.exercise.primaryMuscleGroups.contains(muscle) && !selected.contains(where: { $0.id == item.exercise.id })
            }) {
                selected.append(best.exercise)
                coveredMuscles.formUnion(best.exercise.primaryMuscleGroups)
            }
        }
        
        // Second pass: fill up to 5 exercises with top-scored remaining
        for item in scored where selected.count < 5 {
            if !selected.contains(where: { $0.id == item.exercise.id }) {
                selected.append(item.exercise)
            }
        }
        
        // Convert to suggestions with sets/reps and historical weight
        return selected.enumerated().map { index, exercise in
            let (sets, reps) = recommendedSetsReps(for: exercise, order: index)
            let primaryNames = exercise.primaryMuscleGroups.map(\.rawValue).joined(separator: ", ")
            return SuggestedExercise(
                exercise: exercise,
                targetSets: sets,
                targetReps: reps,
                suggestedWeight: mostRecentMaxWeight(for: exercise, in: recentSessions),
                reason: "\(primaryNames) — \(exercise.isCompound ? "compound" : "isolation")"
            )
        }
    }
    
    // MARK: - Weight History

    /// Returns the heaviest weight recorded for an exercise across the user's most recent session
    /// that included it. Uses max weight so warm-up sets don't drag it down.
    private static func mostRecentMaxWeight(for exercise: Exercise, in sessions: [WorkoutSession]) -> Double {
        for session in sessions {
            let sets = session.completedExercises
                .filter { $0.exercise?.id == exercise.id }
                .flatMap { $0.sets.filter(\.isCompleted) }
            if !sets.isEmpty {
                return sets.map(\.weight).max() ?? 0
            }
        }
        return 0
    }

    // MARK: - Sets/Reps Recommendation
    
    /// Recommends sets and reps based on exercise type and position in the workout.
    private static func recommendedSetsReps(for exercise: Exercise, order: Int) -> (sets: Int, reps: Int) {
        if exercise.isCompound {
            // Compounds first: heavier, fewer reps
            return order < 2 ? (4, 8) : (3, 10)
        } else {
            // Isolation later: lighter, higher reps
            return (3, 12)
        }
    }
    
    // MARK: - Naming
    
    private static func workoutName(for muscles: [MuscleGroup], splitType: SplitType) -> String {
        switch splitType {
        case .pushPullLegs:
            if muscles.contains(.chest) { return "Push Day" }
            if muscles.contains(.lats) { return "Pull Day" }
            if muscles.contains(.quadriceps) { return "Leg Day" }
            return "Workout"
        case .upperLower:
            if muscles.contains(where: { $0.category == .lowerBody }) &&
               !muscles.contains(where: { $0.category == .upperBody }) {
                return "Lower Body"
            }
            return "Upper Body"
        case .fullBody:
            return "Full Body"
        case .bodypartSplit:
            let names = Array(Set(muscles.prefix(2).map(\.rawValue)))
            return names.joined(separator: " & ")
        }
    }
    
    // MARK: - Convert to Template
    
    /// Converts a generated workout into a WorkoutTemplate and inserts it into the model context.
    static func createTemplate(from workout: GeneratedWorkout, modelContext: ModelContext) -> WorkoutTemplate {
        let template = WorkoutTemplate(name: workout.name, description: "AI-generated workout")
        modelContext.insert(template)
        
        for (index, suggestion) in workout.exercises.enumerated() {
            let te = TemplateExercise(
                order: index,
                targetSets: suggestion.targetSets,
                targetReps: suggestion.targetReps
            )
            te.exercise = suggestion.exercise
            te.template = template
            te.targetWeight = suggestion.suggestedWeight
            modelContext.insert(te)
        }
        
        return template
    }
}
