//
//  WorkoutApp.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import SwiftUI
import SwiftData

@main
struct WorkoutApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            TemplateSet.self,
            TemplateExercise.self,
            WorkoutTemplate.self,
            WorkoutSession.self,
            CompletedExercise.self,
            ExerciseSet.self,
            UserSettings.self,
            MuscleRecoveryState.self,
        ])

        let inMemory = CommandLine.arguments.contains("--ui-testing")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Persistent store unavailable (e.g. simulator sandbox in CI) — fall back to in-memory.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }()

    @State private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    SeedDataService.seedIfNeeded(modelContext: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
