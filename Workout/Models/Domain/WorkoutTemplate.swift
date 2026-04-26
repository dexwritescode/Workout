//
//  WorkoutTemplate.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation
import SwiftData

// MARK: - WorkoutTemplate

/// Represents a reusable workout template containing a sequence of exercises
/// Can be pre-built (provided by the app) or user-created
@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var templateDescription: String
    var isPreBuilt: Bool
    var createdDate: Date
    var lastUsedDate: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]
    
    @Relationship(deleteRule: .nullify, inverse: \WorkoutSession.template)
    var sessions: [WorkoutSession]?
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        isPreBuilt: Bool = false,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.templateDescription = description
        self.isPreBuilt = isPreBuilt
        self.createdDate = createdDate
        self.exercises = []
    }
}

// MARK: - TemplateExercise

/// Represents an exercise within a workout template with target sets/reps
@Model
final class TemplateExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double = 0
    var restSeconds: Int
    var notes: String?
    
    var template: WorkoutTemplate?
    var exercise: Exercise?
    
    init(
        id: UUID = UUID(),
        order: Int,
        targetSets: Int,
        targetReps: Int,
        restSeconds: Int = 90,
        notes: String? = nil
    ) {
        self.id = id
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restSeconds = restSeconds
        self.notes = notes
    }
}

// MARK: - WorkoutSession

/// Represents a completed (or in-progress) workout session
@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var notes: String?
    var isCompleted: Bool
    
    var template: WorkoutTemplate?
    
    @Relationship(deleteRule: .cascade, inverse: \CompletedExercise.session)
    var completedExercises: [CompletedExercise]
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        template: WorkoutTemplate? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.template = template
        self.isCompleted = false
        self.completedExercises = []
    }
    
    /// Duration of the workout (nil if not yet finished)
    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// The calendar date of the workout
    var date: Date {
        startTime
    }
}

// MARK: - CompletedExercise

/// Represents an exercise performed during a workout session
@Model
final class CompletedExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var notes: String?
    
    var session: WorkoutSession?
    var exercise: Exercise?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.completedExercise)
    var sets: [ExerciseSet]
    
    init(id: UUID = UUID(), order: Int, notes: String? = nil) {
        self.id = id
        self.order = order
        self.notes = notes
        self.sets = []
    }
}

// MARK: - ExerciseSet

/// Represents a single set within a completed exercise (weight, reps, etc.)
@Model
final class ExerciseSet {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    var completedAt: Date?
    var rpe: Int?  // Rate of Perceived Exertion (1-10)
    
    var completedExercise: CompletedExercise?
    
    init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double = 0,
        reps: Int = 0,
        isCompleted: Bool = false,
        rpe: Int? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
        self.rpe = rpe
    }
}
