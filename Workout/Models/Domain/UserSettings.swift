//
//  UserSettings.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation
import SwiftData

/// Stores user preferences for the app (weight unit, rest time, etc.)
/// Only one instance should exist — created on first launch
@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var weightUnit: String              // WeightUnit raw value
    var defaultRestTime: Int            // seconds
    var notificationsEnabled: Bool
    var notificationTime: Date?
    var preferredEquipment: [String]
    var preferredSplitType: String?     // SplitType raw value
    var createdDate: Date
    
    init(id: UUID = UUID()) {
        self.id = id
        self.weightUnit = WeightUnit.kg.rawValue
        self.defaultRestTime = 90
        self.notificationsEnabled = false
        self.preferredEquipment = []
        self.createdDate = Date()
    }
    
    // MARK: - Type-safe computed properties
    
    var unit: WeightUnit {
        get { WeightUnit(rawValue: weightUnit) ?? .kg }
        set { weightUnit = newValue.rawValue }
    }
    
    var splitType: SplitType? {
        get {
            guard let raw = preferredSplitType else { return nil }
            return SplitType(rawValue: raw)
        }
        set { preferredSplitType = newValue?.rawValue }
    }
}
