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

    // Plate calculator
    var availablePlatesKg: [Double]
    var availablePlatesLbs: [Double]
    var barbellWeightKg: Double
    var barbellWeightLbs: Double

    static let standardPlatesKg:  [Double] = [25, 20, 15, 10, 5, 2.5, 1.25, 0.5, 0.25]
    static let standardPlatesLbs: [Double] = [45, 35, 25, 10, 5, 2.5, 1.25]

    init(id: UUID = UUID()) {
        self.id = id
        self.weightUnit = WeightUnit.kg.rawValue
        self.defaultRestTime = 90
        self.notificationsEnabled = false
        self.preferredEquipment = []
        self.createdDate = Date()
        self.availablePlatesKg  = [25, 20, 15, 10, 5, 2.5, 1.25]
        self.availablePlatesLbs = [45, 35, 25, 10, 5, 2.5, 1.25]
        self.barbellWeightKg  = 20
        self.barbellWeightLbs = 45
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
