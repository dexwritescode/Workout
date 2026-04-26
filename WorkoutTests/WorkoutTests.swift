//
//  WorkoutTests.swift
//  WorkoutTests
//
//  Created by Dexter Darwich on 2025-12-30.
//

import Testing
import Foundation
import SwiftData
@testable import Workout

@Suite("PR #1: Enum Tests")
@MainActor
struct EnumTests {

    @Test("MuscleGroup has 14 cases")
    func muscleGroupCount() async throws {
        #expect(MuscleGroup.allCases.count == 14)
    }
    
    @Test("MuscleGroup categories are correct")
    func muscleGroupCategories() async throws {
        // Upper body muscles
        #expect(MuscleGroup.chest.category == .upperBody)
        #expect(MuscleGroup.shoulders.category == .upperBody)
        #expect(MuscleGroup.biceps.category == .upperBody)
        #expect(MuscleGroup.triceps.category == .upperBody)
        #expect(MuscleGroup.forearms.category == .upperBody)
        #expect(MuscleGroup.lats.category == .upperBody)
        #expect(MuscleGroup.traps.category == .upperBody)
        #expect(MuscleGroup.lowerBack.category == .upperBody)
        #expect(MuscleGroup.neck.category == .upperBody)
        #expect(MuscleGroup.abs.category == .upperBody)
        
        // Lower body muscles
        #expect(MuscleGroup.glutes.category == .lowerBody)
        #expect(MuscleGroup.hamstrings.category == .lowerBody)
        #expect(MuscleGroup.quadriceps.category == .lowerBody)
        #expect(MuscleGroup.calves.category == .lowerBody)
    }
    
    @Test("MuscleGroup recovery times are reasonable")
    func muscleGroupRecoveryTimes() async throws {
        // Small muscles (24 hours)
        #expect(MuscleGroup.neck.defaultRecoveryHours == 24)
        #expect(MuscleGroup.forearms.defaultRecoveryHours == 24)
        #expect(MuscleGroup.calves.defaultRecoveryHours == 24)
        #expect(MuscleGroup.abs.defaultRecoveryHours == 24)
        
        // Medium muscles (48 hours)
        #expect(MuscleGroup.biceps.defaultRecoveryHours == 48)
        #expect(MuscleGroup.triceps.defaultRecoveryHours == 48)
        #expect(MuscleGroup.shoulders.defaultRecoveryHours == 48)
        #expect(MuscleGroup.traps.defaultRecoveryHours == 48)
        
        // Large muscles (72 hours)
        #expect(MuscleGroup.chest.defaultRecoveryHours == 72)
        #expect(MuscleGroup.lats.defaultRecoveryHours == 72)
        #expect(MuscleGroup.lowerBack.defaultRecoveryHours == 72)
        #expect(MuscleGroup.quadriceps.defaultRecoveryHours == 72)
        #expect(MuscleGroup.hamstrings.defaultRecoveryHours == 72)
        #expect(MuscleGroup.glutes.defaultRecoveryHours == 72)
    }
    
    @Test("WeightUnit conversions are accurate")
    func weightUnitConversions() async throws {
        let kg = WeightUnit.kg
        let lbs = WeightUnit.lbs
        
        // 100 kg to lbs
        let kgToLbs = kg.convert(100, to: .lbs)
        #expect(abs(kgToLbs - 220.462) < 0.01)
        
        // 220 lbs to kg
        let lbsToKg = lbs.convert(220, to: .kg)
        #expect(abs(lbsToKg - 99.79) < 0.01)
        
        // Same unit conversion should return same value
        #expect(kg.convert(100, to: .kg) == 100)
        #expect(lbs.convert(220, to: .lbs) == 220)
    }
    
    @Test("DifficultyLevel has correct count")
    func difficultyLevelCount() async throws {
        #expect(DifficultyLevel.allCases.count == 3)
    }
    
    @Test("SplitType has correct count")
    func splitTypeCount() async throws {
        #expect(SplitType.allCases.count == 4)
    }
    
    @Test("All enums are Identifiable")
    func enumsAreIdentifiable() async throws {
        // Should not crash - tests that id property exists
        let _ = MuscleGroup.biceps.id
        let _ = DifficultyLevel.beginner.id
        let _ = WeightUnit.kg.id
        let _ = SplitType.fullBody.id
        
        // IDs should be stable
        #expect(MuscleGroup.biceps.id == MuscleGroup.biceps.id)
    }
    
    @Test("MuscleCategory provides correct muscles")
    func muscleCategoryMuscles() async throws {
        let upperMuscles = MuscleCategory.upperBody.muscles
        let lowerMuscles = MuscleCategory.lowerBody.muscles
        
        #expect(upperMuscles.count == 10)
        #expect(lowerMuscles.count == 4)
        
        #expect(upperMuscles.contains(.chest))
        #expect(upperMuscles.contains(.biceps))
        #expect(upperMuscles.contains(.lats))
        #expect(lowerMuscles.contains(.quadriceps))
        #expect(lowerMuscles.contains(.calves))
    }
}

@Suite("PR #2: Exercise Model Tests")
@MainActor
struct ExerciseModelTests {
    
    @Test("Exercise initialization works correctly")
    func exerciseInitialization() async throws {
        let exercise = Exercise(
            name: "Barbell Bench Press",
            description: "A compound chest exercise",
            instructions: ["Lie on bench", "Lower bar to chest", "Press up"],
            equipment: ["Barbell", "Flat Bench"],
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders],
            difficultyLevel: .intermediate
        )
        
