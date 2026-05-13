package com.dexwritescode.workout.ui.workout

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.MuscleRecoveryState
import com.dexwritescode.workout.data.model.entity.UserSettings
import com.dexwritescode.workout.data.model.entity.WorkoutSession
import com.dexwritescode.workout.data.model.enums.SplitType
import com.dexwritescode.workout.data.services.model.WorkoutSessionDetail
import com.dexwritescode.workout.data.services.workout.WorkoutEngine
import com.dexwritescode.workout.ui.theme.AppColors
import kotlinx.coroutines.flow.Flow

@Composable
fun SmartWorkoutScreen(
    exercisesFlow: Flow<List<Exercise>>,
    recoveryFlow: Flow<List<MuscleRecoveryState>>,
    settingsFlow: Flow<List<UserSettings>>,
    recentSessions: List<WorkoutSessionDetail>,
    onBack: () -> Unit,
    onStartWorkout: (WorkoutEngine.GeneratedWorkout) -> Unit,
) {
    val allExercises by exercisesFlow.collectAsState(initial = emptyList())
    val recoveryStates by recoveryFlow.collectAsState(initial = emptyList())
    val settingsList by settingsFlow.collectAsState(initial = emptyList())

    val defaultSplit = settingsList.firstOrNull()?.splitType ?: SplitType.PUSH_PULL_LEGS
    var selectedSplit by remember { mutableStateOf(defaultSplit) }
    var generatedWorkout by remember { mutableStateOf<WorkoutEngine.GeneratedWorkout?>(null) }

    LaunchedEffect(allExercises, recoveryStates) {
        if (allExercises.isNotEmpty()) {
            generatedWorkout = WorkoutEngine.generateWorkout(selectedSplit, recoveryStates, allExercises, recentSessions)
        }
    }

    fun regenerate() {
        if (allExercises.isNotEmpty()) {
            generatedWorkout = WorkoutEngine.generateWorkout(selectedSplit, recoveryStates, allExercises, recentSessions)
        }
    }

    Surface(color = AppColors.background, modifier = Modifier.fillMaxSize()) {
        Column {
            // Toolbar
            Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = AppColors.text)
                }
                Text("Smart Workout", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
            }

            HorizontalDivider(color = AppColors.border)

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                // Split picker
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    SectionHeader("Training Split")
                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        SplitType.entries.forEach { split ->
                            SplitChip(
                                label = split.rawValue,
                                selected = split == selectedSplit,
                                onClick = {
                                    selectedSplit = split
                                    regenerate()
                                },
                            )
                        }
                    }
                }

                // Workout preview or generate prompt
                val workout = generatedWorkout
                if (workout != null) {
                    WorkoutPreview(workout = workout, onRegenerate = { regenerate() })
                } else {
                    GeneratePrompt(onGenerate = { regenerate() })
                }
            }

            // Start button
            if (generatedWorkout != null) {
                Button(
                    onClick = { generatedWorkout?.let { onStartWorkout(it) } },
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp).height(52.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.brand),
                    shape = RoundedCornerShape(AppColors.radiusCard.dp),
                ) {
                    Text("▶  Start Workout", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = AppColors.text)
                }
            }
        }
    }
}

@Composable
private fun SplitChip(label: String, selected: Boolean, onClick: () -> Unit) {
    val bg = if (selected) AppColors.brand.copy(alpha = 0.12f) else AppColors.surface2
    val textColor = if (selected) AppColors.brand else AppColors.textSecondary
    val borderColor = if (selected) AppColors.brand else AppColors.borderStrong

    Surface(
        shape = RoundedCornerShape(100.dp),
        color = bg,
        modifier = Modifier
            .border(1.dp, borderColor, RoundedCornerShape(100.dp))
            .clickable { onClick() },
    ) {
        Text(
            label,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = textColor,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
        )
    }
}

