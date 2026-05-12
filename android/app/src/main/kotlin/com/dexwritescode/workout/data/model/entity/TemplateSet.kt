package com.dexwritescode.workout.data.model.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(
    tableName = "template_sets",
    foreignKeys = [
        ForeignKey(
            entity = TemplateExercise::class,
            parentColumns = ["id"],
            childColumns = ["templateExerciseId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("templateExerciseId")],
)
data class TemplateSet(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val templateExerciseId: String?,
    val order: Int,
    val targetWeight: Double = 0.0,
    val targetReps: Int = 10,
)
