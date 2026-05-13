package com.dexwritescode.workout.data.services.model

import com.dexwritescode.workout.data.model.entity.CompletedExercise
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.ExerciseSet
import com.dexwritescode.workout.data.model.entity.WorkoutSession

data class CompletedExerciseDetail(
    val completedExercise: CompletedExercise,
    val exercise: Exercise?,
    val sets: List<ExerciseSet>,
)

data class WorkoutSessionDetail(
    val session: WorkoutSession,
    val completedExercises: List<CompletedExerciseDetail>,
)
