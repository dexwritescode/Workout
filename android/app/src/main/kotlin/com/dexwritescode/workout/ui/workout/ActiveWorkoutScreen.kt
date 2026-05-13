package com.dexwritescode.workout.ui.workout

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dexwritescode.workout.ui.theme.AppColors

@Composable
fun ActiveWorkoutScreen(
    viewModel: ActiveWorkoutViewModel,
    onNavigateToTracking: (Int) -> Unit,
    onNavigateToSummary: () -> Unit,
    onBack: () -> Unit,
) {
    val state by viewModel.state.collectAsState()
    var showCancelDialog by remember { mutableStateOf(false) }
    var showExercisePicker by remember { mutableStateOf(false) }

    // Auto-start if navigated from Smart Workout
    LaunchedEffect(Unit) {
        // autoStart is handled by the nav graph passing a flag
    }

    if (showExercisePicker) {
        // We can't easily access the exerciseDao directly here — the NavGraph wires this
        // by passing the flow; handled at nav graph level
    }

    when (val s = state) {
        is WorkoutState.Loading -> {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("Loading...", color = AppColors.textSecondary)
            }
        }
        is WorkoutState.NotStarted -> {
            PreWorkoutView(
                state = s,
                templateName = s.template.name,
                onStart = { viewModel.startWorkout() },
                onBack = onBack,
            )
        }
        is WorkoutState.InProgress -> {
            InProgressView(
                state = s,
                onExerciseTap = { index -> onNavigateToTracking(index) },
                onRemoveExercise = { index -> viewModel.removeExercise(index) },
                onAddExercise = { showExercisePicker = true },
                onFinish = {
                    viewModel.finishWorkout()
                    onNavigateToSummary()
                },
                onCancelRequest = { showCancelDialog = true },
            )
        }
        is WorkoutState.Finished -> {
            // Summary is shown as a separate screen navigated by the parent
            FinishedPlaceholder()
        }
    }

    if (showCancelDialog) {
        AlertDialog(
            onDismissRequest = { showCancelDialog = false },
            containerColor = AppColors.surface2,
            title = { Text("Cancel Workout?", color = AppColors.text) },
            text = { Text("Your progress will be lost.", color = AppColors.textSecondary) },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.cancelWorkout()
                    showCancelDialog = false
                    onBack()
                }) { Text("Cancel Workout", color = AppColors.error) }
            },
            dismissButton = {
                TextButton(onClick = { showCancelDialog = false }) { Text("Keep Going", color = AppColors.textSecondary) }
            },
        )
    }
}

@Composable
private fun PreWorkoutView(
    state: WorkoutState.NotStarted,
    templateName: String,
    onStart: () -> Unit,
    onBack: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxSize().background(AppColors.background)) {
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = AppColors.text)
            }
            Text(templateName, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
        }
        HorizontalDivider(color = AppColors.border)

        LazyColumn(modifier = Modifier.weight(1f).padding(horizontal = 16.dp, vertical = 12.dp)) {
            itemsIndexed(state.slots) { index, slot ->
                ExerciseRowContent(slot = slot, isCurrent = false, isActive = false)
                if (index < state.slots.size - 1) Spacer(Modifier.height(6.dp))
            }
        }

        Button(
            onClick = onStart,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp).height(52.dp),
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.brand),
            shape = RoundedCornerShape(AppColors.radiusCard.dp),
        ) {
            Text("▶  Start Workout", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = AppColors.text)
        }
    }
}

@Composable
private fun InProgressView(
    state: WorkoutState.InProgress,
    onExerciseTap: (Int) -> Unit,
    onRemoveExercise: (Int) -> Unit,
    onAddExercise: () -> Unit,
    onFinish: () -> Unit,
    onCancelRequest: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxSize().background(AppColors.background)) {
        // Toolbar
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onCancelRequest) {
                Text("Cancel", color = AppColors.error)
            }
            Text(
                state.template.name,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                color = AppColors.text,
                modifier = Modifier.weight(1f),
            )
            IconButton(onClick = onAddExercise) {
                Icon(Icons.Default.Add, contentDescription = "Add exercise", tint = AppColors.text)
            }
        }
        HorizontalDivider(color = AppColors.border)

        // Elapsed timer bar
        ElapsedTimerBar(elapsedSeconds = state.elapsedSeconds)

        LazyColumn(modifier = Modifier.weight(1f).padding(horizontal = 16.dp, vertical = 12.dp)) {
            itemsIndexed(state.slots, key = { _, slot -> slot.completedExercise.id }) { index, slot ->
                val dismissState = rememberSwipeToDismissBoxState(
                    confirmValueChange = { value ->
                        if (value == SwipeToDismissBoxValue.EndToStart) {
                            onRemoveExercise(index)
                            true
                        } else false
                    }
                )
                SwipeToDismissBox(
                    state = dismissState,
                    enableDismissFromStartToEnd = false,
                    backgroundContent = {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .clip(RoundedCornerShape(AppColors.radiusMedium.dp))
                                .background(AppColors.error.copy(alpha = 0.15f)),
                            contentAlignment = Alignment.CenterEnd,
                        ) {
                            Icon(Icons.Default.Close, contentDescription = "Remove", tint = AppColors.error, modifier = Modifier.padding(end = 24.dp))
                        }
                    },
                ) {
                    ExerciseRowContent(
                        slot = slot,
                        isCurrent = index == state.currentIndex,
                        isActive = true,
                        modifier = Modifier.clickable { onExerciseTap(index) },
                    )
                }
                if (index < state.slots.size - 1) Spacer(Modifier.height(6.dp))
            }
        }

        Button(
            onClick = onFinish,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp).height(52.dp),
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.success),
            shape = RoundedCornerShape(AppColors.radiusCard.dp),
        ) {
            Text("✓  Finish Workout", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = AppColors.text)
        }
    }
}

