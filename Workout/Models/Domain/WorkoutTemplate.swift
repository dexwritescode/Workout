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

    /// Stored as a raw String (not the enum directly) for #Predicate compatibility — same
    /// convention as MuscleGroup/WeightUnit/WorkoutStartMode elsewhere in the model layer.
    /// nil means a real, permanent, user-visible template.
    var draftKindRaw: String? = nil
    var createdDate: Date
    var lastUsedDate: Date?

    /// The real template this draft's exercises were last loaded from, if any (nil after a fresh
    /// AI generation). Meaningful only for the `.workoutStaging` draft.
    var sourceTemplateID: UUID? = nil
    var timesStarted: Int = 0

    /// Which weekday the day-template schedule system last auto-populated the draft for, if any.
    /// `nil` means whatever's currently staged was placed there by the user (Load Template,
    /// Regenerate, or hand-edits) — distinguishes an auto-load from a deliberate same-day
    /// override so the next appear's schedule check doesn't silently clobber it. Meaningful only
    /// for the `.workoutStaging` draft.
    var autoLoadedForWeekday: Int? = nil

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]

    @Relationship(deleteRule: .nullify, inverse: \WorkoutSession.template)
    var sessions: [WorkoutSession]?

    @Relationship(deleteRule: .nullify, inverse: \DayTemplateAssignment.template)
    var dayAssignments: [DayTemplateAssignment]?

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

    // MARK: - Staging rows (Smart Workout draft + Template Editor scratch buffer)

    enum TemplateKind: String, Codable {
        case workoutStaging
        case templateStaging
    }

    var draftKind: TemplateKind? {
        get { draftKindRaw.flatMap(TemplateKind.init(rawValue:)) }
        set { draftKindRaw = newValue?.rawValue }
    }

    /// Fetches the single scratch row for the given kind, if one already exists — does not create.
    static func existingStagingTemplate(kind: TemplateKind, in context: ModelContext) -> WorkoutTemplate? {
        let kindRaw = kind.rawValue
        var descriptor = FetchDescriptor<WorkoutTemplate>(
            predicate: #Predicate { $0.draftKindRaw == kindRaw }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Returns the single scratch template used to stage either the Smart Workout draft or the
    /// Template Editor's in-progress edits, depending on `kind`. Created lazily on first use,
    /// never seeded at launch. `draftKind` is set on the object before it is ever inserted/saved,
    /// so there is no persisted state where a staging row exists with `draftKind == nil`.
    static func stagingTemplate(kind: TemplateKind, in context: ModelContext) -> WorkoutTemplate {
        if let existing = existingStagingTemplate(kind: kind, in: context) {
            return existing
        }

        let staging = WorkoutTemplate(name: "Draft")
        staging.draftKind = kind
        context.insert(staging)
        try? context.save()
        return staging
    }

    /// Returns all real, user-visible templates — excludes any scratch staging row.
    /// Shared by `TemplatePickerView`'s query and anywhere else that lists templates.
    static func nonDraftTemplates(in context: ModelContext) -> [WorkoutTemplate] {
        var descriptor = FetchDescriptor<WorkoutTemplate>(
            predicate: #Predicate { $0.draftKindRaw == nil }
        )
        descriptor.sortBy = [SortDescriptor(\.name)]
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetches a specific template by id — used to resolve a draft's `sourceTemplateID` back to
    /// the real template it was loaded from.
    static func template(withID id: UUID, in context: ModelContext) -> WorkoutTemplate? {
        var descriptor = FetchDescriptor<WorkoutTemplate>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    // MARK: - Draft mutation

    /// Deletes all of this template's exercises (and their cascading sets). Used both by the
    /// rebuild/load operations below and to clean up a staging row when it's no longer needed
    /// (Template Editor cancel, or after its contents have been committed to a real template).
    func clearExercises(context: ModelContext) {
        // context.delete() alone doesn't retroactively clear an already-held relationship array,
        // so remove from `exercises` explicitly first (same pattern as removeExercise(at:) in
        // ActiveWorkoutViewModel) rather than relying on a later fetch to reflect the deletion.
        let existing = exercises
        exercises.removeAll()
        for te in existing { context.delete(te) }
    }

    /// Deep-copies another template's exercises into this template's own rows, replacing whatever
    /// was there. Never a live reference; the source template is left untouched. Pure exercise
    /// copy only — no source-tracking fields touched, safe to use in either direction (workout
    /// draft ⇠ real template, or real template ⇠ Template Editor's staging row).
    func copyExercises(from source: WorkoutTemplate, context: ModelContext) {
        clearExercises(context: context)
        for sourceExercise in source.exercises.sorted(by: { $0.order < $1.order }) {
            let copy = sourceExercise.duplicated(in: context)
            copy.template = self
        }
    }

    /// Rebuilds this template's exercises from a fresh AI generation, discarding whatever was
    /// staged before. Clears `sourceTemplateID` since this content has no real-template source.
    func rebuildExercises(from workout: WorkoutEngine.GeneratedWorkout, context: ModelContext) {
        clearExercises(context: context)

        for (index, suggestion) in workout.exercises.enumerated() {
            let te = TemplateExercise(
                order: index,
                targetSets: suggestion.targetSets,
                targetReps: suggestion.targetReps
            )
            te.exercise = suggestion.exercise
            te.targetWeight = suggestion.suggestedWeight
            te.template = self
            context.insert(te)
        }

        name = workout.name
        sourceTemplateID = nil
        autoLoadedForWeekday = nil
    }

    /// Copies another template's exercises into this template's own rows — a deep copy, never a
    /// live reference; the source template is left untouched. Sets `sourceTemplateID` so later
    /// steps (usage tracking, save-back-to-original) can resolve where this content came from.
    func loadExercises(from source: WorkoutTemplate, context: ModelContext) {
        copyExercises(from: source, context: context)
        name = source.name
        sourceTemplateID = source.id
        autoLoadedForWeekday = nil
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

    /// Deep-copies this exercise and its `TemplateSet` children into new, inserted rows.
    /// `.template` is left unset — callers attach the copy to whichever template (or none, for a
    /// session's own working copy) is appropriate.
    func duplicated(in context: ModelContext) -> TemplateExercise {
        let copy = TemplateExercise(
            order: order,
            targetSets: targetSets,
            targetReps: targetReps,
            restSeconds: restSeconds
        )
        copy.targetWeight = targetWeight
        copy.targetWeightUnit = targetWeightUnit
        copy.exercise = exercise
        context.insert(copy)

        for set in setTargets {
            let setCopy = TemplateSet(order: set.order, targetWeight: set.targetWeight, targetReps: set.targetReps)
            setCopy.targetWeightUnit = set.targetWeightUnit
            setCopy.templateExercise = copy
            context.insert(setCopy)
        }

        return copy
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