        #expect(exercise.name == "Barbell Bench Press")
        #expect(exercise.exerciseDescription == "A compound chest exercise")
        #expect(exercise.instructions.count == 3)
        #expect(exercise.equipment.count == 2)
        #expect(exercise.isCustom == false)
        #expect(exercise.difficulty == .intermediate)
    }
    
    @Test("Exercise muscle group conversion works")
    func exerciseMuscleGroupConversion() async throws {
        let exercise = Exercise(
            name: "Test Exercise",
            description: "Test",
            primaryMuscles: [.chest, .shoulders],
            secondaryMuscles: [.triceps]
        )
        
        #expect(exercise.primaryMuscleGroups.count == 2)
        #expect(exercise.secondaryMuscleGroups.count == 1)
        #expect(exercise.allMuscleGroups.count == 3)
        
        #expect(exercise.primaryMuscleGroups.contains(.chest))
        #expect(exercise.primaryMuscleGroups.contains(.shoulders))
        #expect(exercise.secondaryMuscleGroups.contains(.triceps))
    }
    
    @Test("Exercise computed properties work")
    func exerciseComputedProperties() async throws {
        let exercise = Exercise(
            name: "Squat",
            description: "Leg exercise",
            equipment: ["Barbell"],
            primaryMuscles: [.quadriceps, .glutes],
            secondaryMuscles: [.hamstrings]
        )
        
        #expect(exercise.isCompound == true)
        #expect(exercise.requiresEquipment == true)
        #expect(exercise.primaryMusclesDisplayString.contains("Quadriceps"))
        #expect(exercise.equipmentDisplayString == "Barbell")
    }
    
    @Test("Exercise bodyweight detection works")
    func exerciseBodyweightDetection() async throws {
        let bodyweightExercise = Exercise(
            name: "Push-up",
            description: "Bodyweight chest exercise",
            equipment: ["Bodyweight"],
            primaryMuscles: [.chest]
        )
        
        let weightedExercise = Exercise(
            name: "Bench Press",
            description: "Weighted chest exercise",
            equipment: ["Barbell"],
            primaryMuscles: [.chest]
        )
        
        #expect(bodyweightExercise.requiresEquipment == false)
        #expect(weightedExercise.requiresEquipment == true)
    }
    
    @Test("Exercise muscle checking works")
    func exerciseMuscleChecking() async throws {
        let exercise = Exercise(
            name: "Pull-up",
            description: "Back exercise",
            primaryMuscles: [.lats],
            secondaryMuscles: [.biceps, .traps]
        )
        
        #expect(exercise.works(muscle: .lats) == true)
        #expect(exercise.works(muscle: .biceps) == true)
        #expect(exercise.works(muscle: .chest) == false)
        
        #expect(exercise.works(category: .upperBody) == true)
        #expect(exercise.works(category: .lowerBody) == false)
    }
    
    @Test("Exercise equipment checking works")
    func exerciseEquipmentChecking() async throws {
        let exercise = Exercise(
            name: "Dumbbell Curl",
            description: "Bicep exercise",
            equipment: ["Dumbbell"],
            primaryMuscles: [.biceps]
        )
        
        #expect(exercise.uses(equipment: "Dumbbell") == true)
        #expect(exercise.uses(equipment: "Barbell") == false)
    }
    
    @Test("Exercise duplication works")
    func exerciseDuplication() async throws {
        let original = Exercise(
            name: "Original Exercise",
            description: "Test exercise",
            primaryMuscles: [.chest],
            isCustom: false
        )
        
        let duplicate = original.duplicate()
        
        #expect(duplicate.name == "Original Exercise (Copy)")
        #expect(duplicate.isCustom == true)
        #expect(duplicate.id != original.id)
        #expect(duplicate.exerciseDescription == original.exerciseDescription)
    }
    
    @Test("Exercise equality works by ID")
    func exerciseEquality() async throws {
        let exercise1 = Exercise(
            name: "Test",
            description: "Test",
            primaryMuscles: [.chest]
        )
        
        let exercise2 = Exercise(
            name: "Test",
            description: "Test",
            primaryMuscles: [.chest]
        )
        
        // Different IDs means not equal
        #expect(exercise1.id != exercise2.id)
        
        // Same object has same ID
        #expect(exercise1.id == exercise1.id)
    }
    
    @Test("Exercise description string works")
    func exerciseDescriptionString() async throws {
        let exercise = Exercise(
            name: "Test Exercise",
            description: "Test",
            primaryMuscles: [.chest],
            difficultyLevel: .beginner
        )
        
        let description = exercise.description
        #expect(description.contains("Test Exercise"))
        #expect(description.contains("Beginner"))
        #expect(description.contains("Chest"))
    }
}

// MARK: - WorkoutSession Tests

@Suite("WorkoutSession Model Tests")
@MainActor
struct WorkoutSessionTests {
    
    @Test("WorkoutSession initializes with defaults")
    func sessionInitialization() async throws {
        let session = WorkoutSession()
        
        #expect(session.isCompleted == false)
        #expect(session.endTime == nil)
        #expect(session.notes == nil)
        #expect(session.template == nil)
        #expect(session.completedExercises.isEmpty)
    }
    
    @Test("WorkoutSession duration is nil when not finished")
    func sessionDurationNilWhenOpen() async throws {
        let session = WorkoutSession()
        
        #expect(session.duration == nil)
    }
    
    @Test("WorkoutSession duration calculates correctly")
    func sessionDurationCalculation() async throws {
        let start = Date()
        let session = WorkoutSession(startTime: start)
        session.endTime = start.addingTimeInterval(3600) // 1 hour later
        
        #expect(session.duration == 3600)
    }
    
    @Test("WorkoutSession date returns startTime")
    func sessionDateProperty() async throws {
        let start = Date()
        let session = WorkoutSession(startTime: start)
        
        #expect(session.date == start)
    }
}

// MARK: - ExerciseSet Tests

@Suite("ExerciseSet Model Tests")
@MainActor
struct ExerciseSetTests {
    
    @Test("ExerciseSet initializes with defaults")
    func setInitialization() async throws {
        let set = ExerciseSet(setNumber: 1)
        
        #expect(set.setNumber == 1)
        #expect(set.weight == 0)
        #expect(set.reps == 0)
        #expect(set.isCompleted == false)
        #expect(set.completedAt == nil)
        #expect(set.rpe == nil)
    }
    
    @Test("ExerciseSet initializes with custom values")
    func setCustomInitialization() async throws {
        let set = ExerciseSet(
            setNumber: 3,
            weight: 100.0,
            reps: 8,
            isCompleted: true,
            rpe: 8
        )
        
        #expect(set.setNumber == 3)
        #expect(set.weight == 100.0)
        #expect(set.reps == 8)
        #expect(set.isCompleted == true)
        #expect(set.rpe == 8)
    }
}

// MARK: - CompletedExercise Tests

@Suite("CompletedExercise Model Tests")
@MainActor
struct CompletedExerciseTests {
    
