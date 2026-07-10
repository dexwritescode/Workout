// SPDX-License-Identifier: AGPL-3.0-or-later
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
    var isDraft: Bool = false
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

    // MARK: - Draft (Smart Workout staging area)

    /// Returns the single scratch template used to stage a Smart Workout draft before it's
    /// started (see WRK-51/WRK-52). Created lazily on first use, never seeded at launch.
    /// `isDraft` is set on the object before it is ever inserted/saved, so there is no
    /// persisted state where a draft row exists with `isDraft == false`.
    static func draft(in context: ModelContext) -> WorkoutTemplate {
        var descriptor = FetchDescriptor<WorkoutTemplate>(
            predicate: #Predicate { $0.isDraft == true }
        )
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let draft = WorkoutTemplate(name: "Draft")
        draft.isDraft = true
        context.insert(draft)
        try? context.save()
        return draft
    }

    /// Returns all real, user-visible templates — excludes the scratch draft row.
    /// Shared by `TemplatePickerView`'s query and anywhere else that lists templates.
    static func nonDraftTemplates(in context: ModelContext) -> [WorkoutTemplate] {
        var descriptor = FetchDescriptor<WorkoutTemplate>(
            predicate: #Predicate { $0.isDraft == false }
        )
        descriptor.sortBy = [SortDescriptor(\.name)]
        return (try? context.fetch(descriptor)) ?? []
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
    var targetWeightUnit: String = WeightUnit.kg.rawValue
    var restSeconds: Int

    @Relationship(deleteRule: .cascade, inverse: \TemplateSet.templateExercise)
    var setTargets: [TemplateSet]

    var template: WorkoutTemplate?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        order: Int,
        targetSets: Int,
        targetReps: Int,
        restSeconds: Int = 0
    ) {
        self.id = id
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restSeconds = restSeconds
        self.setTargets = []
    }
}

// MARK: - TemplateSet

/// One planned set within a TemplateExercise — lets you define different weight/reps per set.
@Model
final class TemplateSet {
    @Attribute(.unique) var id: UUID
    var order: Int
    var targetWeight: Double
    var targetWeightUnit: String = WeightUnit.kg.rawValue
    var targetReps: Int

    var templateExercise: TemplateExercise?

    init(order: Int, targetWeight: Double = 0, targetReps: Int = 10) {
        self.id = UUID()
        self.order = order
        self.targetWeight = targetWeight
        self.targetReps = targetReps
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
    var sessionTitle: String?
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
    
    var displayName: String { sessionTitle ?? template?.name ?? "Workout" }

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

    var session: WorkoutSession?
    var exercise: Exercise?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.completedExercise)
    var sets: [ExerciseSet]
    
    init(id: UUID = UUID(), order: Int) {
        self.id = id
        self.order = order
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
    var weightUnit: String = WeightUnit.kg.rawValue
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

    var storedWeightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnit) ?? .kg
    }
}

extension TemplateExercise {
    var storedTargetWeightUnit: WeightUnit {
        WeightUnit(rawValue: targetWeightUnit) ?? .kg
    }
}

extension TemplateSet {
    var storedTargetWeightUnit: WeightUnit {
        WeightUnit(rawValue: targetWeightUnit) ?? .kg
    }
}
