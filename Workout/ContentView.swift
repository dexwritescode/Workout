// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ContentView.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ActiveWorkoutCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        TabView {
            Tab("Workout", systemImage: "figure.strengthtraining.traditional") {
                NavigationStack {
                    WorkoutStagingView()
                }
            }

            Tab("Recovery", systemImage: "heart.circle") {
                NavigationStack {
                    RecoveryDashboardView()
                }
            }

            Tab("History", systemImage: "calendar") {
                NavigationStack {
                    WorkoutHistoryView()
                }
            }

            Tab("Exercises", systemImage: "dumbbell") {
                NavigationStack {
                    ExerciseLibraryView()
                }
            }

            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(AppStyle.Colors.brand)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: coordinator.isActive && !coordinator.isPresented) {
            ActiveWorkoutMiniBar()
        }
        .fullScreenCover(isPresented: $coordinator.isPresented) {
            NavigationStack {
                ActiveWorkoutView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(ActiveWorkoutCoordinator())
        .modelContainer(for: [
            WorkoutTemplate.self,
            MuscleRecoveryState.self,
            WorkoutSession.self,
            Exercise.self
        ], inMemory: true)
}
