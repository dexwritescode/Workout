//
//  ThemeManager.swift
//  Workout
//
//  Observable singleton that drives the app-wide accent color.
//  Persisted via UserDefaults so it survives app restarts.
//

import SwiftUI

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var accentTheme: AppStyle.AccentTheme {
        didSet {
            UserDefaults.standard.set(accentTheme.rawValue, forKey: "accentTheme")
        }
    }

    var brandColor: Color { accentTheme.color }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "accentTheme") ?? "forge"
        self.accentTheme = AppStyle.AccentTheme(rawValue: saved) ?? .forge
    }
}
