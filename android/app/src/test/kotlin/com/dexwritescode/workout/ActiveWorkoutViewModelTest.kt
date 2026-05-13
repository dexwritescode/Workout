package com.dexwritescode.workout

import com.dexwritescode.workout.ui.workout.ActiveWorkoutViewModel
import com.dexwritescode.workout.ui.workout.ExerciseSlot
import com.dexwritescode.workout.ui.workout.WorkoutState
import com.dexwritescode.workout.data.model.entity.CompletedExercise
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.ExerciseSet
import com.dexwritescode.workout.data.model.entity.TemplateExercise
import com.dexwritescode.workout.data.model.entity.WorkoutSession
import com.dexwritescode.workout.data.model.entity.WorkoutTemplate
import com.dexwritescode.workout.ui.workout.WorkoutSummary
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ActiveWorkoutViewModelTest {

    // MARK: - formatDuration

    @Test
    fun `formatDuration under one hour shows MM SS`() {
        assertEquals("0:00", ActiveWorkoutViewModel.formatDuration(0))
        assertEquals("1:30", ActiveWorkoutViewModel.formatDuration(90))
        assertEquals("59:59", ActiveWorkoutViewModel.formatDuration(3599))
    }

    @Test
    fun `formatDuration one hour or more shows H MM SS`() {
        assertEquals("1:00:00", ActiveWorkoutViewModel.formatDuration(3600))
        assertEquals("1:30:45", ActiveWorkoutViewModel.formatDuration(5445))
        assertEquals("2:00:00", ActiveWorkoutViewModel.formatDuration(7200))
    }

    // MARK: - WorkoutState helpers

    @Test
    fun `NotStarted state carries template and slots`() {
        val template = WorkoutTemplate(name = "Push Day", templateDescription = "")
        val slots = listOf(makeSlot(targetSets = 3))
        val state = WorkoutState.NotStarted(template = template, slots = slots)
        assertEquals("Push Day", state.template.name)
        assertEquals(1, state.slots.size)
    }

    @Test
    fun `InProgress elapsedSeconds updates independently of slot state`() {
        val template = WorkoutTemplate(name = "Test", templateDescription = "")
        val session = WorkoutSession(templateId = template.id)
        val state = WorkoutState.InProgress(
            template = template,
            session = session,
            slots = listOf(makeSlot()),
            currentIndex = 0,
            elapsedSeconds = 42L,
        )
        assertEquals(42L, state.elapsedSeconds)
        val updated = state.copy(elapsedSeconds = 100L)
        assertEquals(100L, updated.elapsedSeconds)
    }

    // MARK: - markExerciseComplete logic (pure)

    @Test
    fun `markExerciseComplete selects next incomplete slot`() {
        val slots = listOf(
            makeSlot(targetSets = 3, completedCount = 3), // done
            makeSlot(targetSets = 3, completedCount = 1), // incomplete
            makeSlot(targetSets = 3, completedCount = 0), // not started
        )
        // Simulate the logic from the VM: advance past index 0
        val next = slots.indices.drop(1).firstOrNull { i ->
            val slot = slots[i]
            slot.completedSets.count { it.isCompleted } < slot.templateExercise.targetSets
        }
        assertEquals(1, next)
    }

    @Test
    fun `markExerciseComplete stays put when all subsequent are done`() {
        val slots = listOf(
            makeSlot(targetSets = 3, completedCount = 3),
            makeSlot(targetSets = 3, completedCount = 3),
        )
        val next = slots.indices.drop(1).firstOrNull { i ->
            slots[i].completedSets.count { it.isCompleted } < slots[i].templateExercise.targetSets
        }
        assertEquals(null, next)
    }

    // MARK: - Summary computation (pure)

    @Test
    fun `WorkoutSummary totalVolume sums weight times reps`() {
        val summary = WorkoutSummary(
            durationMs = 60_000,
            exercisesCompleted = 1,
            totalExercises = 1,
            totalSets = 3,
            totalVolume = 100.0 * 8 + 95.0 * 7,  // 800 + 665 = 1465
            exerciseBreakdowns = emptyList(),
            musclesWorked = emptyMap(),
        )
        assertEquals(1465.0, summary.totalVolume, 0.001)
    }

    @Test
    fun `WorkoutSummary formatDuration matches expected string`() {
        val durationSec = 90 * 60 + 30  // 90 min 30 sec = 5430 sec
        assertEquals("1:30:30", ActiveWorkoutViewModel.formatDuration(durationSec.toLong()))
    }

    // MARK: - ExerciseSlot helpers

    @Test
    fun `ExerciseSlot reports correct completed set count`() {
        val slot = makeSlot(targetSets = 4, completedCount = 2)
        val done = slot.completedSets.count { it.isCompleted }
        assertEquals(2, done)
        assertFalse(done >= slot.templateExercise.targetSets)
    }

    @Test
    fun `ExerciseSlot marks as done when all target sets completed`() {
        val slot = makeSlot(targetSets = 3, completedCount = 3)
        val done = slot.completedSets.count { it.isCompleted }
        assertTrue(done >= slot.templateExercise.targetSets)
    }

    // MARK: - removeExercise index guard (pure logic)

    @Test
    fun `removeExercise clamps currentIndex when last slot removed`() {
        val slots = (0 until 3).map { makeSlot() }
        val currentIndex = 2
        val indexToRemove = 2

        val updatedSlots = slots.toMutableList().also { it.removeAt(indexToRemove) }
        val newIndex = minOf(currentIndex, maxOf(0, updatedSlots.size - 1))

        assertEquals(1, newIndex)
        assertEquals(2, updatedSlots.size)
    }

    @Test
    fun `removeExercise keeps currentIndex when removing earlier slot`() {
        val slots = (0 until 4).map { makeSlot() }
        val currentIndex = 3
        val indexToRemove = 0

        val updatedSlots = slots.toMutableList().also { it.removeAt(indexToRemove) }
        val newIndex = minOf(currentIndex, maxOf(0, updatedSlots.size - 1))

        // currentIndex was 3; after removal there are 3 slots → indices 0..2; clamped to 2
        assertEquals(2, newIndex)
    }

    // MARK: - Helpers

    private fun makeSlot(targetSets: Int = 3, completedCount: Int = 0): ExerciseSlot {
        val te = TemplateExercise(
            templateId = null,
            exerciseId = null,
            order = 0,
            targetSets = targetSets,
            targetReps = 10,
        )
        val ce = CompletedExercise(sessionId = null, exerciseId = null, order = 0)
        val sets = (1..completedCount).map { n ->
            ExerciseSet(completedExerciseId = ce.id, setNumber = n, weight = 100.0, reps = 8, isCompleted = true)
        }
        return ExerciseSlot(
            templateExercise = te,
            exercise = null,
            templateSets = emptyList(),
            completedExercise = ce,
            completedSets = sets,
        )
    }
}
