package com.dexwritescode.workout.data.services.export

import kotlinx.serialization.Serializable

// Dates are stored as ISO 8601 strings (e.g. "2025-12-30T10:30:00Z") for
// cross-platform compatibility with the iOS export format.

@Serializable
data class ExportData(
    val exportDate: String,
    val version: Int = 1,
    val sessions: List<SessionExport>,
    val settings: SettingsExport? = null,
)

@Serializable
data class SessionExport(
    val id: String,
    val templateName: String? = null,
    val startTime: String,
    val endTime: String? = null,
    val notes: String? = null,
    val exercises: List<ExerciseExport>,
)

@Serializable
data class ExerciseExport(
    val name: String,
    val order: Int,
    val sets: List<SetExport>,
)

@Serializable
data class SetExport(
    val setNumber: Int,
    val weight: Double,
    val reps: Int,
    val rpe: Int? = null,
    val completedAt: String? = null,
)

@Serializable
data class SettingsExport(
    val weightUnit: String,
    val defaultRestTime: Int,
    val preferredSplitType: String? = null,
)
