//
//  ImportService.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation
import SwiftData

/// Imports workout data from a JSON backup file.
struct ImportService {
    
    enum ImportError: LocalizedError {
        case invalidData
        case unsupportedVersion(Int)
        case decodingFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidData:
                return "The file does not contain valid workout data."
            case .unsupportedVersion(let v):
                return "Export version \(v) is not supported."
            case .decodingFailed(let msg):
                return "Failed to read data: \(msg)"
            }
        }
    }
    
    /// Result of an import operation
    struct ImportResult {
        let sessionsImported: Int
        let settingsImported: Bool
    }
    
    // MARK: - Import
    
    /// Imports workout data from JSON. Does NOT overwrite existing sessions (skips duplicates by ID).
    static func importData(from data: Data, modelContext: ModelContext) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData: ExportService.ExportData
        do {
            exportData = try decoder.decode(ExportService.ExportData.self, from: data)
        } catch {
            throw ImportError.decodingFailed(error.localizedDescription)
        }
        
        guard exportData.version == 1 else {
            throw ImportError.unsupportedVersion(exportData.version)
        }
        
        // Fetch existing session IDs to avoid duplicates
        let existingDescriptor = FetchDescriptor<WorkoutSession>()
        let existingIDs = Set((try? modelContext.fetch(existingDescriptor))?.map { $0.id.uuidString } ?? [])
        
        // Fetch exercise name lookup
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let exercises = (try? modelContext.fetch(exerciseDescriptor)) ?? []
        let exerciseLookup = Dictionary(uniqueKeysWithValues: exercises.map { ($0.name, $0) })
        
        var importedCount = 0
        
        for sessionExport in exportData.sessions {
            // Skip if already exists
            if existingIDs.contains(sessionExport.id) { continue }
            
            let session = WorkoutSession(
                id: UUID(uuidString: sessionExport.id) ?? UUID(),
                startTime: sessionExport.startTime
            )
            session.endTime = sessionExport.endTime
            session.notes = sessionExport.notes
            session.isCompleted = true
            modelContext.insert(session)
            
            for exerciseExport in sessionExport.exercises {
                let ce = CompletedExercise(order: exerciseExport.order)
                ce.exercise = exerciseLookup[exerciseExport.name]
                ce.session = session
                modelContext.insert(ce)
                
                for setExport in exerciseExport.sets {
                    let set = ExerciseSet(
                        setNumber: setExport.setNumber,
                        weight: setExport.weight,
                        reps: setExport.reps,
                        isCompleted: true,
                        rpe: setExport.rpe
                    )
                    set.completedAt = setExport.completedAt
                    set.completedExercise = ce
                    modelContext.insert(set)
                }
            }
            
            importedCount += 1
        }
        
        // Import settings if present
        var settingsImported = false
        if let settingsExport = exportData.settings {
            let settingsDescriptor = FetchDescriptor<UserSettings>()
            if let existing = try? modelContext.fetch(settingsDescriptor).first {
                existing.weightUnit = settingsExport.weightUnit
                existing.defaultRestTime = settingsExport.defaultRestTime
                existing.preferredSplitType = settingsExport.preferredSplitType
                settingsImported = true
            }
        }
        
        return ImportResult(sessionsImported: importedCount, settingsImported: settingsImported)
    }
}