@Composable
private fun GeneratePrompt(onGenerate: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("✦", fontSize = 48.sp, color = AppColors.textTertiary)
        Text(
            "Tap Generate to create a workout\nbased on your recovery status.",
            fontSize = 15.sp,
            color = AppColors.textSecondary,
        )
        Button(
            onClick = onGenerate,
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.brand),
            shape = RoundedCornerShape(AppColors.radiusCard.dp),
        ) {
            Text("✦  Generate Workout", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
        }
    }
}

@Composable
private fun WorkoutPreview(workout: WorkoutEngine.GeneratedWorkout, onRegenerate: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        // Header card
        Surface(
            shape = RoundedCornerShape(AppColors.radiusCard.dp),
            color = AppColors.surface1,
            modifier = Modifier.fillMaxWidth().border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
        ) {
            Column(
                modifier = Modifier.padding(16.dp).fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(workout.name, fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, color = AppColors.text)
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    Text("${workout.exercises.size} exercises", fontSize = 14.sp, color = AppColors.textSecondary)
                    Text("~${workout.estimatedDurationMinutes} min", fontSize = 14.sp, color = AppColors.textSecondary)
                }
                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()).padding(top = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    workout.targetMuscles.forEach { muscle ->
                        Surface(shape = RoundedCornerShape(100.dp), color = AppColors.brand.copy(alpha = 0.12f)) {
                            Text(
                                muscle.rawValue,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = AppColors.brand,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 3.dp),
                            )
                        }
                    }
                }
            }
        }

        // Exercise list
        Surface(
            shape = RoundedCornerShape(AppColors.radiusCard.dp),
            color = AppColors.surface1,
            modifier = Modifier.fillMaxWidth().border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
        ) {
            Column {
                workout.exercises.forEachIndexed { index, suggestion ->
                    if (index > 0) HorizontalDivider(color = AppColors.border, modifier = Modifier.padding(start = 56.dp))
                    SuggestedExerciseRow(index = index + 1, suggestion = suggestion)
                }
            }
        }

        // Regenerate button
        Surface(
            shape = RoundedCornerShape(10.dp),
            color = AppColors.surface1,
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, AppColors.borderStrong, RoundedCornerShape(10.dp))
                .clickable { onRegenerate() },
        ) {
            Row(
                modifier = Modifier.padding(vertical = 10.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("↺  Regenerate", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = AppColors.brand)
            }
        }
    }
}

@Composable
private fun SuggestedExerciseRow(index: Int, suggestion: WorkoutEngine.SuggestedExercise) {
    val isCompound = suggestion.exercise.primaryMuscleGroups.size > 1 || suggestion.exercise.secondaryMuscleGroups.isNotEmpty()
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Number badge
        Surface(
            shape = RoundedCornerShape(8.dp),
            color = AppColors.brand.copy(alpha = 0.1f),
            modifier = Modifier.size(28.dp),
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text("$index", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = AppColors.brand)
            }
        }

        Column(modifier = Modifier.weight(1f).padding(start = 14.dp)) {
            Text(suggestion.exercise.name, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
            Text(
                "${suggestion.targetSets} sets × ${suggestion.targetReps} reps · ${suggestion.exercise.primaryMuscleGroups.joinToString(", ") { it.rawValue }}",
                fontSize = 13.sp,
                color = AppColors.textTertiary,
            )
        }

        Surface(
            shape = RoundedCornerShape(6.dp),
            color = (if (isCompound) AppColors.compound else AppColors.isolation).copy(alpha = 0.13f),
        ) {
            Text(
                if (isCompound) "compound" else "isolation",
                fontSize = 10.sp,
                fontWeight = FontWeight.SemiBold,
                color = if (isCompound) AppColors.compound else AppColors.isolation,
                modifier = Modifier.padding(horizontal = 7.dp, vertical = 2.dp),
            )
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(text.uppercase(), fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textSecondary, letterSpacing = 0.7.sp)
}