    @Test("CompletedExercise initializes with defaults")
    func completedExerciseInitialization() async throws {
        let completed = CompletedExercise(order: 0)
        
        #expect(completed.order == 0)
        #expect(completed.notes == nil)
        #expect(completed.sets.isEmpty)
        #expect(completed.exercise == nil)
        #expect(completed.session == nil)
    }
    
    @Test("CompletedExercise initializes with notes")
    func completedExerciseWithNotes() async throws {
        let completed = CompletedExercise(order: 2, notes: "Felt strong today")
        
        #expect(completed.order == 2)
        #expect(completed.notes == "Felt strong today")
    }
}

// MARK: - WorkoutTemplate Tests

@Suite("WorkoutTemplate Model Tests")
@MainActor
struct WorkoutTemplateTests {
    
    @Test("WorkoutTemplate initializes with defaults")
    func templateInitialization() async throws {
        let template = WorkoutTemplate(name: "Push Day")
        
        #expect(template.name == "Push Day")
        #expect(template.templateDescription == "")
        #expect(template.isPreBuilt == false)
        #expect(template.lastUsedDate == nil)
        #expect(template.exercises.isEmpty)
    }
    
    @Test("WorkoutTemplate initializes as pre-built")
    func preBuiltTemplate() async throws {
        let template = WorkoutTemplate(
            name: "PPL Push",
            description: "Push day for Push/Pull/Legs split",
            isPreBuilt: true
        )
        
        #expect(template.isPreBuilt == true)
        #expect(template.templateDescription == "Push day for Push/Pull/Legs split")
    }
}

// MARK: - TemplateExercise Tests

@Suite("TemplateExercise Model Tests")
@MainActor
struct TemplateExerciseTests {
    
    @Test("TemplateExercise initializes with defaults")
    func templateExerciseInitialization() async throws {
        let te = TemplateExercise(order: 0, targetSets: 3, targetReps: 10)
        
        #expect(te.order == 0)
        #expect(te.targetSets == 3)
        #expect(te.targetReps == 10)
        #expect(te.restSeconds == 90)
        #expect(te.notes == nil)
    }
    
    @Test("TemplateExercise initializes with custom rest time")
    func templateExerciseCustomRest() async throws {
        let te = TemplateExercise(
            order: 1,
            targetSets: 5,
            targetReps: 5,
            restSeconds: 180,
            notes: "Heavy compound lift"
        )
        
        #expect(te.restSeconds == 180)
        #expect(te.notes == "Heavy compound lift")
    }
}

// MARK: - UserSettings Tests

@Suite("UserSettings Model Tests")
@MainActor
struct UserSettingsTests {
    
    @Test("UserSettings initializes with defaults")
    func settingsInitialization() async throws {
        let settings = UserSettings()
        
        #expect(settings.unit == .kg)
        #expect(settings.defaultRestTime == 90)
        #expect(settings.notificationsEnabled == false)
        #expect(settings.notificationTime == nil)
        #expect(settings.preferredEquipment.isEmpty)
        #expect(settings.splitType == nil)
    }
    
    @Test("UserSettings type-safe computed properties work")
    func settingsComputedProperties() async throws {
        let settings = UserSettings()
        
        settings.unit = .lbs
        #expect(settings.weightUnit == "Pounds")
        #expect(settings.unit == .lbs)
        
        settings.splitType = .pushPullLegs
        #expect(settings.preferredSplitType == "Push/Pull/Legs")
        #expect(settings.splitType == .pushPullLegs)
        
        settings.splitType = nil
        #expect(settings.preferredSplitType == nil)
    }
}

// MARK: - MuscleRecoveryState Tests

@Suite("MuscleRecoveryState Model Tests")
@MainActor
struct MuscleRecoveryStateTests {
    
    @Test("MuscleRecoveryState initializes with defaults")
    func recoveryStateInitialization() async throws {
        let state = MuscleRecoveryState(muscleGroup: .chest)
        
        #expect(state.muscleGroup == "Chest")
        #expect(state.muscle == .chest)
        #expect(state.fatigueLevel == 0.0)
        #expect(state.recoveryPercentage == 1.0)
    }
    
    @Test("MuscleRecoveryState recovery percentage is inverse of fatigue")
    func recoveryPercentageCalculation() async throws {
        let state = MuscleRecoveryState(muscleGroup: .quadriceps, fatigueLevel: 0.7)
        
        #expect(state.fatigueLevel == 0.7)
        #expect(abs(state.recoveryPercentage - 0.3) < 0.001)
    }
    
    @Test("MuscleRecoveryState muscle group lookup works")
    func muscleGroupLookup() async throws {
        let state = MuscleRecoveryState(muscleGroup: .lats)
        
        #expect(state.muscle == .lats)
        #expect(state.muscle?.category == .upperBody)
    }
}

// MARK: - Exercise Database JSON Tests

@Suite("Exercise Database Tests")
@MainActor
struct ExerciseDatabaseTests {
    
    /// Decodable structs matching exercises.json format
    private struct ExerciseJSON: Decodable {
        let id: String
        let name: String
        let description: String
        let instructions: [String]
        let equipment: [String]
        let primaryMuscles: [String]
        let secondaryMuscles: [String]
        let difficultyLevel: String
    }
    
    private struct ExerciseFile: Decodable {
        let exercises: [ExerciseJSON]
    }
    
    @Test("exercises.json exists in bundle and is valid JSON")
    func exercisesJsonIsValid() async throws {
        let url = try #require(Bundle.main.url(forResource: "exercises", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(ExerciseFile.self, from: data)
        
        #expect(file.exercises.count >= 50)
    }
    
    @Test("All exercises have valid UUIDs")
    func exercisesHaveValidUUIDs() async throws {
        let exercises = try loadExercises()
        
        for exercise in exercises {
            #expect(UUID(uuidString: exercise.id) != nil, "Invalid UUID: \(exercise.id) for \(exercise.name)")
        }
        
        // All UUIDs should be unique
        let ids = Set(exercises.map(\.id))
        #expect(ids.count == exercises.count, "Duplicate UUIDs found")
    }
    
