package com.dexwritescode.workout

import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.MuscleRecoveryState
import com.dexwritescode.workout.data.model.enums.DifficultyLevel
import com.dexwritescode.workout.data.model.enums.MuscleGroup
import com.dexwritescode.workout.data.model.enums.SplitType
import com.dexwritescode.workout.data.services.workout.WorkoutEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WorkoutEngineTest {

    // ── Target muscle selection ────────────────────────────────────────────────

    @Test
    fun `PPL selects push day when chest group is most recovered`() {
        val states = buildList {
            listOf(MuscleGroup.CHEST, MuscleGroup.SHOULDERS, MuscleGroup.TRICEPS)
                .forEach { add(MuscleRecoveryState(it.rawValue, fatigueLevel = 0.0)) }
            listOf(MuscleGroup.LATS, MuscleGroup.TRAPS, MuscleGroup.BICEPS, MuscleGroup.FOREARMS)
                .forEach { add(MuscleRecoveryState(it.rawValue, fatigueLevel = 0.8)) }
            listOf(MuscleGroup.QUADRICEPS, MuscleGroup.HAMSTRINGS, MuscleGroup.GLUTES, MuscleGroup.CALVES)
                .forEach { add(MuscleRecoveryState(it.rawValue, fatigueLevel = 0.5)) }
        }

        val workout = WorkoutEngine.generateWorkout(SplitType.PUSH_PULL_LEGS, states, sampleExercises(), emptyList())

        assertEquals("Push Day", workout.name)
        assertTrue(MuscleGroup.CHEST in workout.targetMuscles)
        assertTrue(MuscleGroup.SHOULDERS in workout.targetMuscles)
        assertTrue(MuscleGroup.TRICEPS in workout.targetMuscles)
    }

    @Test
    fun `upper lower selects lower body when lower is most recovered`() {
        val states = buildList {
            listOf(MuscleGroup.CHEST, MuscleGroup.SHOULDERS, MuscleGroup.BICEPS, MuscleGroup.TRICEPS,
                   MuscleGroup.LATS, MuscleGroup.TRAPS, MuscleGroup.FOREARMS)
                .forEach { add(MuscleRecoveryState(it.rawValue, fatigueLevel = 0.9)) }
            listOf(MuscleGroup.QUADRICEPS, MuscleGroup.HAMSTRINGS, MuscleGroup.GLUTES, MuscleGroup.CALVES)
                .forEach { add(MuscleRecoveryState(it.rawValue, fatigueLevel = 0.0)) }
        }

        val workout = WorkoutEngine.generateWorkout(SplitType.UPPER_LOWER, states, sampleExercises(), emptyList())

        assertEquals("Lower Body", workout.name)
        assertTrue(MuscleGroup.QUADRICEPS in workout.targetMuscles)
        assertTrue(MuscleGroup.HAMSTRINGS in workout.targetMuscles)
    }

    @Test
    fun `full body picks most recovered muscles across all groups`() {
        val states = MuscleGroup.entries.map { muscle ->
            val fatigue = if (muscle in listOf(MuscleGroup.CHEST, MuscleGroup.LATS, MuscleGroup.QUADRICEPS)) 0.0 else 0.9
            MuscleRecoveryState(muscle.rawValue, fatigueLevel = fatigue)
        }

        val workout = WorkoutEngine.generateWorkout(SplitType.FULL_BODY, states, sampleExercises(), emptyList())

        assertEquals("Full Body", workout.name)
        assertTrue(MuscleGroup.CHEST in workout.targetMuscles)
        assertTrue(MuscleGroup.LATS in workout.targetMuscles)
        assertTrue(MuscleGroup.QUADRICEPS in workout.targetMuscles)
    }

    // ── Exercise selection ─────────────────────────────────────────────────────

    @Test
    fun `generated workout has between 1 and 5 exercises`() {
        val workout = WorkoutEngine.generateWorkout(SplitType.PUSH_PULL_LEGS, allRecovered(), sampleExercises(), emptyList())
        assertTrue(workout.exercises.size in 1..5)
    }

    @Test
    fun `first exercise is a compound movement`() {
        val workout = WorkoutEngine.generateWorkout(SplitType.PUSH_PULL_LEGS, allRecovered(), sampleExercises(), emptyList())
        val first = workout.exercises.firstOrNull() ?: return
        val isCompound = first.exercise.primaryMuscleGroups.size > 1 || first.exercise.secondaryMuscleGroups.isNotEmpty()
        assertTrue(isCompound)
    }

    @Test
    fun `compound exercises get lower reps and more sets than isolation`() {
        val workout = WorkoutEngine.generateWorkout(SplitType.PUSH_PULL_LEGS, allRecovered(), sampleExercises(), emptyList())
        for (suggestion in workout.exercises) {
            val isCompound = suggestion.exercise.primaryMuscleGroups.size > 1 || suggestion.exercise.secondaryMuscleGroups.isNotEmpty()
            if (isCompound) {
                assertTrue(suggestion.targetReps <= 10)
                assertTrue(suggestion.targetSets >= 3)
            } else {
                assertEquals(3, suggestion.targetSets)
                assertEquals(12, suggestion.targetReps)
            }
        }
    }

    @Test
    fun `estimated duration is at least 20 minutes`() {
        val workout = WorkoutEngine.generateWorkout(SplitType.FULL_BODY, allRecovered(), sampleExercises(), emptyList())
        assertTrue(workout.estimatedDurationMinutes >= 20)
    }

    @Test
    fun `each target muscle has at least one exercise`() {
        val workout = WorkoutEngine.generateWorkout(SplitType.PUSH_PULL_LEGS, allRecovered(), sampleExercises(), emptyList())
        val covered = workout.exercises.flatMap { it.exercise.primaryMuscleGroups }.toSet()
        for (muscle in workout.targetMuscles) {
            assertTrue("$muscle not covered by any exercise", muscle in covered)
        }
    }

    @Test
    fun `full body name is Full Body`() {
        val workout = WorkoutEngine.generateWorkout(SplitType.FULL_BODY, allRecovered(), sampleExercises(), emptyList())
        assertEquals("Full Body", workout.name)
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private fun allRecovered() = MuscleGroup.entries.map {
        MuscleRecoveryState(muscleGroup = it.rawValue, fatigueLevel = 0.0)
    }

    private fun sampleExercises() = listOf(
        ex("Barbell Bench Press", listOf(MuscleGroup.CHEST, MuscleGroup.SHOULDERS), listOf(MuscleGroup.TRICEPS)),
        ex("Incline Dumbbell Press", listOf(MuscleGroup.CHEST), listOf(MuscleGroup.SHOULDERS, MuscleGroup.TRICEPS)),
        ex("Overhead Press", listOf(MuscleGroup.SHOULDERS), listOf(MuscleGroup.TRICEPS)),
        ex("Lateral Raise", listOf(MuscleGroup.SHOULDERS), difficulty = DifficultyLevel.BEGINNER),
        ex("Tricep Pushdown", listOf(MuscleGroup.TRICEPS), difficulty = DifficultyLevel.BEGINNER),
        ex("Barbell Row", listOf(MuscleGroup.LATS, MuscleGroup.TRAPS), listOf(MuscleGroup.BICEPS)),
        ex("Pull-ups", listOf(MuscleGroup.LATS), listOf(MuscleGroup.BICEPS, MuscleGroup.TRAPS)),
        ex("Barbell Curl", listOf(MuscleGroup.BICEPS), listOf(MuscleGroup.FOREARMS), DifficultyLevel.BEGINNER),
        ex("Face Pulls", listOf(MuscleGroup.SHOULDERS, MuscleGroup.TRAPS), difficulty = DifficultyLevel.BEGINNER),
        ex("Barbell Squat", listOf(MuscleGroup.QUADRICEPS, MuscleGroup.GLUTES), listOf(MuscleGroup.HAMSTRINGS)),
        ex("Romanian Deadlift", listOf(MuscleGroup.HAMSTRINGS, MuscleGroup.LOWER_BACK), listOf(MuscleGroup.GLUTES)),
        ex("Leg Press", listOf(MuscleGroup.QUADRICEPS, MuscleGroup.GLUTES), listOf(MuscleGroup.HAMSTRINGS), DifficultyLevel.BEGINNER),
        ex("Leg Curl", listOf(MuscleGroup.HAMSTRINGS), difficulty = DifficultyLevel.BEGINNER),
        ex("Calf Raise", listOf(MuscleGroup.CALVES), difficulty = DifficultyLevel.BEGINNER),
    )

    private fun ex(
        name: String,
        primary: List<MuscleGroup>,
        secondary: List<MuscleGroup> = emptyList(),
        difficulty: DifficultyLevel = DifficultyLevel.INTERMEDIATE,
    ) = Exercise(
        name = name,
        exerciseDescription = "Test",
        primaryMuscles = primary.map { it.rawValue },
        secondaryMuscles = secondary.map { it.rawValue },
        difficultyLevel = difficulty.rawValue,
    )
}
