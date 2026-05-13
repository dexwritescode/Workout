package com.dexwritescode.workout.data.services.recovery

import com.dexwritescode.workout.data.db.dao.MuscleRecoveryStateDao
import com.dexwritescode.workout.data.model.entity.MuscleRecoveryState
import com.dexwritescode.workout.data.model.enums.MuscleGroup
import com.dexwritescode.workout.data.services.model.WorkoutSessionDetail
import kotlin.math.ln
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.tanh

object RecoveryEngine {

    private const val REFERENCE_VOLUME = 5000.0
    private const val FATIGUE_SCALE = 0.85
    private const val SECONDARY_FACTOR = 0.5

    fun calculateFatigueDeltas(session: WorkoutSessionDetail): Map<MuscleGroup, Double> {
        val muscleVolume = mutableMapOf<MuscleGroup, Double>()
        for (detail in session.completedExercises) {
            val exercise = detail.exercise ?: continue
            val completedSets = detail.sets.filter { it.isCompleted }
            if (completedSets.isEmpty()) continue
            val volume = completedSets.sumOf { it.weight * it.reps }
            exercise.primaryMuscleGroups.forEach { muscle ->
                muscleVolume[muscle] = (muscleVolume[muscle] ?: 0.0) + volume
            }
            exercise.secondaryMuscleGroups.forEach { muscle ->
                muscleVolume[muscle] = (muscleVolume[muscle] ?: 0.0) + volume * SECONDARY_FACTOR
            }
        }
        return muscleVolume.mapValues { normalizeFatigue(it.value) }
    }

    fun normalizeFatigue(volume: Double): Double {
        if (volume <= 0) return 0.0
        return min(1.0, tanh(volume / REFERENCE_VOLUME) * FATIGUE_SCALE)
    }

    fun currentFatigue(
        storedFatigue: Double,
        lastUpdatedMs: Long,
        muscleGroup: MuscleGroup,
        nowMs: Long = System.currentTimeMillis(),
    ): Double {
        val hoursElapsed = (nowMs - lastUpdatedMs) / 3_600_000.0
        if (hoursElapsed <= 0 || storedFatigue <= 0) return storedFatigue
        val halfLife = muscleGroup.defaultRecoveryHours / 2.5
        val fatigue = storedFatigue * 0.5.pow(hoursElapsed / halfLife)
        return if (fatigue < 0.01) 0.0 else fatigue
    }

    fun currentRecoveryPercentage(
        state: MuscleRecoveryState,
        nowMs: Long = System.currentTimeMillis(),
    ): Double {
        val muscle = state.muscle ?: return 1.0
        return 1.0 - currentFatigue(state.fatigueLevel, state.lastUpdated, muscle, nowMs)
    }

    fun estimateFullRecoveryMs(
        fatigue: Double,
        muscleGroup: MuscleGroup,
        fromMs: Long = System.currentTimeMillis(),
    ): Long {
        if (fatigue <= 0.05) return fromMs
        val halfLife = muscleGroup.defaultRecoveryHours / 2.5
        val hoursToRecover = halfLife * ln(fatigue / 0.05) / ln(2.0)
        return fromMs + (hoursToRecover * 3_600_000).toLong()
    }

    suspend fun updateRecoveryStates(session: WorkoutSessionDetail, dao: MuscleRecoveryStateDao) {
        val fatigueDeltas = calculateFatigueDeltas(session)
        if (fatigueDeltas.isEmpty()) return
        val nowMs = System.currentTimeMillis()
        for ((muscle, fatigueDelta) in fatigueDeltas) {
            val existing = dao.getByMuscleGroup(muscle.rawValue)
            val decayed = if (existing != null) {
                currentFatigue(existing.fatigueLevel, existing.lastUpdated, muscle, nowMs)
            } else {
                0.0
            }
            val newFatigue = min(1.0, decayed + fatigueDelta)
            val updated = (existing ?: MuscleRecoveryState(muscleGroup = muscle.rawValue)).copy(
                fatigueLevel = newFatigue,
                lastWorkedDate = nowMs,
                lastUpdated = nowMs,
                estimatedFullRecoveryDate = estimateFullRecoveryMs(newFatigue, muscle, nowMs),
            )
            dao.insert(updated)
        }
    }
}
