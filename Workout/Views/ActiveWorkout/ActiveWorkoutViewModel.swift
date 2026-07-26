// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ActiveWorkoutViewModel.swift
//  Workout
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Foundation
import SwiftData

/// Manages the lifecycle of an active workout session
@Observable
final class ActiveWorkoutViewModel {
    
    // MARK: - State
    
    enum WorkoutState: Equatable {
        case notStarted
        case inProgress
        case finished
    }
    
    private(set) var state: WorkoutState = .notStarted
    private(set) var session: WorkoutSession?
    private(set) var currentExerciseIndex: Int = 0
    private(set) var sessionExercises: [TemplateExercise] = []
    private(set) var adhocExercises: [TemplateExercise] = []

    let template: WorkoutTemplate?
    let sessionName: String
    private let modelContext: ModelContext

    /// Sorted exercises for the active session — always the session's own copy (see
    /// `startWorkout()`), never a live read of the template/draft's current exercises.
    var sortedExercises: [TemplateExercise] {
        sessionExercises
    }

    /// All exercises for the active session — session-local copy of template exercises
    /// plus any exercises added mid-workout. Does not mutate the template.
    var allTemplateExercises: [TemplateExercise] {
        sessionExercises + adhocExercises
    }

    // MARK: - Init

    init(template: WorkoutTemplate, modelContext: ModelContext) {
        self.template = template
        self.sessionName = template.name
        self.modelContext = modelContext
    }

    // MARK: - Session Lifecycle
    
    /// Starts a new workout session, creating CompletedExercise entries for each template exercise
    func startWorkout() {
        let isDraftSession = template?.draftKind == .workoutStaging
        let newSession = WorkoutSession(template: isDraftSession ? nil : template)
        if isDraftSession || template == nil { newSession.sessionTitle = sessionName }
        modelContext.insert(newSession)

        // Deep-copy the template/draft's exercises into new, unattached rows (te.template = nil,
        // same convention addExercise() uses below) rather than holding live references. This
        // decouples the running session from the draft entirely — editing/regenerating/loading
        // the draft while this workout is active can't corrupt what's being tracked here.
        if let template {
            sessionExercises = template.exercises
                .sorted { $0.order < $1.order }
                .map { $0.duplicated(in: modelContext) }
        }

        for templateExercise in sessionExercises {
            let completed = CompletedExercise(order: templateExercise.order)
            completed.exercise = templateExercise.exercise
            completed.session = newSession
            modelContext.insert(completed)
            newSession.completedExercises.append(completed)
        }

        if let sourceID = template?.sourceTemplateID,
           let source = WorkoutTemplate.template(withID: sourceID, in: modelContext) {
            source.lastUsedDate = Date()
            source.timesStarted += 1
        }

        session = newSession
        currentExerciseIndex = 0
        state = .inProgress
    }
    
    /// Finishes the current workout session
    func finishWorkout() {
        guard let session, state == .inProgress else { return }
        session.endTime = Date()
        session.isCompleted = true
        state = .finished
    }
    
    /// Adds an exercise to the current session without modifying the template
    func addExercise(_ exercise: Exercise) {
        guard let session else { return }
        let order = allTemplateExercises.count
        let te = TemplateExercise(order: order, targetSets: 3, targetReps: 10, restSeconds: 0)
        te.exercise = exercise
        modelContext.insert(te)
        adhocExercises.append(te)

        let ce = CompletedExercise(order: order)
        ce.exercise = exercise
        ce.session = session
        modelContext.insert(ce)
        session.completedExercises.append(ce)
    }

    /// Removes an exercise from the current session by its position in allTemplateExercises.
    /// Template exercises are removed from the session list only — the template is not modified.
    func removeExercise(at index: Int) {
        guard let session else { return }
        let sorted = sortedCompletedExercises
        guard index < sorted.count else { return }

        let ce = sorted[index]
        session.completedExercises.removeAll { $0 === ce }
        modelContext.delete(ce)

        if index < sessionExercises.count {
            sessionExercises.remove(at: index)
        } else {
            let adhocIndex = index - sessionExercises.count
            if adhocIndex < adhocExercises.count {
                modelContext.delete(adhocExercises.remove(at: adhocIndex))
            }
        }

        for (i, c) in sortedCompletedExercises.enumerated() { c.order = i }

        let remaining = allTemplateExercises.count
        if currentExerciseIndex >= remaining { currentExerciseIndex = max(0, remaining - 1) }
    }

    /// Cancels and deletes the current workout session
    func cancelWorkout() {
        // sessionExercises/adhocExercises are the session's own independent copies (see
        // startWorkout()) — safe to delete regardless of outcome. The draft's own exercises are
        // left untouched: nothing was completed, so the staged plan should still be there to retry.
        for te in sessionExercises { modelContext.delete(te) }
        for te in adhocExercises { modelContext.delete(te) }
        adhocExercises = []
        sessionExercises = []
        guard let session else { return }
        modelContext.delete(session)
        self.session = nil
        state = .notStarted
    }
    
    // MARK: - Navigation
    
