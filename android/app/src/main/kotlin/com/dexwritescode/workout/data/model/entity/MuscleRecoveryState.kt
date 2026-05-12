package com.dexwritescode.workout.data.model.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.dexwritescode.workout.data.model.enums.MuscleGroup

@Entity(tableName = "muscle_recovery_states")
data class MuscleRecoveryState(
    @PrimaryKey val muscleGroup: String,
    val fatigueLevel: Double = 0.0,
    val lastWorkedDate: Long = System.currentTimeMillis(),
    val estimatedFullRecoveryDate: Long = System.currentTimeMillis(),
    val lastUpdated: Long = System.currentTimeMillis(),
    val workloadHistory: ByteArray? = null,
) {
    val muscle: MuscleGroup?
        get() = MuscleGroup.fromRawValue(muscleGroup)

    val recoveryPercentage: Double
        get() = 1.0 - fatigueLevel

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is MuscleRecoveryState) return false
        return muscleGroup == other.muscleGroup &&
            fatigueLevel == other.fatigueLevel &&
            lastWorkedDate == other.lastWorkedDate &&
            estimatedFullRecoveryDate == other.estimatedFullRecoveryDate &&
            lastUpdated == other.lastUpdated &&
            workloadHistory.contentEquals(other.workloadHistory)
    }

    override fun hashCode(): Int {
        var result = muscleGroup.hashCode()
        result = 31 * result + fatigueLevel.hashCode()
        result = 31 * result + lastWorkedDate.hashCode()
        result = 31 * result + estimatedFullRecoveryDate.hashCode()
        result = 31 * result + lastUpdated.hashCode()
        result = 31 * result + (workloadHistory?.contentHashCode() ?: 0)
        return result
    }
}
