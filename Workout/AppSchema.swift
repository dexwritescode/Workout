// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  AppSchema.swift
//  Workout
//

import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 4, 0)
    static var models: [any PersistentModel.Type] {
        [
            Exercise.self,
            TemplateSet.self,
            TemplateExercise.self,
            WorkoutTemplate.self,
            WorkoutSession.self,
            CompletedExercise.self,
            ExerciseSet.self,
            UserSettings.self,
            MuscleRecoveryState.self,
            DayTemplateAssignment.self,
        ]
    }
}

enum WorkoutMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
