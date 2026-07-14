// SPDX-License-Identifier: AGPL-3.0-or-later
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

// MARK: - Workout Start Mode

/// How the unified staging view populates itself when the Workout tab appears.
enum WorkoutStartMode: String, Codable, CaseIterable, Identifiable {
    case smart       // AI-generated
    case dayTemplate // fixed weekly schedule
    case freeform    // manual pick, no automation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smart: return "Smart Workout"
        case .dayTemplate: return "Day Template"
        case .freeform: return "Freeform"
        }
    }

    var description: String {
        switch self {
        case .smart: return "Auto-generate a workout based on recovery status"
        case .dayTemplate: return "Load a fixed template based on the day of the week"
        case .freeform: return "Start blank and pick exercises manually"
        }
    }
}

// MARK: - Weekday

/// Raw value matches `Calendar.Component.weekday` (1 = Sunday ... 7 = Saturday).
enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    /// Today's weekday, using the current calendar.
    static var today: Weekday {
        Weekday(rawValue: Calendar.current.component(.weekday, from: Date())) ?? .sunday
    }

    /// Monday-first ordering for UI display (the schedule editor, settings summary), independent
    /// of `Calendar.Component.weekday`'s Sunday-first raw values.
    static let displayOrder: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
}
