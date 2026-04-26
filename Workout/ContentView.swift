//
//  ContentView.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppStyle.Colors.surface1)
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppStyle.Colors.textTertiary)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(AppStyle.Colors.textTertiary)]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppStyle.Colors.brand)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppStyle.Colors.brand)]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(AppStyle.Colors.background)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppStyle.Colors.text)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppStyle.Colors.text)]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }

    var body: some View {
        TabView {
            NavigationStack {
                TemplatePickerView()
            }
            .tabItem {
                Label("Workout", systemImage: "figure.strengthtraining.traditional")
            }

            NavigationStack {
                RecoveryDashboardView()
            }
            .tabItem {
                Label("Recovery", systemImage: "heart.circle")
            }

            NavigationStack {
                WorkoutHistoryView()
            }
            .tabItem {
                Label("History", systemImage: "calendar")
            }

            NavigationStack {
                ExerciseLibraryView()
            }
            .tabItem {
                Label("Exercises", systemImage: "dumbbell")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .tint(AppStyle.Colors.brand)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            WorkoutTemplate.self,
            MuscleRecoveryState.self,
            WorkoutSession.self,
            Exercise.self
        ], inMemory: true)
}
