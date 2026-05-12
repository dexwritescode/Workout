package com.dexwritescode.workout.data.model.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "workout_templates")
data class WorkoutTemplate(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val templateDescription: String = "",
    val isPreBuilt: Boolean = false,
    val createdDate: Long = System.currentTimeMillis(),
    val lastUsedDate: Long? = null,
)