    /// Moves to the next exercise in the list
    func moveToNextExercise() {
        let maxIndex = sortedExercises.count - 1
        if currentExerciseIndex < maxIndex {
            currentExerciseIndex += 1
        }
    }
    
    /// Moves to the previous exercise in the list
    func moveToPreviousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
        }
    }
    
    /// Selects a specific exercise by index
    func selectExercise(at index: Int) {
        guard index >= 0 && index < sortedExercises.count else { return }
        currentExerciseIndex = index
    }
    
    // MARK: - Set Completion
    
    /// Marks an exercise as complete and auto-advances to the next incomplete exercise
    func markExerciseComplete(at index: Int) {
        let all = allTemplateExercises
        let maxIndex = all.count - 1
        guard index + 1 <= maxIndex else { return }
        for i in (index + 1)...maxIndex {
            let te = all[i]
            let ce = sortedCompletedExercises.count > i ? sortedCompletedExercises[i] : nil
            let done = ce?.sets.filter(\.isCompleted).count ?? 0
            if done < te.targetSets {
                currentExerciseIndex = i
                return
            }
        }
        // If all after are done, stay put
    }
    
    // MARK: - Summary Stats
    
    struct WorkoutSummary {
        let duration: TimeInterval
        let exercisesCompleted: Int
        let totalExercises: Int
        let totalSets: Int
        let totalVolume: Double // weight × reps summed
        let exerciseBreakdowns: [ExerciseBreakdown]
        let musclesWorked: [MuscleGroup: Double] // muscle → fatigue delta
    }
    
    struct ExerciseBreakdown {
        let name: String
        let sets: [SetDetail]
    }
    
    struct SetDetail {
        let setNumber: Int
        let weight: Double
        let reps: Int
    }
    
    /// Computes summary stats for the finished workout
    var summary: WorkoutSummary? {
        guard let session, state == .finished else { return nil }
        
        let duration = session.duration ?? 0
        let completedExercises = sortedCompletedExercises
        
        let exercisesWithSets = completedExercises.filter { !$0.sets.filter(\.isCompleted).isEmpty }
        let allCompletedSets = completedExercises.flatMap { $0.sets.filter(\.isCompleted) }
        let totalVolume = allCompletedSets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
        
        let breakdowns: [ExerciseBreakdown] = completedExercises.compactMap { ce in
            let doneSets = ce.sets.filter(\.isCompleted).sorted { $0.setNumber < $1.setNumber }
            guard !doneSets.isEmpty else { return nil }
            return ExerciseBreakdown(
                name: ce.exercise?.name ?? "Unknown",
                sets: doneSets.map { SetDetail(setNumber: $0.setNumber, weight: $0.weight, reps: $0.reps) }
            )
        }
        
        let musclesWorked = RecoveryEngine.calculateFatigueDeltas(for: session)
        
        return WorkoutSummary(
            duration: duration,
            exercisesCompleted: exercisesWithSets.count,
            totalExercises: completedExercises.count,
            totalSets: allCompletedSets.count,
            totalVolume: totalVolume,
            exerciseBreakdowns: breakdowns,
            musclesWorked: musclesWorked
        )
    }
    
    /// Saves the workout and updates muscle recovery states
    func saveWorkout() {
        guard let session else { return }
        session.isCompleted = true
        RecoveryEngine.updateRecoveryStates(for: session, modelContext: modelContext)

        // sessionExercises/adhocExercises are independent copies with no further purpose now
        // that CompletedExercise/ExerciseSet hold the real, saved record.
        for te in sessionExercises { modelContext.delete(te) }
        for te in adhocExercises { modelContext.delete(te) }
        sessionExercises = []
        adhocExercises = []

        // The draft's own exercises are cleared only on an actual completion, so the next time
        // the staging view appears it starts from a clean slate rather than an already-used plan.
        if let template, template.draftKind == .workoutStaging {
            template.clearExercises(context: modelContext)
            template.sourceTemplateID = nil
            template.autoLoadedForWeekday = nil
        }
    }

    /// Discards the workout by deleting the session
    func discardWorkout() {
        // Same reasoning as cancelWorkout(): these are independent copies, safe to delete
        // regardless of outcome, but the draft's own exercises are left untouched since nothing
        // was actually completed.
        for te in sessionExercises { modelContext.delete(te) }
        for te in adhocExercises { modelContext.delete(te) }
        adhocExercises = []
        sessionExercises = []
        guard let session else { return }
        modelContext.delete(session)
        self.session = nil
    }
    
    /// Updates session notes
    func updateNotes(_ notes: String) {
        session?.notes = notes.isEmpty ? nil : notes
    }
    
    // MARK: - Helpers
    
    /// Returns the sorted completed exercises matching the template order
    var sortedCompletedExercises: [CompletedExercise] {
        session?.completedExercises.sorted { $0.order < $1.order } ?? []
    }
    
    /// Elapsed time since workout started (for use with TimelineView)
    var elapsedTime: TimeInterval {
        guard let session, state == .inProgress else { return 0 }
        return Date().timeIntervalSince(session.startTime)
    }
    
    /// Formats a time interval as MM:SS or H:MM:SS
    static func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