    @Test("All exercises have valid muscle groups")
    func exercisesHaveValidMuscleGroups() async throws {
        let exercises = try loadExercises()
        let validMuscles = Set(MuscleGroup.allCases.map(\.rawValue))
        
        for exercise in exercises {
            #expect(!exercise.primaryMuscles.isEmpty, "\(exercise.name) has no primary muscles")
            
            for muscle in exercise.primaryMuscles {
                #expect(validMuscles.contains(muscle), "\(exercise.name) has invalid primary muscle: \(muscle)")
            }
            for muscle in exercise.secondaryMuscles {
                #expect(validMuscles.contains(muscle), "\(exercise.name) has invalid secondary muscle: \(muscle)")
            }
        }
    }
    
    @Test("All exercises have valid difficulty levels")
    func exercisesHaveValidDifficultyLevels() async throws {
        let exercises = try loadExercises()
        let validLevels = Set(DifficultyLevel.allCases.map(\.rawValue))
        
        for exercise in exercises {
            #expect(validLevels.contains(exercise.difficultyLevel),
                    "\(exercise.name) has invalid difficulty: \(exercise.difficultyLevel)")
        }
    }
    
    @Test("All exercises have instructions")
    func exercisesHaveInstructions() async throws {
        let exercises = try loadExercises()
        
        for exercise in exercises {
            #expect(!exercise.instructions.isEmpty, "\(exercise.name) has no instructions")
            #expect(exercise.instructions.count >= 3, "\(exercise.name) has fewer than 3 instructions")
        }
    }
    
    @Test("SeedDataService loads exercises into model context")
    @MainActor
    func seedDataServiceWorks() async throws {
        let schema = Schema([
            Exercise.self,
            TemplateExercise.self,
            WorkoutTemplate.self,
            WorkoutSession.self,
            CompletedExercise.self,
            ExerciseSet.self,
            UserSettings.self,
            MuscleRecoveryState.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        
        // Should be empty before seeding
        let beforeCount = try context.fetchCount(FetchDescriptor<Exercise>())
        #expect(beforeCount == 0)
        
        // Seed
        SeedDataService.seedIfNeeded(modelContext: context)
        
        // Should have exercises now
        let afterCount = try context.fetchCount(FetchDescriptor<Exercise>())
        #expect(afterCount >= 50)
        
        // Seeding again should be a no-op
        SeedDataService.seedIfNeeded(modelContext: context)
        let secondCount = try context.fetchCount(FetchDescriptor<Exercise>())
        #expect(secondCount == afterCount)
    }
    
    // MARK: - Helper
    
    private func loadExercises() throws -> [ExerciseJSON] {
        let url = Bundle.main.url(forResource: "exercises", withExtension: "json")!
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ExerciseFile.self, from: data).exercises
    }
}

// MARK: - Recovery Engine Tests
@Suite("PR #7: Recovery Engine Tests")
@MainActor
struct RecoveryEngineTests {
    
    @Test("Zero volume produces zero fatigue")
    func zeroVolume() {
        let fatigue = RecoveryEngine.normalizeFatigue(volume: 0)
        #expect(fatigue == 0.0)
    }
    
    @Test("Moderate volume produces reasonable fatigue")
    func moderateVolume() {
        // 4 sets × 10 reps × 100 kg = 4000 volume
        let fatigue = RecoveryEngine.normalizeFatigue(volume: 4000)
        // Should be around 0.5-0.7 range
        #expect(fatigue > 0.4)
        #expect(fatigue < 0.8)
    }
    
    @Test("Very high volume saturates below 1.0")
    func highVolumeSaturation() {
        let fatigue = RecoveryEngine.normalizeFatigue(volume: 50000)
        #expect(fatigue <= 0.85)
        #expect(fatigue > 0.8)
    }
    
    @Test("Fatigue decays to ~50% after one half-life")
    func exponentialDecayHalfLife() {
        let muscle = MuscleGroup.chest // 72h recovery, halfLife = 28.8h
        let halfLife = Double(muscle.defaultRecoveryHours) / 2.5
        let start = Date()
        let afterHalfLife = start.addingTimeInterval(halfLife * 3600)
        
        let fatigue = RecoveryEngine.currentFatigue(
            storedFatigue: 0.8,
            lastUpdated: start,
            muscleGroup: muscle,
            now: afterHalfLife
        )
        
        // Should be ~0.4 (half of 0.8)
        #expect(fatigue > 0.35)
        #expect(fatigue < 0.45)
    }
    
    @Test("Full recovery after enough time")
    func fullRecoveryAfterTime() {
        let muscle = MuscleGroup.biceps // 48h recovery
        let start = Date()
        // 10 days later — well past recovery time
        let tenDaysLater = start.addingTimeInterval(10 * 24 * 3600)
        
        let fatigue = RecoveryEngine.currentFatigue(
            storedFatigue: 0.9,
            lastUpdated: start,
            muscleGroup: muscle,
            now: tenDaysLater
        )
        
        #expect(fatigue == 0.0) // Below 0.01 threshold
    }
    
    @Test("No decay when no time has passed")
    func noDecayAtZeroTime() {
        let now = Date()
        let fatigue = RecoveryEngine.currentFatigue(
            storedFatigue: 0.7,
            lastUpdated: now,
            muscleGroup: .chest,
            now: now
        )
        #expect(fatigue == 0.7)
    }
    
