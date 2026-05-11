//
//  MuscleRecoveryState.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation
import SwiftData

/// Tracks the recovery state of a single muscle group
/// One instance per muscle group — updated after each workout
@Model
final class MuscleRecoveryState {
    @Attribute(.unique) var muscleGroup: String  // MuscleGroup raw value
    var fatigueLevel: Double                     // 0.0 (fresh) to 1.0 (max fatigue)
    var lastWorkedDate: Date
    var estimatedFullRecoveryDate: Date
    var lastUpdated: Date
    var workloadHistory: Data?                   // Encoded array of recent workloads
    
    init(muscleGroup: MuscleGroup, fatigueLevel: Double = 0.0) {
        self.muscleGroup = muscleGroup.rawValue
        self.fatigueLevel = fatigueLevel
        self.lastWorkedDate = Date()
        self.estimatedFullRecoveryDate = Date()
        self.lastUpdated = Date()
    }
    
    /// Type-safe access to the muscle group enum
    var muscle: MuscleGroup? {
        MuscleGroup(rawValue: muscleGroup)
    }
    
    /// Stored recovery percentage (snapshot — does not account for elapsed time)
    var recoveryPercentage: Double {
        1.0 - fatigueLevel
    }
    
    /// Dynamic recovery percentage accounting for time elapsed since last update.
    var currentRecoveryPercentage: Double {
        RecoveryEngine.currentRecoveryPercentage(for: self)
    }
    
    /// Dynamic current fatigue accounting for time elapsed.
    var currentFatigue: Double {
        guard let muscle else { return fatigueLevel }
        return RecoveryEngine.currentFatigue(
            storedFatigue: fatigueLevel,
            lastUpdated: lastUpdated,
            muscleGroup: muscle
        )
    }
}
