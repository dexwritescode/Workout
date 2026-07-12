// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ActiveWorkoutCoordinator.swift
//  Workout
//
//  App-level coordinator for an active workout session. Lives above TabView so
//  the workout state persists across tab switches and can be surfaced both
//  full-screen and as a tab bar bottom accessory.
//

import Foundation
import SwiftData

@Observable
final class ActiveWorkoutCoordinator {
    /// Non-nil while a workout is in progress (running or finished, pre-save).
    var viewModel: ActiveWorkoutViewModel?

    /// True when the full-screen workout view should be presented. False when
    /// the workout is minimized to the tab bar accessory.
    var isPresented: Bool = false

    var isActive: Bool { viewModel != nil }

    func start(template: WorkoutTemplate, modelContext: ModelContext) {
        let vm = ActiveWorkoutViewModel(template: template, modelContext: modelContext)
        vm.startWorkout()
        viewModel = vm
        isPresented = true
    }

    func minimize() {
        isPresented = false
    }

    func expand() {
        guard viewModel != nil else { return }
        isPresented = true
    }

    func clear() {
        viewModel = nil
        isPresented = false
    }
}