    @Test("Secondary muscles get 50% volume contribution")
    func secondaryMuscleContribution() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: WorkoutSession.self, CompletedExercise.self, ExerciseSet.self,
            Exercise.self, WorkoutTemplate.self, TemplateExercise.self,
            configurations: config
        )
        let context = container.mainContext
        
        let exercise = Exercise(
            name: "Bench Press",
            description: "Test",
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders]
        )
        context.insert(exercise)
        
        let session = WorkoutSession()
        context.insert(session)
        
        let ce = CompletedExercise(order: 0)
        ce.exercise = exercise
        ce.session = session
        session.completedExercises.append(ce)
        context.insert(ce)
        
        let set1 = ExerciseSet(setNumber: 1, weight: 100, reps: 10, isCompleted: true)
        set1.completedExercise = ce
        ce.sets.append(set1)
        context.insert(set1)
        
        let deltas = RecoveryEngine.calculateFatigueDeltas(for: session)
        
        // Chest (primary) should have full volume contribution
        let chestDelta = deltas[.chest] ?? 0
        // Triceps (secondary) should have half the volume
        let tricepsDelta = deltas[.triceps] ?? 0
        
        #expect(chestDelta > tricepsDelta)
        // Volume = 100 × 10 = 1000 for primary, 500 for secondary
        let primaryFatigue = RecoveryEngine.normalizeFatigue(volume: 1000)
        let secondaryFatigue = RecoveryEngine.normalizeFatigue(volume: 500)
        #expect(abs(chestDelta - primaryFatigue) < 0.001)
        #expect(abs(tricepsDelta - secondaryFatigue) < 0.001)
    }
    
    @Test("Recovery percentage accounts for elapsed time")
    func recoveryPercentageWithTime() {
        let state = MuscleRecoveryState(muscleGroup: .chest, fatigueLevel: 0.8)
        // Stored recovery = 0.2 (20%) — use approximate comparison for floating point
        #expect(abs(state.recoveryPercentage - 0.2) < 0.001)
        
        // Dynamic recovery should be higher after time passes
        // (currentRecoveryPercentage uses Date() internally, so it should
        // be approximately 0.2 since almost no time has passed)
        let dynamicRecovery = state.currentRecoveryPercentage
        // Should be close to 0.2 since we just created it
        #expect(dynamicRecovery >= 0.19)
        #expect(dynamicRecovery <= 0.25)
    }
    
    @Test("Estimate full recovery date is in the future for fatigued muscles")
    func estimateRecoveryDate() {
        let now = Date()
        let recoveryDate = RecoveryEngine.estimateFullRecoveryDate(
            fatigue: 0.8,
            muscleGroup: .chest,
            from: now
        )
        #expect(recoveryDate > now)
        
        // For zero fatigue, recovery date should be now
        let noFatigueDate = RecoveryEngine.estimateFullRecoveryDate(
            fatigue: 0.0,
            muscleGroup: .chest,
            from: now
        )
        #expect(noFatigueDate == now)
    }
}

// MARK: - Test Helpers

/// Shared helper to create an in-memory ModelContainer with all model types.
@MainActor
private func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([
        Exercise.self,
        TemplateExercise.self,
        WorkoutTemplate.self,
        WorkoutSession.self,
        CompletedExercise.self,
        ExerciseSet.self,
        UserSettings.self,
        MuscleRecoveryState.self,
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}
/// Creates a simple exercise for testing purposes.
@MainActor
private func makeExercise(
    name: String = "Test Exercise",
    primary: [MuscleGroup] = [.chest],
    secondary: [MuscleGroup] = [.triceps],
    difficulty: DifficultyLevel = .intermediate,
    equipment: [String] = ["Barbell"]
) -> Exercise {
    Exercise(
        name: name,
        description: "Test exercise description",
        equipment: equipment,
        primaryMuscles: primary,
        secondaryMuscles: secondary,
        difficultyLevel: difficulty
    )
}

/// Creates a completed workout session with exercises and sets, inserts into context.
@MainActor
private func makeCompletedSession(
    context: ModelContext,
    exercises: [Exercise],
    setsPerExercise: Int = 3,
    weight: Double = 100,
    reps: Int = 10,
    startTime: Date = Date(),
    templateName: String? = nil
) -> WorkoutSession {
    let session = WorkoutSession(startTime: startTime)
    session.endTime = startTime.addingTimeInterval(3600)
    session.isCompleted = true
    session.notes = "Test session"
    context.insert(session)
    
    if let templateName {
        let template = WorkoutTemplate(name: templateName)
        context.insert(template)
        session.template = template
    }
    
    for (index, exercise) in exercises.enumerated() {
        let ce = CompletedExercise(order: index)
        ce.exercise = exercise
        ce.session = session
        context.insert(ce)
        
        for setNum in 1...setsPerExercise {
            let set = ExerciseSet(
                setNumber: setNum,
                weight: weight,
                reps: reps,
                isCompleted: true
            )
            set.completedAt = startTime.addingTimeInterval(Double(setNum * 180))
            set.completedExercise = ce
            context.insert(set)
        }
    }
    
    return session
}

// MARK: - Export Service Tests

@Suite("ExportService Tests")
@MainActor
struct ExportServiceTests {
    
    @Test("Export produces valid JSON with correct structure")
    func exportProducesValidJSON() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let exercise = makeExercise(name: "Bench Press")
        context.insert(exercise)
        
        let _ = makeCompletedSession(context: context, exercises: [exercise])
        
        let data = try ExportService.exportAll(modelContext: context)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportService.ExportData.self, from: data)
        
        #expect(exportData.version == 1)
        #expect(exportData.sessions.count == 1)
    }
    
    @Test("Export includes session details correctly")
    func exportSessionDetails() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let exercise = makeExercise(name: "Squat")
        context.insert(exercise)
        
        let startTime = Date()
        let session = makeCompletedSession(
            context: context,
            exercises: [exercise],
            setsPerExercise: 3,
            weight: 140,
            reps: 5,
            startTime: startTime,
            templateName: "Leg Day"
        )
        
        let data = try ExportService.exportAll(modelContext: context)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportService.ExportData.self, from: data)
        
        let exported = try #require(exportData.sessions.first)
        #expect(exported.id == session.id.uuidString)
        #expect(exported.templateName == "Leg Day")
        #expect(exported.notes == "Test session")
        #expect(exported.endTime != nil)
    }
    
    @Test("Export includes exercise and set data")
    func exportExerciseAndSetData() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let bench = makeExercise(name: "Bench Press")
        let curl = makeExercise(name: "Barbell Curl", primary: [.biceps], secondary: [.forearms])
        context.insert(bench)
        context.insert(curl)
        
        let _ = makeCompletedSession(
            context: context,
            exercises: [bench, curl],
            setsPerExercise: 3,
            weight: 80,
            reps: 10
        )
        
        let data = try ExportService.exportAll(modelContext: context)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportService.ExportData.self, from: data)
        
        let session = try #require(exportData.sessions.first)
        #expect(session.exercises.count == 2)
        
        let firstExercise = session.exercises.sorted(by: { $0.order < $1.order }).first!
        #expect(firstExercise.sets.count == 3)
        #expect(firstExercise.sets.first?.weight == 80)
        #expect(firstExercise.sets.first?.reps == 10)
    }
    
    @Test("Export includes settings when present")
    func exportIncludesSettings() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let settings = UserSettings()
        settings.unit = .lbs
        settings.defaultRestTime = 120
        settings.splitType = .pushPullLegs
        context.insert(settings)
        
        let data = try ExportService.exportAll(modelContext: context)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportService.ExportData.self, from: data)
        
        let exported = try #require(exportData.settings)
        #expect(exported.weightUnit == "Pounds")
        #expect(exported.defaultRestTime == 120)
        #expect(exported.preferredSplitType == "Push/Pull/Legs")
    }
    
    @Test("Export with no sessions returns empty array")
    func exportEmptySessions() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let data = try ExportService.exportAll(modelContext: context)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportService.ExportData.self, from: data)
        
        #expect(exportData.sessions.isEmpty)
        #expect(exportData.settings == nil)
    }
    
    @Test("Export only includes completed sessions")
    func exportOnlyCompletedSessions() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let exercise = makeExercise(name: "Row")
        context.insert(exercise)
        
        // Create one completed session
        let _ = makeCompletedSession(context: context, exercises: [exercise])
        
        // Create one incomplete session
        let incomplete = WorkoutSession()
        incomplete.isCompleted = false
        context.insert(incomplete)
        
        let data = try ExportService.exportAll(modelContext: context)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportService.ExportData.self, from: data)
        
        #expect(exportData.sessions.count == 1)
    }
    
    @Test("Export to file creates valid file on disk")
    func exportToFileWorks() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let url = try ExportService.exportToFile(modelContext: context)
        
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(url.pathExtension == "json")
        #expect(url.lastPathComponent.hasPrefix("workout-export-"))
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Import Service Tests

