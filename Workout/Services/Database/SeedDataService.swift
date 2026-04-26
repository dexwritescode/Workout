//
//  SeedDataService.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation
import SwiftData

/// Loads the bundled exercise database into SwiftData on first launch
struct SeedDataService {
    
    // MARK: - JSON Decodable
    
    /// Intermediate struct for decoding exercises.json
    private struct ExerciseJSON: Decodable {
        let id: String
        let name: String
        let description: String
        let instructions: [String]
        let equipment: [String]
        let primaryMuscles: [String]
        let secondaryMuscles: [String]
        let difficultyLevel: String
    }
    
    private struct ExerciseFile: Decodable {
        let exercises: [ExerciseJSON]
    }
    
    // MARK: - Public API
    
    /// Seeds the exercise database, sample templates, and default settings on first launch.
    /// Call this on app launch with the model context.
    @MainActor
    static func seedIfNeeded(modelContext: ModelContext) {
        seedExercises(modelContext: modelContext)
        seedDefaultSettings(modelContext: modelContext)
        seedSampleTemplates(modelContext: modelContext)
        seedRecoveryStates(modelContext: modelContext)
    }
    
    // MARK: - Recovery States
    
    @MainActor
    private static func seedRecoveryStates(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<MuscleRecoveryState>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }
        
        for muscle in MuscleGroup.allCases {
            let state = MuscleRecoveryState(muscleGroup: muscle, fatigueLevel: 0.0)
            modelContext.insert(state)
        }
        try? modelContext.save()
    }
    
    // MARK: - Exercise Seeding
    
    @MainActor
    private static func seedExercises(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }
        
        do {
            let exercises = try loadExercisesFromBundle()
            for exercise in exercises {
                modelContext.insert(exercise)
            }
            try modelContext.save()
        } catch {
            print("SeedDataService: Failed to seed exercises — \(error)")
        }
    }
    
    // MARK: - Default Settings
    
    @MainActor
    private static func seedDefaultSettings(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserSettings>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }
        
        let settings = UserSettings()
        modelContext.insert(settings)
        try? modelContext.save()
    }
    
    // MARK: - Sample Templates
    
    @MainActor
    private static func seedSampleTemplates(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }
        
        // Look up exercises by name to build the template
        let exerciseNames = [
            "Barbell Bench Press",
            "Incline Dumbbell Press",
            "Cable Flyes",
            "Barbell Overhead Press",
            "Dumbbell Lateral Raise",
            "Cable Tricep Pushdown",
        ]
        
        let template = WorkoutTemplate(
            name: "Push Day A",
            description: "Chest, shoulders, and triceps",
            isPreBuilt: true
        )
        modelContext.insert(template)
        
        for (index, name) in exerciseNames.enumerated() {
            var fetchDescriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate { $0.name == name }
            )
            fetchDescriptor.fetchLimit = 1
            
            let exercise = try? modelContext.fetch(fetchDescriptor).first
            
            let templateExercise = TemplateExercise(
                order: index,
                targetSets: index < 2 ? 4 : 3,  // Compound lifts get 4 sets
                targetReps: index < 2 ? 8 : 12   // Compound lifts get lower reps
            )
            templateExercise.template = template
            templateExercise.exercise = exercise
            modelContext.insert(templateExercise)
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Private
    
    /// Loads and decodes exercises.json from the app bundle, returning SwiftData Exercise models
    private static func loadExercisesFromBundle() throws -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            throw SeedError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(ExerciseFile.self, from: data)
        
        return decoded.exercises.compactMap { json in
            guard let uuid = UUID(uuidString: json.id) else {
                print("SeedDataService: Invalid UUID for exercise '\(json.name)', skipping")
                return nil
            }
            
            let primaryMuscles = json.primaryMuscles.compactMap { MuscleGroup(rawValue: $0) }
            let secondaryMuscles = json.secondaryMuscles.compactMap { MuscleGroup(rawValue: $0) }
            let difficulty = DifficultyLevel(rawValue: json.difficultyLevel) ?? .intermediate
            
            guard !primaryMuscles.isEmpty else {
                print("SeedDataService: No valid primary muscles for '\(json.name)', skipping")
                return nil
            }
            
            return Exercise(
                id: uuid,
                name: json.name,
                description: json.description,
                instructions: json.instructions,
                equipment: json.equipment,
                primaryMuscles: primaryMuscles,
                secondaryMuscles: secondaryMuscles,
                difficultyLevel: difficulty,
                isCustom: false
            )
        }
    }
    
    // MARK: - Errors
    
    enum SeedError: Error, LocalizedError {
        case fileNotFound
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "exercises.json not found in app bundle"
            }
        }
    }
}
