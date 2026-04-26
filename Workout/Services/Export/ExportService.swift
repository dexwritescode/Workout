//
//  ExportService.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation
import SwiftData

/// Exports workout data to JSON for backup.
struct ExportService {
    
    // MARK: - Codable Types
    
    struct ExportData: Codable {
        let exportDate: Date
        let version: Int
        let sessions: [SessionExport]
        let settings: SettingsExport?
    }
    
    struct SessionExport: Codable {
        let id: String
        let templateName: String?
        let startTime: Date
        let endTime: Date?
        let notes: String?
        let exercises: [ExerciseExport]
    }
    
    struct ExerciseExport: Codable {
        let name: String
        let order: Int
        let sets: [SetExport]
    }
    
    struct SetExport: Codable {
        let setNumber: Int
        let weight: Double
        let reps: Int
        let rpe: Int?
        let completedAt: Date?
    }
    
    struct SettingsExport: Codable {
        let weightUnit: String
        let defaultRestTime: Int
        let preferredSplitType: String?
    }
    
    // MARK: - Export
    
    /// Exports all completed workout sessions and settings to JSON Data.
    static func exportAll(modelContext: ModelContext) throws -> Data {
        // Fetch completed sessions
        var sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted },
            sortBy: [SortDescriptor(\WorkoutSession.startTime, order: .reverse)]
        )
        sessionDescriptor.fetchLimit = 1000
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
        
        let sessionExports = sessions.map { session in
            let exercises = session.completedExercises
                .sorted { $0.order < $1.order }
                .map { ce in
                    ExerciseExport(
                        name: ce.exercise?.name ?? "Unknown",
                        order: ce.order,
                        sets: ce.sets
                            .filter(\.isCompleted)
                            .sorted { $0.setNumber < $1.setNumber }
                            .map { set in
                                SetExport(
                                    setNumber: set.setNumber,
                                    weight: set.weight,
                                    reps: set.reps,
                                    rpe: set.rpe,
                                    completedAt: set.completedAt
                                )
                            }
                    )
                }
            
            return SessionExport(
                id: session.id.uuidString,
                templateName: session.template?.name,
                startTime: session.startTime,
                endTime: session.endTime,
                notes: session.notes,
                exercises: exercises
            )
        }
        
        // Fetch settings
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        let userSettings = try? modelContext.fetch(settingsDescriptor).first
        let settingsExport = userSettings.map { s in
            SettingsExport(
                weightUnit: s.weightUnit,
                defaultRestTime: s.defaultRestTime,
                preferredSplitType: s.preferredSplitType
            )
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            version: 1,
            sessions: sessionExports,
            settings: settingsExport
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportData)
    }
    
    /// Returns a temporary file URL for sharing the export.
    static func exportToFile(modelContext: ModelContext) throws -> URL {
        let data = try exportAll(modelContext: modelContext)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "workout-export-\(dateFormatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
        return url
    }
}