@Suite("ImportService Tests")
@MainActor
struct ImportServiceTests {
    
    @Test("Import decodes exported data correctly")
    func importRoundTrip() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let exercise = makeExercise(name: "Bench Press")
        context.insert(exercise)
        
        let _ = makeCompletedSession(context: context, exercises: [exercise], setsPerExercise: 3, weight: 100, reps: 10)
        
        let settings = UserSettings()
        settings.unit = .kg
        settings.defaultRestTime = 90
        context.insert(settings)
        
        // Export
        let exportedData = try ExportService.exportAll(modelContext: context)
        
        // Import into a fresh context
        let container2 = try makeTestContainer()
        let context2 = container2.mainContext
        
        // Need an exercise in the import context for name matching
        let exercise2 = makeExercise(name: "Bench Press")
        context2.insert(exercise2)
        
        // Need settings in the import context for settings import
        let settings2 = UserSettings()
        context2.insert(settings2)
        
        let result = try ImportService.importData(from: exportedData, modelContext: context2)
        
        #expect(result.sessionsImported == 1)
        #expect(result.settingsImported == true)
    }
    
    @Test("Import skips duplicate sessions by ID")
    func importSkipsDuplicates() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let exercise = makeExercise(name: "Squat")
        context.insert(exercise)
        let _ = makeCompletedSession(context: context, exercises: [exercise])
        
        // Export
        let exportedData = try ExportService.exportAll(modelContext: context)
        
        // Import into the same context (sessions already exist)
        let result = try ImportService.importData(from: exportedData, modelContext: context)
        
        #expect(result.sessionsImported == 0) // Skipped because IDs match
    }
    
    @Test("Import rejects unsupported version")
    func importRejectsUnsupportedVersion() throws {
        let json = """
        {
            "exportDate": "2026-01-01T00:00:00Z",
            "version": 99,
            "sessions": [],
            "settings": null
        }
        """
        let data = Data(json.utf8)
        let container = try makeTestContainer()
        let context = container.mainContext
        
        #expect(throws: ImportService.ImportError.self) {
            try ImportService.importData(from: data, modelContext: context)
        }
    }
    
    @Test("Import rejects invalid JSON")
    func importRejectsInvalidJSON() throws {
        let data = Data("not json at all".utf8)
        let container = try makeTestContainer()
        let context = container.mainContext
        
        #expect(throws: ImportService.ImportError.self) {
            try ImportService.importData(from: data, modelContext: context)
        }
    }
    
    @Test("Import matches exercises by name")
    func importMatchesExercisesByName() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        // Create an exercise and a completed session
        let exercise = makeExercise(name: "Deadlift")
        context.insert(exercise)
        let _ = makeCompletedSession(context: context, exercises: [exercise])
        
        let exportedData = try ExportService.exportAll(modelContext: context)
        
        // Import into fresh context that has the same exercise by name
        let container2 = try makeTestContainer()
        let context2 = container2.mainContext
        let matchExercise = makeExercise(name: "Deadlift")
        context2.insert(matchExercise)
        
        let result = try ImportService.importData(from: exportedData, modelContext: context2)
        #expect(result.sessionsImported == 1)
        
        // Verify the imported session's completed exercise is linked to the matching exercise
        let sessions = try context2.fetch(FetchDescriptor<WorkoutSession>())
        let imported = try #require(sessions.first)
        let ce = try #require(imported.completedExercises.first)
        #expect(ce.exercise?.name == "Deadlift")
        #expect(ce.exercise?.id == matchExercise.id)
    }
    
    @Test("Import creates sets correctly")
    func importCreatesSetsCorrectly() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let exercise = makeExercise(name: "OHP")
        context.insert(exercise)
        let _ = makeCompletedSession(context: context, exercises: [exercise], setsPerExercise: 4, weight: 60, reps: 8)
        
        let exportedData = try ExportService.exportAll(modelContext: context)
        
        let container2 = try makeTestContainer()
        let context2 = container2.mainContext
        let exercise2 = makeExercise(name: "OHP")
        context2.insert(exercise2)
        
        let _ = try ImportService.importData(from: exportedData, modelContext: context2)
        
        let sessions = try context2.fetch(FetchDescriptor<WorkoutSession>())
        let session = try #require(sessions.first)
        let ce = try #require(session.completedExercises.first)
        
        #expect(ce.sets.count == 4)
        #expect(ce.sets.allSatisfy { $0.weight == 60 })
        #expect(ce.sets.allSatisfy { $0.reps == 8 })
        #expect(ce.sets.allSatisfy { $0.isCompleted })
    }
    
    @Test("Import updates existing settings")
    func importUpdatesSettings() throws {
        let json = """
        {
            "exportDate": "2026-01-01T00:00:00Z",
            "version": 1,
            "sessions": [],
            "settings": {
                "weightUnit": "Pounds",
                "defaultRestTime": 180,
                "preferredSplitType": "Push/Pull/Legs"
            }
        }
        """
        let data = Data(json.utf8)
        
        let container = try makeTestContainer()
        let context = container.mainContext
        
        // Pre-existing settings with different values
        let settings = UserSettings()
        settings.unit = .kg
        settings.defaultRestTime = 90
        context.insert(settings)
        
        let result = try ImportService.importData(from: data, modelContext: context)
        
        #expect(result.settingsImported == true)
        #expect(settings.weightUnit == "Pounds")
        #expect(settings.defaultRestTime == 180)
        #expect(settings.preferredSplitType == "Push/Pull/Legs")
    }
    
    @Test("Import without settings does not touch existing settings")
    func importWithoutSettingsPreservesExisting() throws {
        let json = """
        {
            "exportDate": "2026-01-01T00:00:00Z",
            "version": 1,
            "sessions": [],
            "settings": null
        }
        """
        let data = Data(json.utf8)
        
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let settings = UserSettings()
        settings.unit = .lbs
        settings.defaultRestTime = 120
        context.insert(settings)
        
        let result = try ImportService.importData(from: data, modelContext: context)
        
        #expect(result.settingsImported == false)
        #expect(settings.unit == .lbs)
        #expect(settings.defaultRestTime == 120)
    }
}

