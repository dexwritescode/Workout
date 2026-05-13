package com.dexwritescode.workout.ui.workout

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.dexwritescode.workout.data.db.AppDatabase
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.TemplateExercise
import com.dexwritescode.workout.data.model.entity.TemplateSet
import com.dexwritescode.workout.data.model.entity.WorkoutTemplate
import com.dexwritescode.workout.data.services.model.WorkoutSessionDetail
import com.dexwritescode.workout.data.services.workout.WorkoutEngine
import kotlinx.coroutines.launch

private const val ROUTE_PICKER = "templatePicker"
private const val ROUTE_SMART = "smartWorkout"
private const val ROUTE_EDITOR = "templateEditor?templateId={templateId}"
private const val ROUTE_ACTIVE = "activeWorkout/{templateId}"
private const val ROUTE_TRACKING = "exerciseTracking/{templateId}/{slotIndex}"
private const val ROUTE_SUMMARY = "workoutSummary/{templateId}"

@Composable
fun WorkoutNavGraph(navController: NavHostController, context: Context) {
    val db = remember { AppDatabase.getInstance(context) }

    NavHost(navController = navController, startDestination = ROUTE_PICKER) {

        // ── Template Picker ──────────────────────────────────────────────────
        composable(ROUTE_PICKER) {
            val scope = rememberCoroutineScope()
            TemplatePickerScreen(
                templatesFlow = db.workoutTemplateDao().getAll(),
                onSmartWorkout = { navController.navigate("smartWorkout") },
                onTemplateSelected = { template ->
                    navController.navigate("activeWorkout/${template.id}")
                },
                onCreateTemplate = { navController.navigate("templateEditor") },
                onEditTemplate = { template ->
                    navController.navigate("templateEditor?templateId=${template.id}")
                },
                onDeleteTemplate = { template ->
                    scope.launch { db.workoutTemplateDao().delete(template) }
                },
            )
        }

        // ── Smart Workout ────────────────────────────────────────────────────
        composable("smartWorkout") {
            val scope = rememberCoroutineScope()
            var recentSessions by remember { mutableStateOf<List<WorkoutSessionDetail>>(emptyList()) }
            LaunchedEffect(Unit) {
                val sessions = db.workoutSessionDao().getAllCompleted().take(10)
                recentSessions = sessions.map { session ->
                    val ces = db.completedExerciseDao().getBySessionOnce(session.id)
                    val details = ces.map { ce ->
                        val exercise = ce.exerciseId?.let { db.exerciseDao().getById(it) }
                        val sets = db.exerciseSetDao().getByCompletedExerciseOnce(ce.id)
                        com.dexwritescode.workout.data.services.model.CompletedExerciseDetail(ce, exercise, sets)
                    }
                    WorkoutSessionDetail(session, details)
                }
            }

            SmartWorkoutScreen(
                exercisesFlow = db.exerciseDao().getAll(),
                recoveryFlow = db.muscleRecoveryStateDao().getAll(),
                settingsFlow = db.userSettingsDao().getAll(),
                recentSessions = recentSessions,
                onBack = { navController.popBackStack() },
                onStartWorkout = { generatedWorkout ->
                    scope.launch {
                        val template = WorkoutEngine.createTemplate(
                            workout = generatedWorkout,
                            templateDao = db.workoutTemplateDao(),
                            templateExerciseDao = db.templateExerciseDao(),
                        )
                        navController.navigate("activeWorkout/${template.id}") {
                            popUpTo("smartWorkout") { inclusive = true }
                        }
                    }
                },
            )
        }

        // ── Template Editor (create or edit) ─────────────────────────────────
        composable(
            "templateEditor?templateId={templateId}",
            arguments = listOf(navArgument("templateId") { nullable = true; defaultValue = null }),
        ) { backStackEntry ->
            val templateId = backStackEntry.arguments?.getString("templateId")
            val scope = rememberCoroutineScope()
            var existingData by remember { mutableStateOf<ExistingTemplateData?>(null) }

            LaunchedEffect(templateId) {
                if (templateId == null) return@LaunchedEffect
                val template = db.workoutTemplateDao().getById(templateId) ?: return@LaunchedEffect
                val templateExercises = db.templateExerciseDao().getByTemplate(templateId)
                    .let { flow ->
                        var result = emptyList<TemplateExercise>()
                        kotlinx.coroutines.flow.flow { emit(flow.collect { result = it }) }.collect {}
                        result
                    }
                // Build ExerciseEntry list
                val entries = templateExercises.sortedBy { it.order }.mapNotNull { te ->
                    val exercise = te.exerciseId?.let { db.exerciseDao().getById(it) } ?: return@mapNotNull null
                    var templateSets = emptyList<TemplateSet>()
                    db.templateSetDao().getByTemplateExercise(te.id).collect { templateSets = it; return@collect }
                    val setRows = if (templateSets.isEmpty()) {
                        (0 until maxOf(1, te.targetSets)).map { SetRow(weight = te.targetWeight, reps = te.targetReps) }
                    } else {
                        templateSets.sortedBy { it.order }.map { SetRow(weight = it.targetWeight, reps = it.targetReps) }
                    }
                    ExerciseEntry(exercise = exercise, setRows = setRows, restSeconds = te.restSeconds)
                }
                existingData = ExistingTemplateData(name = template.name, description = template.templateDescription, entries = entries)
            }

            TemplateEditorScreen(
                existingTemplate = existingData,
                exercisesFlow = db.exerciseDao().getAll(),
                onSave = { name, description, entries ->
                    scope.launch {
                        if (templateId != null) {
                            val template = db.workoutTemplateDao().getById(templateId) ?: return@launch
                            db.workoutTemplateDao().update(template.copy(name = name, templateDescription = description))
                            // Delete old exercises and re-insert
                            db.templateExerciseDao().getByTemplate(templateId).collect { old ->
                                old.forEach { db.templateExerciseDao().delete(it) }
                                return@collect
                            }
                        } else {
                            val template = WorkoutTemplate(name = name, templateDescription = description)
                            db.workoutTemplateDao().insert(template)
                            insertTemplateExercises(db, template.id, entries)
                            navController.popBackStack()
                            return@launch
                        }
                        insertTemplateExercises(db, templateId, entries)
                        navController.popBackStack()
                    }
                },
                onDismiss = { navController.popBackStack() },
            )
        }

        // ── Active Workout ───────────────────────────────────────────────────
        composable(
            ROUTE_ACTIVE,
            arguments = listOf(navArgument("templateId") { type = NavType.StringType }),
        ) { backStackEntry ->
            val templateId = backStackEntry.arguments!!.getString("templateId")!!
            val vm: ActiveWorkoutViewModel = viewModel(
                factory = ActiveWorkoutViewModel.Factory(
                    templateId = templateId,
                    templateDao = db.workoutTemplateDao(),
                    templateExerciseDao = db.templateExerciseDao(),
                    templateSetDao = db.templateSetDao(),
                    exerciseDao = db.exerciseDao(),
                    sessionDao = db.workoutSessionDao(),
                    completedExerciseDao = db.completedExerciseDao(),
                    exerciseSetDao = db.exerciseSetDao(),
                    recoveryDao = db.muscleRecoveryStateDao(),
                )
            )

            ActiveWorkoutScreen(
                viewModel = vm,
                onNavigateToTracking = { slotIndex ->
                    navController.navigate("exerciseTracking/$templateId/$slotIndex")
                },
                onNavigateToSummary = {
                    navController.navigate("workoutSummary/$templateId") {
                        popUpTo("activeWorkout/$templateId") { inclusive = false }
                    }
                },
                onBack = { navController.popBackStack() },
            )
        }

        // ── Exercise Tracking ────────────────────────────────────────────────
        composable(
            ROUTE_TRACKING,
            arguments = listOf(
                navArgument("templateId") { type = NavType.StringType },
                navArgument("slotIndex") { type = NavType.IntType },
            ),
        ) { backStackEntry ->
            val templateId = backStackEntry.arguments!!.getString("templateId")!!
            val slotIndex = backStackEntry.arguments!!.getInt("slotIndex")
            // Re-use the same VM from the activeWorkout destination
            val vm: ActiveWorkoutViewModel = viewModel(
                viewModelStoreOwner = navController.getBackStackEntry("activeWorkout/$templateId"),
                factory = ActiveWorkoutViewModel.Factory(
                    templateId = templateId,
                    templateDao = db.workoutTemplateDao(),
                    templateExerciseDao = db.templateExerciseDao(),
                    templateSetDao = db.templateSetDao(),
                    exerciseDao = db.exerciseDao(),
                    sessionDao = db.workoutSessionDao(),
                    completedExerciseDao = db.completedExerciseDao(),
                    exerciseSetDao = db.exerciseSetDao(),
                    recoveryDao = db.muscleRecoveryStateDao(),
                )
            )
            ExerciseTrackingScreen(
                viewModel = vm,
                slotIndex = slotIndex,
                settingsFlow = db.userSettingsDao().getAll(),
                onBack = { navController.popBackStack() },
            )
        }

        // ── Workout Summary ───────────────────────────────────────────────────
        composable(
            ROUTE_SUMMARY,
            arguments = listOf(navArgument("templateId") { type = NavType.StringType }),
        ) { backStackEntry ->
            val templateId = backStackEntry.arguments!!.getString("templateId")!!
            val vm: ActiveWorkoutViewModel = viewModel(
                viewModelStoreOwner = navController.getBackStackEntry("activeWorkout/$templateId"),
                factory = ActiveWorkoutViewModel.Factory(
                    templateId = templateId,
                    templateDao = db.workoutTemplateDao(),
                    templateExerciseDao = db.templateExerciseDao(),
                    templateSetDao = db.templateSetDao(),
                    exerciseDao = db.exerciseDao(),
                    sessionDao = db.workoutSessionDao(),
                    completedExerciseDao = db.completedExerciseDao(),
                    exerciseSetDao = db.exerciseSetDao(),
                    recoveryDao = db.muscleRecoveryStateDao(),
                )
            )
            WorkoutSummaryScreen(
                viewModel = vm,
                onSaved = { navController.popBackStack(ROUTE_PICKER, inclusive = false) },
                onDiscarded = { navController.popBackStack(ROUTE_PICKER, inclusive = false) },
            )
        }
    }
}

private suspend fun insertTemplateExercises(
    db: AppDatabase,
    templateId: String,
    entries: List<ExerciseEntry>,
) {
    entries.forEachIndexed { idx, entry ->
        val te = TemplateExercise(
            templateId = templateId,
            exerciseId = entry.exercise.id,
            order = idx,
            targetSets = entry.setRows.size,
            targetReps = entry.setRows.firstOrNull()?.reps ?: 10,
            targetWeight = entry.setRows.firstOrNull()?.weight ?: 0.0,
            restSeconds = entry.restSeconds,
        )
        db.templateExerciseDao().insert(te)
        entry.setRows.forEachIndexed { setIdx, row ->
            db.templateSetDao().insert(
                TemplateSet(templateExerciseId = te.id, order = setIdx, targetWeight = row.weight, targetReps = row.reps)
            )
        }
    }
}
