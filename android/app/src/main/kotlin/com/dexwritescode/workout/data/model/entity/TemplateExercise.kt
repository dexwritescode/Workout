package com.dexwritescode.workout.data.model.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(
    tableName = "template_exercises",
    foreignKeys = [
        ForeignKey(
            entity = WorkoutTemplate::class,
            parentColumns = ["id"],
            childColumns = ["templateId"],
            onDelete = ForeignKey.CASCADE,
        ),
        ForeignKey(
            entity = Exercise::class,
            parentColumns = ["id"],
            childColumns = ["exerciseId"],
            onDelete = ForeignKey.SET_NULL,
        ),
    ],
    indices = [Index("templateId"), Index("exerciseId")],
)
data class TemplateExercise(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val templateId: String?,
    val exerciseId: String?,
    val order: Int,
    val targetSets: Int,
    val targetReps: Int,
    val targetWeight: Double = 0.0,
    val restSeconds: Int = 90,
    val notes: String? = null,
)
