//
//  RecoveryEngine.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation
import SwiftData

/// Deterministic muscle recovery engine.
/// Calculates fatigue from workout volume and models recovery via exponential decay.
struct RecoveryEngine {
    
    // MARK: - Constants
    
    /// Reference volume (kg × reps) representing a heavy single-muscle session.
    /// e.g. 4 sets × 10 reps × 100 kg = 4000 for a big compound lift.
    private static let referenceVolume: Double = 5000.0
    
    /// Scaling factor for tanh normalization. Caps effective fatigue below 1.0.
    private static let fatigueScale: Double = 0.85
    
    /// Secondary muscles receive this fraction of the primary volume contribution.
    private static let secondaryFactor: Double = 0.5
    
    // MARK: - Volume & Fatigue Calculation
    
    /// Calculates per-muscle fatigue deltas from a completed workout session.
    /// Returns a dictionary mapping each worked MuscleGroup to its fatigue delta (0.0–1.0).
    static func calculateFatigueDeltas(for session: WorkoutSession) -> [MuscleGroup: Double] {
        var muscleVolume: [MuscleGroup: Double] = [:]
        
        for completedExercise in session.completedExercises {
            guard let exercise = completedExercise.exercise else { continue }
            
            let completedSets = completedExercise.sets.filter(\.isCompleted)
            guard !completedSets.isEmpty else { continue }
            
            // Volume = sum of (weight × reps) across all completed sets
            let volume = completedSets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            
            // Primary muscles get full volume
            for muscle in exercise.primaryMuscleGroups {
                muscleVolume[muscle, default: 0] += volume
            }
            
            // Secondary muscles get reduced volume
            for muscle in exercise.secondaryMuscleGroups {
                muscleVolume[muscle, default: 0] += volume * secondaryFactor
            }
        }
        
        // Normalize volume to fatigue delta using saturating curve
        return muscleVolume.mapValues { normalizeFatigue(volume: $0) }
    }
    
    /// Converts raw volume (kg × reps) into a 0.0–1.0 fatigue delta.
    /// Uses tanh for smooth saturation so extreme volume has diminishing returns.
    static func normalizeFatigue(volume: Double) -> Double {
        guard volume > 0 else { return 0 }
        let normalized = volume / referenceVolume
        return min(1.0, tanh(normalized) * fatigueScale)
    }
    
    // MARK: - Recovery Over Time (Exponential Decay)
    
    /// Computes the current fatigue level for a muscle given its stored state and elapsed time.
    /// Uses exponential decay: fatigue halves every (defaultRecoveryHours / 2.5) hours.
    static func currentFatigue(
        storedFatigue: Double,
        lastUpdated: Date,
        muscleGroup: MuscleGroup,
        now: Date = Date()
    ) -> Double {
        let hoursElapsed = now.timeIntervalSince(lastUpdated) / 3600.0
        guard hoursElapsed > 0, storedFatigue > 0 else { return storedFatigue }
        
        let halfLife = Double(muscleGroup.defaultRecoveryHours) / 2.5
        let decayFactor = pow(0.5, hoursElapsed / halfLife)
        let fatigue = storedFatigue * decayFactor
        
        // Below threshold, treat as fully recovered
        return fatigue < 0.01 ? 0.0 : fatigue
    }
    
    /// Returns recovery percentage (0.0–1.0) for a MuscleRecoveryState, accounting for elapsed time.
    static func currentRecoveryPercentage(for state: MuscleRecoveryState, now: Date = Date()) -> Double {
        guard let muscle = state.muscle else { return 1.0 }
        let fatigue = currentFatigue(
            storedFatigue: state.fatigueLevel,
            lastUpdated: state.lastUpdated,
            muscleGroup: muscle,
            now: now
        )
        return 1.0 - fatigue
    }
    
    // MARK: - Update Recovery States After Workout
    
    /// Updates all MuscleRecoveryState records after a workout completes.
    /// Decays existing fatigue to current time, then adds new fatigue from the session.
    static func updateRecoveryStates(for session: WorkoutSession, modelContext: ModelContext) {
        let fatigueDeltas = calculateFatigueDeltas(for: session)
        guard !fatigueDeltas.isEmpty else { return }
        
        let now = Date()
        
        for (muscle, fatigueDelta) in fatigueDeltas {
            let state = fetchOrCreateState(for: muscle, modelContext: modelContext)
            
            // Decay existing fatigue to "now"
            let decayedFatigue = currentFatigue(
                storedFatigue: state.fatigueLevel,
                lastUpdated: state.lastUpdated,
                muscleGroup: muscle,
                now: now
            )
            
            // Add new fatigue, clamped to 1.0
            let newFatigue = min(1.0, decayedFatigue + fatigueDelta)
            
            state.fatigueLevel = newFatigue
            state.lastWorkedDate = now
            state.lastUpdated = now
            state.estimatedFullRecoveryDate = estimateFullRecoveryDate(
                fatigue: newFatigue,
                muscleGroup: muscle,
                from: now
            )
        }
    }
    
    // MARK: - Helpers
    
    /// Fetches an existing MuscleRecoveryState or creates a new one.
    private static func fetchOrCreateState(
        for muscle: MuscleGroup,
        modelContext: ModelContext
    ) -> MuscleRecoveryState {
        let rawValue = muscle.rawValue
        var descriptor = FetchDescriptor<MuscleRecoveryState>(
            predicate: #Predicate { $0.muscleGroup == rawValue }
        )
        descriptor.fetchLimit = 1
        
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        
        let newState = MuscleRecoveryState(muscleGroup: muscle)
        modelContext.insert(newState)
        return newState
    }
    
    /// Estimates when fatigue will drop below 5% (effectively recovered).
    static func estimateFullRecoveryDate(
        fatigue: Double,
        muscleGroup: MuscleGroup,
        from date: Date = Date()
    ) -> Date {
        guard fatigue > 0.05 else { return date }
        let halfLife = Double(muscleGroup.defaultRecoveryHours) / 2.5
        // Solve: fatigue × 0.5^(t/halfLife) = 0.05
        // t = halfLife × log2(fatigue / 0.05)
        let hoursToRecover = halfLife * (log(fatigue / 0.05) / log(2.0))
        return date.addingTimeInterval(hoursToRecover * 3600)
    }
}
