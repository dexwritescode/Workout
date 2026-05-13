package com.dexwritescode.workout.data.services.export

import com.dexwritescode.workout.data.db.dao.CompletedExerciseDao
import com.dexwritescode.workout.data.db.dao.ExerciseDao
import com.dexwritescode.workout.data.db.dao.ExerciseSetDao
import com.dexwritescode.workout.data.db.dao.UserSettingsDao
import com.dexwritescode.workout.data.db.dao.WorkoutSessionDao
import com.dexwritescode.workout.data.model.entity.CompletedExercise
import com.dexwritescode.workout.data.model.entity.ExerciseSet
import com.dexwritescode.workout.data.model.entity.WorkoutSession
import kotlinx.serialization.json.Json
import java.time.Instant

object ImportService {

    sealed class ImportError : Exception() {
        object InvalidData : ImportError()
        data class UnsupportedVersion(val version: Int) : ImportError()
        data class DecodingFailed(val reason: String) : ImportError()
    }

    data class ImportResult(val sessionsImported: Int, val settingsImported: Boolean)

    private val json = Json { ignoreUnknownKeys = true }

    suspend fun importData(
        data: ByteArray,
        sessionDao: WorkoutSessionDao,
        completedExerciseDao: CompletedExerciseDao,
        exerciseSetDao: ExerciseSetDao,
        exerciseDao: ExerciseDao,
        userSettingsDao: UserSettingsDao,
    ): ImportResult {
        val exportData = try {
            json.decodeFromString<ExportData>(data.toString(Charsets.UTF_8))
        } catch (e: Exception) {
            throw ImportError.DecodingFailed(e.message ?: "unknown")
        }

        if (exportData.version != 1) throw ImportError.UnsupportedVersion(exportData.version)

        val existingIds = sessionDao.getAllOnce().map { it.id }.toSet()
        val exerciseLookup = exerciseDao.getAllOnce().associateBy { it.name }

        var importedCount = 0

        for (sessionExport in exportData.sessions) {
            if (sessionExport.id in existingIds) continue

            val session = WorkoutSession(
                id = sessionExport.id,
                templateId = null,
                startTime = sessionExport.startTime.fromIso8601(),
                endTime = sessionExport.endTime?.fromIso8601(),
                notes = sessionExport.notes,
                isCompleted = true,
            )
            sessionDao.insert(session)

            for (exerciseExport in sessionExport.exercises) {
                val ce = CompletedExercise(
                    sessionId = session.id,
                    exerciseId = exerciseLookup[exerciseExport.name]?.id,
                    order = exerciseExport.order,
                )
                completedExerciseDao.insert(ce)

                for (setExport in exerciseExport.sets) {
                    exerciseSetDao.insert(
                        ExerciseSet(
                            completedExerciseId = ce.id,
                            setNumber = setExport.setNumber,
                            weight = setExport.weight,
                            reps = setExport.reps,
                            isCompleted = true,
                            completedAt = setExport.completedAt?.fromIso8601(),
                            rpe = setExport.rpe,
                        )
                    )
                }
            }
            importedCount++
        }

        var settingsImported = false
        val settingsExport = exportData.settings
        if (settingsExport != null) {
            val existing = userSettingsDao.getOnce()
            if (existing != null) {
                userSettingsDao.update(
                    existing.copy(
                        weightUnit = settingsExport.weightUnit,
                        defaultRestTime = settingsExport.defaultRestTime,
                        preferredSplitType = settingsExport.preferredSplitType,
                    )
                )
                settingsImported = true
            }
        }

        return ImportResult(sessionsImported = importedCount, settingsImported = settingsImported)
    }

    private fun String.fromIso8601(): Long = Instant.parse(this).toEpochMilli()
}