@Composable
private fun ElapsedTimerBar(elapsedSeconds: Long) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.surface2)
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("⏱", fontSize = 15.sp, color = AppColors.textSecondary)
        Spacer(Modifier.width(6.dp))
        Text(
            ActiveWorkoutViewModel.formatDuration(elapsedSeconds),
            fontSize = 15.sp,
            fontWeight = FontWeight.Medium,
            fontFamily = FontFamily.Monospace,
            color = AppColors.brand,
        )
    }
}

@Composable
private fun ExerciseRowContent(
    slot: ExerciseSlot,
    isCurrent: Boolean,
    isActive: Boolean,
    modifier: Modifier = Modifier,
) {
    val completedSets = slot.completedSets.count { it.isCompleted }
    val isExerciseDone = isActive && completedSets >= slot.templateExercise.targetSets

    Surface(
        shape = RoundedCornerShape(AppColors.radiusMedium.dp),
        color = when {
            isCurrent -> AppColors.brand.copy(alpha = 0.07f)
            else -> AppColors.surface1
        },
        modifier = modifier
            .fillMaxWidth()
            .border(
                1.dp,
                if (isCurrent) AppColors.brand.copy(alpha = 0.2f) else AppColors.border,
                RoundedCornerShape(AppColors.radiusMedium.dp),
            ),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // Status circle
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(
                        when {
                            isExerciseDone -> AppColors.success.copy(alpha = 0.75f)
                            else -> AppColors.surface2
                        }
                    )
                    .then(
                        if (isCurrent) Modifier.border(2.5.dp, AppColors.brand, CircleShape)
                        else Modifier
                    ),
                contentAlignment = Alignment.Center,
            ) {
                if (isExerciseDone) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
                } else {
                    Text(
                        slot.exercise?.name?.firstOrNull()?.toString() ?: "?",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (isCurrent) AppColors.brand else AppColors.textSecondary,
                    )
                }
            }

            Spacer(Modifier.width(14.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    slot.exercise?.name ?: "Unknown Exercise",
                    fontSize = 15.sp,
                    fontWeight = if (isCurrent) FontWeight.Bold else FontWeight.Medium,
                    color = AppColors.text,
                )
                if (isActive && completedSets > 0) {
                    Text("$completedSets/${slot.templateExercise.targetSets} sets logged", fontSize = 13.sp, color = AppColors.textTertiary)
                } else {
                    val weightText = if (slot.templateExercise.targetWeight > 0) " · ${"%.1f".format(slot.templateExercise.targetWeight)} kg" else ""
                    Text("${slot.templateExercise.targetSets} sets × ${slot.templateExercise.targetReps} reps$weightText", fontSize = 13.sp, color = AppColors.textTertiary)
                }
                if (isActive && isCurrent && !isExerciseDone) {
                    Text("Tap to track sets →", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.brand, modifier = Modifier.padding(top = 1.dp))
                }
            }

            slot.exercise?.primaryMuscleGroups?.firstOrNull()?.let { muscle ->
                Surface(shape = RoundedCornerShape(6.dp), color = AppColors.textSecondary.copy(alpha = 0.13f)) {
                    Text(muscle.rawValue, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textSecondary, modifier = Modifier.padding(horizontal = 7.dp, vertical = 2.dp))
                }
            }
        }
    }
}

@Composable
private fun FinishedPlaceholder() {
    Box(modifier = Modifier.fillMaxSize().background(AppColors.background), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = AppColors.success, modifier = Modifier.size(48.dp))
            Text("Workout Complete!", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = AppColors.text)
        }
    }
}
