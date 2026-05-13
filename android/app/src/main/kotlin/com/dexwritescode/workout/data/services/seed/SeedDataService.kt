package com.dexwritescode.workout.data.services.seed

import android.content.Context
import com.dexwritescode.workout.data.db.dao.ExerciseDao
import com.dexwritescode.workout.data.db.dao.MuscleRecoveryStateDao
import com.dexwritescode.workout.data.db.dao.TemplateExerciseDao
import com.dexwritescode.workout.data.db.dao.UserSettingsDao
import com.dexwritescode.workout.data.db.dao.WorkoutTemplateDao
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.MuscleRecoveryState
import com.dexwritescode.workout.data.model.entity.TemplateExercise
import com.dexwritescode.workout.data.model.entity.UserSettings
import com.dexwritescode.workout.data.model.entity.WorkoutTemplate
import com.dexwritescode.workout.data.model.enums.DifficultyLevel
import com.dexwritescode.workout.data.model.enums.MuscleGroup
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

object SeedDataService {

    @Serializable
    private data class ExerciseJson(
        val id: String,
        val name: String,
        val description: String,
        val instructions: List<String> = emptyList(),
        val equipment: List<String> = emptyList(),
        val primaryMuscles: List<String> = emptyList(),
        val secondaryMuscles: List<String> = emptyList(),
        val difficultyLevel: String,
        val mediaFileName: String? = null,
    )

    @Serializable
    private data class ExerciseFile(val exercises: List<ExerciseJson>)

    private val json = Json { ignoreUnknownKeys = true }

    suspend fun seedIfNeeded(
        context: Context,
        exerciseDao: ExerciseDao,
        userSettingsDao: UserSettingsDao,
        workoutTemplateDao: WorkoutTemplateDao,
        templateExerciseDao: TemplateExerciseDao,
        muscleRecoveryStateDao: MuscleRecoveryStateDao,
    ) {
        seedExercises(context, exerciseDao)
        seedDefaultSettings(userSettingsDao)
        seedSampleTemplates(workoutTemplateDao, templateExerciseDao, exerciseDao)
        seedRecoveryStates(muscleRecoveryStateDao)
    }

    private suspend fun seedExercises(context: Context, dao: ExerciseDao) {
        if (dao.count() > 0) return
        val exercises = loadExercisesFromAssets(context)
        dao.insertAll(exercises)
    }

    private suspend fun seedDefaultSettings(dao: UserSettingsDao) {
        if (dao.getOnce() != null) return
        dao.insert(UserSettings())
    }

    private suspend fun seedSampleTemplates(
        templateDao: WorkoutTemplateDao,
        templateExerciseDao: TemplateExerciseDao,
        exerciseDao: ExerciseDao,
    ) {
        if (templateDao.count() > 0) return
        val template = WorkoutTemplate(
            name = "Push Day A",
            templateDescription = "Chest, shoulders, and triceps",
            isPreBuilt = true,
        )
        templateDao.insert(template)
        val exerciseNames = listOf(
            "Barbell Bench Press",
            "Incline Dumbbell Press",
            "Cable Flyes",
            "Barbell Overhead Press",
            "Dumbbell Lateral Raise",
            "Cable Tricep Pushdown",
        )
        exerciseNames.forEachIndexed { index, name ->
            val exercise = exerciseDao.getByName(name)
            templateExerciseDao.insert(
                TemplateExercise(
                    templateId = template.id,
                    exerciseId = exercise?.id,
                    order = index,
                    targetSets = if (index < 2) 4 else 3,
                    targetReps = if (index < 2) 8 else 12,
                )
            )
        }
    }

    private suspend fun seedRecoveryStates(dao: MuscleRecoveryStateDao) {
        if (dao.count() > 0) return
        dao.insertAll(MuscleGroup.entries.map { MuscleRecoveryState(muscleGroup = it.rawValue) })
    }

    private fun loadExercisesFromAssets(context: Context): List<Exercise> {
        val raw = context.assets.open("exercises.json").bufferedReader().readText()
        val file = json.decodeFromString<ExerciseFile>(raw)
        return file.exercises.mapNotNull { j ->
            val primaryMuscles = j.primaryMuscles.filter { MuscleGroup.fromRawValue(it) != null }
            if (primaryMuscles.isEmpty()) return@mapNotNull null
            val difficultyRaw = DifficultyLevel.fromRawValue(j.difficultyLevel)?.rawValue
                ?: DifficultyLevel.INTERMEDIATE.rawValue
            Exercise(
                id = j.id,
                name = j.name,
                exerciseDescription = j.description,
                instructions = j.instructions,
                equipment = j.equipment,
                primaryMuscles = primaryMuscles,
                secondaryMuscles = j.secondaryMuscles.filter { MuscleGroup.fromRawValue(it) != null },
                difficultyLevel = difficultyRaw,
                mediaFileName = j.mediaFileName,
                isCustom = false,
            )
        }
    }
}
