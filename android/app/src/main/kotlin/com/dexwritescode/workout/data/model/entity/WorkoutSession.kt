package com.dexwritescode.workout.data.model.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(
    tableName = "workout_sessions",
    foreignKeys = [
        ForeignKey(
            entity = WorkoutTemplate::class,
            parentColumns = ["id"],
            childColumns = ["templateId"],
            onDelete = ForeignKey.SET_NULL,
        ),
    ],
    indices = [Index("templateId")],
)
data class WorkoutSession(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val templateId: String?,
    val startTime: Long = System.currentTimeMillis(),
    val endTime: Long? = null,
    val notes: String? = null,
    val isCompleted: Boolean = false,
) {
    val durationMs: Long?
        get() = endTime?.minus(startTime)
}
