package com.dexwritescode.workout.data.model.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(
    tableName = "exercise_sets",
    foreignKeys = [
        ForeignKey(
            entity = CompletedExercise::class,
            parentColumns = ["id"],
            childColumns = ["completedExerciseId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("completedExerciseId")],
)
data class ExerciseSet(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val completedExerciseId: String?,
    val setNumber: Int,
    val weight: Double = 0.0,
    val reps: Int = 0,
    val isCompleted: Boolean = false,
    val completedAt: Long? = null,
    val rpe: Int? = null,
)
