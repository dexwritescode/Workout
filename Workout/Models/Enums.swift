//
//  Enums.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation

// MARK: - Muscle Groups

/// Represents the 14 major muscle groups tracked in the app
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    // Upper Body
    case chest = "Chest"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case lats = "Lats"
    case traps = "Traps"
    case lowerBack = "Lower Back"
    case neck = "Neck"
    case abs = "Abs"
    
    // Lower Body
    case glutes = "Glutes"
    case hamstrings = "Hamstrings"
    case quadriceps = "Quadriceps"
    case calves = "Calves"
    
    var id: String { rawValue }
    
    var category: MuscleCategory {
        switch self {
        case .chest, .shoulders, .biceps, .triceps, .forearms, .lats, .traps, .lowerBack, .neck, .abs:
            return .upperBody
        case .glutes, .hamstrings, .quadriceps, .calves:
            return .lowerBody
        }
    }
    
    /// Default recovery time in hours for this muscle group
    var defaultRecoveryHours: Int {
        switch self {
        case .neck, .forearms, .calves, .abs:
            return 24 // Smaller muscles recover faster
        case .biceps, .triceps, .shoulders, .traps:
            return 48 // Medium muscles
        case .chest, .lats, .lowerBack, .quadriceps, .hamstrings, .glutes:
            return 72 // Large muscles need more recovery
        }
    }
}

// MARK: - Muscle Category

enum MuscleCategory: String, Codable, CaseIterable {
    case upperBody = "Upper Body"
    case lowerBody = "Lower Body"
    
    var muscles: [MuscleGroup] {
        MuscleGroup.allCases.filter { $0.category == self }
    }
}

// MARK: - Exercise Difficulty

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .beginner:
            return "Suitable for beginners and those learning proper form"
        case .intermediate:
            return "Requires some experience and good form"
        case .advanced:
            return "For experienced lifters with excellent form"
        }
    }
}

// MARK: - Weight Unit

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg = "Kilograms"
    case lbs = "Pounds"
    
    var id: String { rawValue }
    
    var abbreviation: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }
    
    /// Convert weight from this unit to the other unit
    func convert(_ weight: Double, to targetUnit: WeightUnit) -> Double {
        if self == targetUnit {
            return weight
        }
        
        switch (self, targetUnit) {
        case (.kg, .lbs):
            return weight * 2.20462
        case (.lbs, .kg):
            return weight / 2.20462
        default:
            return weight
        }
    }
}

// MARK: - Workout Split Type

enum SplitType: String, Codable, CaseIterable, Identifiable {
    case fullBody = "Full Body"
    case upperLower = "Upper/Lower"
    case pushPullLegs = "Push/Pull/Legs"
    case bodypartSplit = "Body Part Split"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .fullBody:
            return "Train all major muscle groups in each workout"
        case .upperLower:
            return "Alternate between upper body and lower body workouts"
        case .pushPullLegs:
            return "Split workouts into push muscles, pull muscles, and legs"
        case .bodypartSplit:
            return "Dedicate each workout to specific muscle groups"
        }
    }
    
    var frequency: String {
        switch self {
        case .fullBody:
            return "3 days per week"
        case .upperLower:
            return "4 days per week"
        case .pushPullLegs:
            return "6 days per week"
        case .bodypartSplit:
            return "5-6 days per week"
        }
    }
}
