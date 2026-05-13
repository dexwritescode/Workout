package com.dexwritescode.workout.data.services.workout

import com.dexwritescode.workout.data.db.dao.TemplateExerciseDao
import com.dexwritescode.workout.data.db.dao.WorkoutTemplateDao
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.MuscleRecoveryState
import com.dexwritescode.workout.data.model.entity.TemplateExercise
import com.dexwritescode.workout.data.model.entity.WorkoutTemplate
import com.dexwritescode.workout.data.model.enums.MuscleCategory
import com.dexwritescode.workout.data.model.enums.MuscleGroup
import com.dexwritescode.workout.data.model.enums.SplitType
import com.dexwritescode.workout.data.services.model.WorkoutSessionDetail
import com.dexwritescode.workout.data.services.recovery.RecoveryEngine
import java.util.UUID

object WorkoutEngine {

    data class SuggestedExercise(
        val id: String = UUID.randomUUID().toString(),
        val exercise: Exercise,
        val targetSets: Int,
        val targetReps: Int,
        val suggestedWeight: Double,
        val reason: String,
    )

    data class GeneratedWorkout(
        val name: String,
        val exercises: List<SuggestedExercise>,
        val targetMuscles: List<MuscleGroup>,
        val estimatedDurationMinutes: Int,
    )

    fun generateWorkout(
        splitType: SplitType,
        recoveryStates: List<MuscleRecoveryState>,
        allExercises: List<Exercise>,
        recentSessions: List<WorkoutSessionDetail>,
    ): GeneratedWorkout {
        val targetMuscles = selectTargetMuscles(splitType, recoveryStates, recentSessions)
        val exercises = selectExercises(targetMuscles, allExercises, recentSessions)
        val name = workoutName(targetMuscles, splitType)
        val estimatedMinutes = exercises.sumOf { it.targetSets * 2 } + exercises.size * 2
        return GeneratedWorkout(
            name = name,
            exercises = exercises,
            targetMuscles = targetMuscles,
            estimatedDurationMinutes = maxOf(20, estimatedMinutes),
        )
    }

    private fun selectTargetMuscles(
        splitType: SplitType,
        recoveryStates: List<MuscleRecoveryState>,
        recentSessions: List<WorkoutSessionDetail>,
    ): List<MuscleGroup> {
        val recoveryMap = recoveryStates.mapNotNull { state ->
            state.muscle?.let { it to RecoveryEngine.currentRecoveryPercentage(state) }
        }.toMap()

        if (splitType == SplitType.FULL_BODY) {
            return MuscleGroup.entries
                .filter { (recoveryMap[it] ?: 1.0) >= 0.70 }
                .sortedByDescending { recoveryMap[it] ?: 1.0 }
                .take(6)
        }

        val muscleGroups: List<List<MuscleGroup>> = when (splitType) {
            SplitType.PUSH_PULL_LEGS -> listOf(
                listOf(MuscleGroup.CHEST, MuscleGroup.SHOULDERS, MuscleGroup.TRICEPS),
                listOf(MuscleGroup.LATS, MuscleGroup.TRAPS, MuscleGroup.BICEPS, MuscleGroup.FOREARMS),
                listOf(MuscleGroup.QUADRICEPS, MuscleGroup.HAMSTRINGS, MuscleGroup.GLUTES, MuscleGroup.CALVES),
            )
            SplitType.UPPER_LOWER -> listOf(
                listOf(MuscleGroup.CHEST, MuscleGroup.SHOULDERS, MuscleGroup.BICEPS, MuscleGroup.TRICEPS, MuscleGroup.LATS, MuscleGroup.TRAPS, MuscleGroup.FOREARMS),
                listOf(MuscleGroup.QUADRICEPS, MuscleGroup.HAMSTRINGS, MuscleGroup.GLUTES, MuscleGroup.CALVES),
            )
            SplitType.BODYPART_SPLIT -> listOf(
                listOf(MuscleGroup.CHEST, MuscleGroup.TRICEPS),
                listOf(MuscleGroup.LATS, MuscleGroup.BICEPS, MuscleGroup.FOREARMS),
                listOf(MuscleGroup.SHOULDERS, MuscleGroup.TRAPS),
                listOf(MuscleGroup.QUADRICEPS, MuscleGroup.HAMSTRINGS, MuscleGroup.GLUTES, MuscleGroup.CALVES),
            )
            else -> emptyList()
        }

        return muscleGroups
            .maxByOrNull { group -> group.sumOf { recoveryMap[it] ?: 1.0 } / group.size }
            ?: muscleGroups.firstOrNull()
            ?: emptyList()
    }

