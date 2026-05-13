package com.dexwritescode.workout.data.services.export

import com.dexwritescode.workout.data.db.dao.CompletedExerciseDao
import com.dexwritescode.workout.data.db.dao.ExerciseDao
import com.dexwritescode.workout.data.db.dao.ExerciseSetDao
import com.dexwritescode.workout.data.db.dao.UserSettingsDao
import com.dexwritescode.workout.data.db.dao.WorkoutSessionDao
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import java.time.Instant
import java.time.LocalDate

object ExportService {

    private val json = Json { prettyPrint = true; encodeDefaults = true }

    suspend fun exportAll(
        sessionDao: WorkoutSessionDao,
        completedExerciseDao: CompletedExerciseDao,
        exerciseSetDao: ExerciseSetDao,
        exerciseDao: ExerciseDao,
        userSettingsDao: UserSettingsDao,
    ): ByteArray {
        val sessions = sessionDao.getAllCompleted()

        val sessionExports = sessions.map { session ->
            val completedExercises = completedExerciseDao.getBySessionOnce(session.id)
                .sortedBy { it.order }
            val exerciseExports = completedExercises.map { ce ->
                val exerciseName = ce.exerciseId?.let { exerciseDao.getById(it)?.name } ?: "Unknown"
                val sets = exerciseSetDao.getByCompletedExerciseOnce(ce.id)
                    .filter { it.isCompleted }
                    .sortedBy { it.setNumber }
                    .map { s ->
                        SetExport(
                            setNumber = s.setNumber,
                            weight = s.weight,
                            reps = s.reps,
                            rpe = s.rpe,
                            completedAt = s.completedAt?.toIso8601(),
                        )
                    }
                ExerciseExport(name = exerciseName, order = ce.order, sets = sets)
            }
            SessionExport(
                id = session.id,
                templateName = null,
                startTime = session.startTime.toIso8601(),
                endTime = session.endTime?.toIso8601(),
                notes = session.notes,
                exercises = exerciseExports,
            )
        }

        val settings = userSettingsDao.getOnce()?.let { s ->
            SettingsExport(
                weightUnit = s.weightUnit,
                defaultRestTime = s.defaultRestTime,
                preferredSplitType = s.preferredSplitType,
            )
        }

        val exportData = ExportData(
            exportDate = System.currentTimeMillis().toIso8601(),
            sessions = sessionExports,
            settings = settings,
        )

        return json.encodeToString(exportData).toByteArray(Charsets.UTF_8)
    }

    suspend fun exportToFile(
        cacheDir: File,
        sessionDao: WorkoutSessionDao,
        completedExerciseDao: CompletedExerciseDao,
        exerciseSetDao: ExerciseSetDao,
        exerciseDao: ExerciseDao,
        userSettingsDao: UserSettingsDao,
    ): File {
        val data = exportAll(sessionDao, completedExerciseDao, exerciseSetDao, exerciseDao, userSettingsDao)
        val date = LocalDate.now()
        val file = File(cacheDir, "workout-export-$date.json")
        file.writeBytes(data)
        return file
    }

    private fun Long.toIso8601(): String = Instant.ofEpochMilli(this).toString()
}
