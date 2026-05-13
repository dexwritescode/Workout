package com.dexwritescode.workout

import com.dexwritescode.workout.data.model.entity.CompletedExercise
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.ExerciseSet
import com.dexwritescode.workout.data.model.entity.MuscleRecoveryState
import com.dexwritescode.workout.data.model.entity.WorkoutSession
import com.dexwritescode.workout.data.model.enums.DifficultyLevel
import com.dexwritescode.workout.data.model.enums.MuscleGroup
import com.dexwritescode.workout.data.services.model.CompletedExerciseDetail
import com.dexwritescode.workout.data.services.model.WorkoutSessionDetail
import com.dexwritescode.workout.data.services.recovery.RecoveryEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

class RecoveryEngineTest {

    @Test
    fun `zero volume produces zero fatigue`() {
        assertEquals(0.0, RecoveryEngine.normalizeFatigue(0.0), 0.0)
    }

    @Test
    fun `moderate volume produces reasonable fatigue`() {
        val fatigue = RecoveryEngine.normalizeFatigue(4000.0) // 4×10×100 kg
        assertTrue(fatigue > 0.4)
        assertTrue(fatigue < 0.8)
    }

    @Test
    fun `very high volume saturates at fatigue scale ceiling`() {
        val fatigue = RecoveryEngine.normalizeFatigue(50000.0)
        assertTrue(fatigue <= 0.85)
        assertTrue(fatigue > 0.8)
    }

    @Test
    fun `fatigue decays to half after one half-life`() {
        val muscle = MuscleGroup.CHEST // 72h recovery → halfLife = 28.8h
        val halfLifeMs = (muscle.defaultRecoveryHours / 2.5 * 3_600_000).toLong()
        val nowMs = System.currentTimeMillis()

        val fatigue = RecoveryEngine.currentFatigue(
            storedFatigue = 0.8,
            lastUpdatedMs = nowMs,
            muscleGroup = muscle,
            nowMs = nowMs + halfLifeMs,
        )

        assertTrue(fatigue > 0.35)
        assertTrue(fatigue < 0.45)
    }

    @Test
    fun `full recovery returns zero after many days`() {
        val nowMs = System.currentTimeMillis()
        val tenDaysMs = nowMs + 10L * 24 * 3_600_000

        val fatigue = RecoveryEngine.currentFatigue(
            storedFatigue = 0.9,
            lastUpdatedMs = nowMs,
            muscleGroup = MuscleGroup.BICEPS,
            nowMs = tenDaysMs,
        )

        assertEquals(0.0, fatigue, 0.0)
    }

    @Test
    fun `no decay when zero time has elapsed`() {
        val nowMs = System.currentTimeMillis()

        val fatigue = RecoveryEngine.currentFatigue(
            storedFatigue = 0.7,
            lastUpdatedMs = nowMs,
            muscleGroup = MuscleGroup.CHEST,
            nowMs = nowMs,
        )

        assertEquals(0.7, fatigue, 0.001)
    }

    @Test
    fun `secondary muscles receive 50 percent of volume`() {
        val exercise = makeExercise(
            primary = listOf(MuscleGroup.CHEST),
            secondary = listOf(MuscleGroup.TRICEPS),
        )
        val detail = makeSessionDetail(
            exercise = exercise,
            sets = listOf(ExerciseSet(completedExerciseId = "ce", setNumber = 1, weight = 100.0, reps = 10, isCompleted = true)),
        )

        val deltas = RecoveryEngine.calculateFatigueDeltas(detail)

        val chestDelta = deltas[MuscleGroup.CHEST] ?: 0.0
        val tricepsDelta = deltas[MuscleGroup.TRICEPS] ?: 0.0
        assertTrue(chestDelta > tricepsDelta)
        assertTrue(abs(chestDelta - RecoveryEngine.normalizeFatigue(1000.0)) < 0.001)
        assertTrue(abs(tricepsDelta - RecoveryEngine.normalizeFatigue(500.0)) < 0.001)
    }

    @Test
    fun `incomplete sets are excluded from volume`() {
        val exercise = makeExercise(primary = listOf(MuscleGroup.CHEST))
        val detail = makeSessionDetail(
            exercise = exercise,
            sets = listOf(
                ExerciseSet(completedExerciseId = "ce", setNumber = 1, weight = 100.0, reps = 10, isCompleted = true),
                ExerciseSet(completedExerciseId = "ce", setNumber = 2, weight = 100.0, reps = 10, isCompleted = false),
            ),
        )

        val deltasAll = RecoveryEngine.calculateFatigueDeltas(
            makeSessionDetail(exercise, listOf(
                ExerciseSet(completedExerciseId = "ce", setNumber = 1, weight = 100.0, reps = 10, isCompleted = true),
                ExerciseSet(completedExerciseId = "ce", setNumber = 2, weight = 100.0, reps = 10, isCompleted = true),
            ))
        )
        val deltasOne = RecoveryEngine.calculateFatigueDeltas(detail)

        val chestAll = deltasAll[MuscleGroup.CHEST] ?: 0.0
        val chestOne = deltasOne[MuscleGroup.CHEST] ?: 0.0
        assertTrue(chestAll > chestOne)
    }

    @Test
    fun `estimate recovery is in the future for fatigued muscle`() {
        val nowMs = System.currentTimeMillis()
        val recoveryMs = RecoveryEngine.estimateFullRecoveryMs(0.8, MuscleGroup.CHEST, nowMs)
        assertTrue(recoveryMs > nowMs)
    }

    @Test
    fun `estimate recovery returns now when fatigue is zero`() {
        val nowMs = System.currentTimeMillis()
        val recoveryMs = RecoveryEngine.estimateFullRecoveryMs(0.0, MuscleGroup.CHEST, nowMs)
        assertEquals(nowMs, recoveryMs)
    }

    @Test
    fun `current recovery percentage is near 0_2 for 0_8 fatigue at creation time`() {
        val state = MuscleRecoveryState(
            muscleGroup = MuscleGroup.CHEST.rawValue,
            fatigueLevel = 0.8,
            lastUpdated = System.currentTimeMillis(),
        )
        val recovery = RecoveryEngine.currentRecoveryPercentage(state)
        assertTrue(recovery >= 0.19)
        assertTrue(recovery <= 0.25)
    }

    // --- helpers ---

    private fun makeExercise(
        primary: List<MuscleGroup>,
        secondary: List<MuscleGroup> = emptyList(),
    ) = Exercise(
        name = "Test",
        exerciseDescription = "Test",
        primaryMuscles = primary.map { it.rawValue },
        secondaryMuscles = secondary.map { it.rawValue },
        difficultyLevel = DifficultyLevel.INTERMEDIATE.rawValue,
    )

    private fun makeSessionDetail(exercise: Exercise, sets: List<ExerciseSet>): WorkoutSessionDetail {
        val ce = CompletedExercise(id = "ce", sessionId = "s1", exerciseId = exercise.id, order = 0)
        return WorkoutSessionDetail(
            session = WorkoutSession(id = "s1", templateId = null),
            completedExercises = listOf(CompletedExerciseDetail(ce, exercise, sets)),
        )
    }
}