    private fun selectExercises(
        targetMuscles: List<MuscleGroup>,
        allExercises: List<Exercise>,
        recentSessions: List<WorkoutSessionDetail>,
    ): List<SuggestedExercise> {
        val cutoffMs = System.currentTimeMillis() - 3 * 24 * 3_600_000L
        val recentExerciseIds = recentSessions
            .filter { it.session.startTime > cutoffMs }
            .flatMap { it.completedExercises }
            .mapNotNull { it.exercise?.id }
            .toSet()

        val candidates = allExercises.filter { exercise ->
            exercise.primaryMuscleGroups.any { it in targetMuscles }
        }

        val scored = candidates.map { exercise ->
            var score = 0.0
            if (exercise.primaryMuscleGroups.size > 1 || exercise.secondaryMuscleGroups.isNotEmpty()) score += 2.0
            if (exercise.id !in recentExerciseIds) score += 1.5
            when (exercise.difficulty) {
                com.dexwritescode.workout.data.model.enums.DifficultyLevel.BEGINNER -> score += 0.3
                com.dexwritescode.workout.data.model.enums.DifficultyLevel.INTERMEDIATE -> score += 0.5
                else -> Unit
            }
            exercise to score
        }.sortedByDescending { it.second }

        val selected = mutableListOf<Exercise>()
        val coveredMuscles = mutableSetOf<MuscleGroup>()

        for (muscle in targetMuscles) {
            if (muscle in coveredMuscles) continue
            val best = scored.firstOrNull { (ex, _) ->
                muscle in ex.primaryMuscleGroups && selected.none { it.id == ex.id }
            }?.first ?: continue
            selected.add(best)
            coveredMuscles.addAll(best.primaryMuscleGroups)
        }

        for ((exercise, _) in scored) {
            if (selected.size >= 5) break
            if (selected.none { it.id == exercise.id }) selected.add(exercise)
        }

        return selected.mapIndexed { index, exercise ->
            val isCompound = exercise.primaryMuscleGroups.size > 1 || exercise.secondaryMuscleGroups.isNotEmpty()
            val (sets, reps) = if (isCompound) {
                if (index < 2) 4 to 8 else 3 to 10
            } else {
                3 to 12
            }
            val primaryNames = exercise.primaryMuscleGroups.joinToString(", ") { it.rawValue }
            SuggestedExercise(
                exercise = exercise,
                targetSets = sets,
                targetReps = reps,
                suggestedWeight = mostRecentMaxWeight(exercise, recentSessions),
                reason = "$primaryNames — ${if (isCompound) "compound" else "isolation"}",
            )
        }
    }

    private fun workoutName(muscles: List<MuscleGroup>, splitType: SplitType): String = when (splitType) {
        SplitType.PUSH_PULL_LEGS -> when {
            MuscleGroup.CHEST in muscles -> "Push Day"
            MuscleGroup.LATS in muscles -> "Pull Day"
            MuscleGroup.QUADRICEPS in muscles -> "Leg Day"
            else -> "Workout"
        }
        SplitType.UPPER_LOWER -> when {
            muscles.any { it.category == MuscleCategory.LOWER_BODY } &&
                muscles.none { it.category == MuscleCategory.UPPER_BODY } -> "Lower Body"
            else -> "Upper Body"
        }
        SplitType.FULL_BODY -> "Full Body"
        SplitType.BODYPART_SPLIT -> muscles.take(2).map { it.rawValue }.toSet().joinToString(" & ")
    }

    private fun mostRecentMaxWeight(exercise: Exercise, sessions: List<WorkoutSessionDetail>): Double {
        for (sessionDetail in sessions) {
            val sets = sessionDetail.completedExercises
                .filter { it.exercise?.id == exercise.id }
                .flatMap { it.sets.filter { s -> s.isCompleted } }
            if (sets.isNotEmpty()) return sets.maxOf { it.weight }
        }
        return 0.0
    }

    suspend fun createTemplate(
        workout: GeneratedWorkout,
        templateDao: WorkoutTemplateDao,
        templateExerciseDao: TemplateExerciseDao,
    ): WorkoutTemplate {
        val template = WorkoutTemplate(name = workout.name, templateDescription = "Smart workout")
        templateDao.insert(template)
        workout.exercises.forEachIndexed { index, suggestion ->
            templateExerciseDao.insert(
                TemplateExercise(
                    templateId = template.id,
                    exerciseId = suggestion.exercise.id,
                    order = index,
                    targetSets = suggestion.targetSets,
                    targetReps = suggestion.targetReps,
                    targetWeight = suggestion.suggestedWeight,
                )
            )
        }
        return template
    }
}
