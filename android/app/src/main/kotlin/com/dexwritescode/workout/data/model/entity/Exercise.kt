package com.dexwritescode.workout.data.model.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.dexwritescode.workout.data.model.enums.DifficultyLevel
import com.dexwritescode.workout.data.model.enums.MuscleGroup
import java.util.UUID

@Entity(tableName = "exercises")
data class Exercise(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val exerciseDescription: String,
    val instructions: List<String> = emptyList(),
    val equipment: List<String> = emptyList(),
    val primaryMuscles: List<String> = emptyList(),
    val secondaryMuscles: List<String> = emptyList(),
    val difficultyLevel: String = DifficultyLevel.INTERMEDIATE.rawValue,
    val mediaFileName: String? = null,
    val isCustom: Boolean = false,
    val createdDate: Long = System.currentTimeMillis(),
) {
    val primaryMuscleGroups: List<MuscleGroup>
        get() = primaryMuscles.mapNotNull { MuscleGroup.fromRawValue(it) }

    val secondaryMuscleGroups: List<MuscleGroup>
        get() = secondaryMuscles.mapNotNull { MuscleGroup.fromRawValue(it) }

    val difficulty: DifficultyLevel
        get() = DifficultyLevel.fromRawValue(difficultyLevel) ?: DifficultyLevel.INTERMEDIATE
}