// MARK: - Workout Engine Tests

@Suite("WorkoutEngine Tests")
@MainActor
struct WorkoutEngineTests {
    
    // MARK: - Target Muscle Selection
    
    @Test("Push/Pull/Legs selects push muscles when chest is most recovered")
    func pplSelectsPushWhenChestRecovered() {
        let states = [
            MuscleRecoveryState(muscleGroup: .chest, fatigueLevel: 0.0),      // fully recovered
            MuscleRecoveryState(muscleGroup: .shoulders, fatigueLevel: 0.0),
            MuscleRecoveryState(muscleGroup: .triceps, fatigueLevel: 0.0),
            MuscleRecoveryState(muscleGroup: .lats, fatigueLevel: 0.8),        // fatigued
            MuscleRecoveryState(muscleGroup: .traps, fatigueLevel: 0.8),
            MuscleRecoveryState(muscleGroup: .biceps, fatigueLevel: 0.8),
            MuscleRecoveryState(muscleGroup: .forearms, fatigueLevel: 0.8),
            MuscleRecoveryState(muscleGroup: .quadriceps, fatigueLevel: 0.5),
            MuscleRecoveryState(muscleGroup: .hamstrings, fatigueLevel: 0.5),
            MuscleRecoveryState(muscleGroup: .glutes, fatigueLevel: 0.5),
            MuscleRecoveryState(muscleGroup: .calves, fatigueLevel: 0.5),
        ]
        
        let workout = WorkoutEngine.generateWorkout(
            splitType: .pushPullLegs,
            recoveryStates: states,
            allExercises: makeSampleExercises(),
            recentSessions: []
        )
        
        #expect(workout.name == "Push Day")
        #expect(workout.targetMuscles.contains(.chest))
        #expect(workout.targetMuscles.contains(.shoulders))
        #expect(workout.targetMuscles.contains(.triceps))
    }
    
    @Test("Upper/Lower selects lower when lower body is most recovered")
    func upperLowerSelectsLower() {
        var states: [MuscleRecoveryState] = []
        // Upper body all fatigued
        for muscle in [MuscleGroup.chest, .shoulders, .biceps, .triceps, .lats, .traps, .forearms] {
            states.append(MuscleRecoveryState(muscleGroup: muscle, fatigueLevel: 0.9))
        }
        // Lower body all recovered
        for muscle in [MuscleGroup.quadriceps, .hamstrings, .glutes, .calves] {
            states.append(MuscleRecoveryState(muscleGroup: muscle, fatigueLevel: 0.0))
        }
        
        let workout = WorkoutEngine.generateWorkout(
            splitType: .upperLower,
            recoveryStates: states,
            allExercises: makeSampleExercises(),
            recentSessions: []
        )
        
        #expect(workout.name == "Lower Body")
        #expect(workout.targetMuscles.contains(.quadriceps))
        #expect(workout.targetMuscles.contains(.hamstrings))
    }
    
    @Test("Full body picks most recovered muscles across all groups")
    func fullBodyPicksMostRecovered() {
        var states: [MuscleRecoveryState] = []
        for muscle in MuscleGroup.allCases {
            // Make only a few muscles recovered enough (>= 0.70)
            let fatigue: Double = (muscle == .chest || muscle == .lats || muscle == .quadriceps) ? 0.0 : 0.9
            states.append(MuscleRecoveryState(muscleGroup: muscle, fatigueLevel: fatigue))
        }
        
        let workout = WorkoutEngine.generateWorkout(
            splitType: .fullBody,
            recoveryStates: states,
            allExercises: makeSampleExercises(),
            recentSessions: []
        )
        
        #expect(workout.name == "Full Body")
        #expect(workout.targetMuscles.contains(.chest))
        #expect(workout.targetMuscles.contains(.lats))
        #expect(workout.targetMuscles.contains(.quadriceps))
    }
    
    // MARK: - Exercise Selection
    
    @Test("Generated workout has 1-5 exercises")
    func generatedWorkoutExerciseCount() {
        let workout = WorkoutEngine.generateWorkout(
            splitType: .pushPullLegs,
            recoveryStates: allRecoveredStates(),
            allExercises: makeSampleExercises(),
            recentSessions: []
        )
        
        #expect(workout.exercises.count >= 1)
        #expect(workout.exercises.count <= 5)
    }
    
    @Test("Compound exercises are prioritized")
    func compoundExercisesPrioritized() {
        let exercises = makeSampleExercises()
        
        let workout = WorkoutEngine.generateWorkout(
            splitType: .pushPullLegs,
            recoveryStates: allRecoveredStates(),
            allExercises: exercises,
            recentSessions: []
        )
        
        // First exercise should be compound (has multiple primary muscles or is a known compound)
        if let first = workout.exercises.first {
            #expect(first.exercise.isCompound)
        }
    }
    
