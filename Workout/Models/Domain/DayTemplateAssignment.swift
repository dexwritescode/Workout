// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  DayTemplateAssignment.swift
//  Workout
//

import Foundation
import SwiftData

/// One row per weekday (7 total, seeded at first launch), mapping a day of the week to the
/// template that should auto-load when `UserSettings.workoutStartMode == .dayTemplate`.
@Model
final class DayTemplateAssignment {
    @Attribute(.unique) var weekday: Int  // Weekday raw value

    @Relationship(deleteRule: .nullify)
    var template: WorkoutTemplate?

    init(weekday: Weekday, template: WorkoutTemplate? = nil) {
        self.weekday = weekday.rawValue
        self.template = template
    }
}
