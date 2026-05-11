//
//  Exercise.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation
import SwiftData

/// Represents an exercise that can be performed in a workout
/// Includes both pre-loaded exercises from the database and user-created custom exercises
@Model
final class Exercise {
    /// Unique identifier for the exercise
    @Attribute(.unique) var id: UUID
    
    /// Display name of the exercise (e.g., "Barbell Bench Press")
    var name: String
    
    /// Detailed description of the exercise
    var exerciseDescription: String
    
    /// Step-by-step instructions for performing the exercise
    var instructions: [String]
    
    /// Required equipment (stored as raw strings)
    var equipment: [String]
    
    /// Primary muscles worked (stored as MuscleGroup raw values)
    var primaryMuscles: [String]
    
    /// Secondary muscles worked (stored as MuscleGroup raw values)
    var secondaryMuscles: [String]
    
    /// Difficulty level (stored as DifficultyLevel raw value)
    var difficultyLevel: String
    
    /// Optional reference to media file (image/video/animation)
    var mediaFileName: String?
    
    /// Whether this is a user-created custom exercise (false for pre-loaded exercises)
    var isCustom: Bool
    
    /// When this exercise was created (for custom exercises) or loaded (for pre-loaded)
    var createdDate: Date
    
    // MARK: - Relationships
    
    /// Inverse relationship: Exercise appears in multiple workout templates
    @Relationship(deleteRule: .nullify, inverse: \TemplateExercise.exercise)
    var templateExercises: [TemplateExercise]?
    
    /// Inverse relationship: Exercise appears in multiple completed workouts
    @Relationship(deleteRule: .nullify, inverse: \CompletedExercise.exercise)
    var completedExercises: [CompletedExercise]?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        instructions: [String] = [],
        equipment: [String] = [],
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup] = [],
        difficultyLevel: DifficultyLevel = .intermediate,
        mediaFileName: String? = nil,
        isCustom: Bool = false,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.exerciseDescription = description
        self.instructions = instructions
        self.equipment = equipment
        self.primaryMuscles = primaryMuscles.map { $0.rawValue }
        self.secondaryMuscles = secondaryMuscles.map { $0.rawValue }
        self.difficultyLevel = difficultyLevel.rawValue
        self.mediaFileName = mediaFileName
        self.isCustom = isCustom
        self.createdDate = createdDate
    }
    
    // MARK: - Computed Properties
    
    /// Type-safe access to primary muscle groups
    var primaryMuscleGroups: [MuscleGroup] {
        primaryMuscles.compactMap { MuscleGroup(rawValue: $0) }
    }
    
    /// Type-safe access to secondary muscle groups
    var secondaryMuscleGroups: [MuscleGroup] {
        secondaryMuscles.compactMap { MuscleGroup(rawValue: $0) }
    }
    
    /// All muscle groups worked by this exercise (primary + secondary)
    var allMuscleGroups: [MuscleGroup] {
        primaryMuscleGroups + secondaryMuscleGroups
    }
    
    /// Type-safe access to difficulty level
    var difficulty: DifficultyLevel {
        DifficultyLevel(rawValue: difficultyLevel) ?? .intermediate
    }
    
    /// Human-readable list of primary muscles (e.g., "Chest, Shoulders")
    var primaryMusclesDisplayString: String {
        primaryMuscleGroups.map { $0.rawValue }.joined(separator: ", ")
    }
    
    /// Human-readable list of secondary muscles
    var secondaryMusclesDisplayString: String {
        guard !secondaryMuscleGroups.isEmpty else { return "None" }
        return secondaryMuscleGroups.map { $0.rawValue }.joined(separator: ", ")
    }
    
    /// Human-readable equipment list (e.g., "Barbell, Flat Bench")
    var equipmentDisplayString: String {
        guard !equipment.isEmpty else { return "Bodyweight" }
        return equipment.joined(separator: ", ")
    }
    
    /// Whether this exercise requires equipment
    var requiresEquipment: Bool {
        !equipment.isEmpty && !equipment.contains("Bodyweight")
    }
    
    /// Whether this exercise is a compound movement (works multiple muscle groups)
    var isCompound: Bool {
        primaryMuscleGroups.count > 1 || !secondaryMuscleGroups.isEmpty
    }
}

// MARK: - CustomStringConvertible

extension Exercise: CustomStringConvertible {
    var description: String {
        """
        Exercise: \(name)
        Difficulty: \(difficulty.rawValue)
        Primary Muscles: \(primaryMusclesDisplayString)
        Secondary Muscles: \(secondaryMusclesDisplayString)
        Equipment: \(equipmentDisplayString)
        Custom: \(isCustom)
        """
    }
}

// MARK: - Helper Methods

extension Exercise {
    /// Check if this exercise works a specific muscle group (primary or secondary)
    func works(muscle: MuscleGroup) -> Bool {
        allMuscleGroups.contains(muscle)
    }
    
    /// Check if this exercise works any muscles in the given category
    func works(category: MuscleCategory) -> Bool {
        allMuscleGroups.contains { $0.category == category }
    }
    
    /// Check if this exercise uses specific equipment
    func uses(equipment: String) -> Bool {
        self.equipment.contains(equipment)
    }
    
    /// Create a copy of this exercise (useful for creating variations)
    func duplicate(newName: String? = nil, asCustom: Bool = true) -> Exercise {
        Exercise(
            name: newName ?? "\(name) (Copy)",
            description: exerciseDescription,
            instructions: instructions,
            equipment: equipment,
            primaryMuscles: primaryMuscleGroups,
            secondaryMuscles: secondaryMuscleGroups,
            difficultyLevel: difficulty,
            mediaFileName: mediaFileName,
            isCustom: asCustom
        )
    }
}