    @Test("Compound exercises get heavier sets/reps recommendation")
    func compoundGetsHeavierSetsReps() {
        let exercises = makeSampleExercises()
        
        let workout = WorkoutEngine.generateWorkout(
            splitType: .pushPullLegs,
            recoveryStates: allRecoveredStates(),
            allExercises: exercises,
            recentSessions: []
        )
        
        // Compound exercises early in the workout should get 4 sets of 8
        for suggestion in workout.exercises {
            if suggestion.exercise.isCompound {
                #expect(suggestion.targetSets >= 3)
                #expect(suggestion.targetReps <= 10)
            } else {
                // Isolation gets 3 sets of 12
                #expect(suggestion.targetSets == 3)
                #expect(suggestion.targetReps == 12)
            }
        }
    }
    
    @Test("Generated workout has a minimum estimated duration")
    func minimumEstimatedDuration() {
        let workout = WorkoutEngine.generateWorkout(
            splitType: .fullBody,
            recoveryStates: allRecoveredStates(),
            allExercises: makeSampleExercises(),
            recentSessions: []
        )
        
        #expect(workout.estimatedDuration >= 20)
    }
    
    @Test("Workout name follows split type convention")
    func workoutNameConvention() {
        let recovered = allRecoveredStates()
        let exercises = makeSampleExercises()
        
        let fullBody = WorkoutEngine.generateWorkout(
            splitType: .fullBody,
            recoveryStates: recovered,
            allExercises: exercises,
            recentSessions: []
        )
        #expect(fullBody.name == "Full Body")
    }
    
    // MARK: - Create Template
    
    @Test("createTemplate produces a valid WorkoutTemplate")
    func createTemplateWorks() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        
        let exercises = makeSampleExercises()
        for ex in exercises { context.insert(ex) }
        
        let workout = WorkoutEngine.generateWorkout(
            splitType: .pushPullLegs,
            recoveryStates: allRecoveredStates(),
            allExercises: exercises,
            recentSessions: []
        )
        
        let template = WorkoutEngine.createTemplate(from: workout, modelContext: context)
        
        #expect(template.name == workout.name)
        #expect(template.templateDescription == "AI-generated workout")
        
        let templateExercises = try context.fetch(FetchDescriptor<TemplateExercise>())
        #expect(templateExercises.count == workout.exercises.count)
        
        // Verify each template exercise has correct sets/reps
        for (index, suggestion) in workout.exercises.enumerated() {
            let te = templateExercises.first { $0.order == index }
            #expect(te?.targetSets == suggestion.targetSets)
            #expect(te?.targetReps == suggestion.targetReps)
            #expect(te?.exercise?.id == suggestion.exercise.id)
        }
    }
    
    @Test("Each target muscle gets at least one exercise")
    func eachTargetMuscleGetsCoverage() {
        let workout = WorkoutEngine.generateWorkout(
            splitType: .pushPullLegs,
            recoveryStates: allRecoveredStates(),
            allExercises: makeSampleExercises(),
            recentSessions: []
        )
        
        let coveredMuscles = Set(workout.exercises.flatMap { $0.exercise.primaryMuscleGroups })
        
        for muscle in workout.targetMuscles {
            #expect(coveredMuscles.contains(muscle), "Target muscle \(muscle.rawValue) not covered by any exercise")
        }
    }
    
    // MARK: - Helpers
    
    private func makeSampleExercises() -> [Exercise] {
        [
            // Push exercises
            Exercise(name: "Barbell Bench Press", description: "Compound chest", equipment: ["Barbell"], primaryMuscles: [.chest, .shoulders], secondaryMuscles: [.triceps], difficultyLevel: .intermediate),
            Exercise(name: "Incline Dumbbell Press", description: "Upper chest", equipment: ["Dumbbell"], primaryMuscles: [.chest], secondaryMuscles: [.shoulders, .triceps], difficultyLevel: .intermediate),
            Exercise(name: "Overhead Press", description: "Shoulder press", equipment: ["Barbell"], primaryMuscles: [.shoulders], secondaryMuscles: [.triceps], difficultyLevel: .intermediate),
            Exercise(name: "Lateral Raise", description: "Side delts", equipment: ["Dumbbell"], primaryMuscles: [.shoulders], difficultyLevel: .beginner),
            Exercise(name: "Tricep Pushdown", description: "Tricep isolation", equipment: ["Cable Machine"], primaryMuscles: [.triceps], difficultyLevel: .beginner),
            
            // Pull exercises
            Exercise(name: "Barbell Row", description: "Compound back", equipment: ["Barbell"], primaryMuscles: [.lats, .traps], secondaryMuscles: [.biceps], difficultyLevel: .intermediate),
            Exercise(name: "Pull-ups", description: "Compound back", equipment: ["Pull-up Bar"], primaryMuscles: [.lats], secondaryMuscles: [.biceps, .traps], difficultyLevel: .intermediate),
            Exercise(name: "Barbell Curl", description: "Bicep isolation", equipment: ["Barbell"], primaryMuscles: [.biceps], secondaryMuscles: [.forearms], difficultyLevel: .beginner),
            Exercise(name: "Face Pulls", description: "Rear delts", equipment: ["Cable Machine"], primaryMuscles: [.shoulders, .traps], difficultyLevel: .beginner),
            
            // Leg exercises
            Exercise(name: "Barbell Squat", description: "Compound legs", equipment: ["Barbell"], primaryMuscles: [.quadriceps, .glutes], secondaryMuscles: [.hamstrings], difficultyLevel: .intermediate),
            Exercise(name: "Romanian Deadlift", description: "Hamstring focus", equipment: ["Barbell"], primaryMuscles: [.hamstrings, .lowerBack], secondaryMuscles: [.glutes], difficultyLevel: .intermediate),
            Exercise(name: "Leg Press", description: "Leg compound", equipment: ["Leg Press Machine"], primaryMuscles: [.quadriceps, .glutes], secondaryMuscles: [.hamstrings], difficultyLevel: .beginner),
            Exercise(name: "Leg Curl", description: "Hamstring isolation", equipment: ["Leg Curl Machine"], primaryMuscles: [.hamstrings], difficultyLevel: .beginner),
            Exercise(name: "Calf Raise", description: "Calf isolation", equipment: ["Bodyweight"], primaryMuscles: [.calves], difficultyLevel: .beginner),
        ]
    }
    
    private func allRecoveredStates() -> [MuscleRecoveryState] {
        MuscleGroup.allCases.map { MuscleRecoveryState(muscleGroup: $0, fatigueLevel: 0.0) }
    }
}

