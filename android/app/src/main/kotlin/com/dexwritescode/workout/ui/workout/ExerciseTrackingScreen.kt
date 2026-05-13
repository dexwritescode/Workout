package com.dexwritescode.workout.ui.workout

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Scale
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
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
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dexwritescode.workout.data.model.entity.ExerciseSet
import com.dexwritescode.workout.data.model.entity.UserSettings
import com.dexwritescode.workout.ui.theme.AppColors
import kotlinx.coroutines.flow.Flow

private const val REST_TIMER_PREF_KEY = "activeRestTimerEndDate"

@Composable
fun ExerciseTrackingScreen(
    viewModel: ActiveWorkoutViewModel,
    slotIndex: Int,
    settingsFlow: Flow<List<UserSettings>>,
    onBack: () -> Unit,
) {
    val state by viewModel.state.collectAsState()
    val inProgress = state as? WorkoutState.InProgress ?: return
    if (slotIndex !in inProgress.slots.indices) return
    val slot = inProgress.slots[slotIndex]

    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("workout_prefs", android.content.Context.MODE_PRIVATE) }

    val completedSets = slot.completedSets.filter { it.isCompleted }.sortedBy { it.setNumber }
    var extraSets by rememberSaveable { mutableIntStateOf(0) }
    val targetSets = maxOf(maxOf(1, completedSets.size), slot.templateExercise.targetSets + extraSets)
    val allComplete = completedSets.size >= targetSets

    var weight by rememberSaveable { mutableDoubleStateOf(0.0) }
    var reps by rememberSaveable { mutableIntStateOf(slot.templateExercise.targetReps) }
    var editingSet by remember { mutableStateOf<ExerciseSet?>(null) }
    var restTimerEndMs by rememberSaveable { mutableLongStateOf(0L) }
    var showRestTimer by rememberSaveable { mutableStateOf(false) }
    var showPlateCalc by remember { mutableStateOf(false) }

    // Restore state
    LaunchedEffect(Unit) {
        val savedEnd = prefs.getLong(REST_TIMER_PREF_KEY, 0L)
        if (savedEnd > System.currentTimeMillis()) {
            restTimerEndMs = savedEnd
            showRestTimer = true
        }
        // Pre-fill weight/reps from last completed set or template
        val lastSet = completedSets.lastOrNull()
        if (lastSet != null) {
            weight = lastSet.weight
            reps = lastSet.reps
        } else {
            val ts = slot.templateSets.getOrNull(0)
            if (ts != null && ts.targetWeight > 0) {
                weight = ts.targetWeight
                reps = ts.targetReps
            }
        }
    }

    if (showPlateCalc) {
        PlateCalculatorSheet(
            targetWeight = weight,
            settingsFlow = settingsFlow,
            onDismiss = { showPlateCalc = false },
        )
        return
    }

    Column(modifier = Modifier.fillMaxSize().background(AppColors.background)) {
        // Toolbar
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = AppColors.text)
            }
            Text(
                slot.exercise?.name ?: "Exercise",
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                color = AppColors.text,
                modifier = Modifier.weight(1f),
            )
            IconButton(onClick = { showPlateCalc = true }, enabled = weight > 0) {
                Icon(Icons.Default.Scale, contentDescription = "Plate calculator", tint = if (weight > 0) AppColors.text else AppColors.textTertiary)
            }
        }
        // Subtitle
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                "${if (completedSets.isNotEmpty()) completedSets.size else 1} of $targetSets sets",
                fontSize = 11.sp,
                color = AppColors.textTertiary,
            )
            Text(" · ", fontSize = 11.sp, color = AppColors.textTertiary)
            Text(
                slot.exercise?.primaryMuscleGroups?.joinToString(", ") { it.rawValue } ?: "",
                fontSize = 11.sp,
                color = AppColors.textTertiary,
            )
            Spacer(Modifier.weight(1f))
            if (allComplete) {
                Surface(shape = RoundedCornerShape(6.dp), color = AppColors.success.copy(alpha = 0.13f)) {
                    Text("Done", fontSize = 10.sp, fontWeight = FontWeight.SemiBold, color = AppColors.success, modifier = Modifier.padding(horizontal = 7.dp, vertical = 2.dp))
                }
            }
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            // Rest timer banner
            AnimatedVisibility(visible = showRestTimer, enter = expandVertically(), exit = shrinkVertically()) {
                RestTimerBanner(
                    endTimeMs = restTimerEndMs,
                    onComplete = {
                        showRestTimer = false
                        prefs.edit().remove(REST_TIMER_PREF_KEY).apply()
                    },
                    onSkip = {
                        showRestTimer = false
                        prefs.edit().remove(REST_TIMER_PREF_KEY).apply()
                    },
                    onAdjust = { deltaMs ->
                        restTimerEndMs += deltaMs
                        prefs.edit().putLong(REST_TIMER_PREF_KEY, restTimerEndMs).apply()
                    },
                )
            }

            // Sets table
            SetsTable(
                completedSets = completedSets,
                targetSets = targetSets,
                weight = weight,
                reps = reps,
                editingSet = editingSet,
                templateSets = slot.templateSets.map { it.targetWeight to it.targetReps },
                onWeightChange = { weight = it },
                onRepsChange = { reps = it },
                onBeginEdit = { set ->
                    editingSet = set
                    weight = set.weight
                    reps = set.reps
                },
                onCancelEdit = {
                    editingSet = null
                    completedSets.lastOrNull()?.let { weight = it.weight; reps = it.reps }
                },
                onSaveEdit = { set ->
                    viewModel.updateSet(slotIndex, set, weight, reps)
                    editingSet = null
                },
                onDeleteSet = { set -> viewModel.deleteSet(slotIndex, set) },
                onAddExtraSet = { extraSets++ },
                onDeleteExtraRow = {
                    if (targetSets > maxOf(1, completedSets.size)) extraSets--
                },
            )

            // All complete banner
            AnimatedVisibility(visible = allComplete && editingSet == null, enter = expandVertically(), exit = shrinkVertically()) {
                Surface(
                    shape = RoundedCornerShape(AppColors.radiusCard.dp),
                    color = AppColors.success.copy(alpha = 0.06f),
                    modifier = Modifier.fillMaxWidth().border(1.dp, AppColors.success.copy(alpha = 0.15f), RoundedCornerShape(AppColors.radiusCard.dp)),
                ) {
                    Column(modifier = Modifier.padding(16.dp).fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("All sets complete!", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = AppColors.success)
                        Text("Head back to continue your workout.", fontSize = 14.sp, color = AppColors.textSecondary)
                    }
                }
            }
        }

        // Bottom button
        val editing = editingSet
        if (editing != null) {
            Button(
                onClick = {
                    viewModel.updateSet(slotIndex, editing, weight, reps)
                    editingSet = null
                },
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp).height(52.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.brand),
                shape = RoundedCornerShape(AppColors.radiusCard.dp),
            ) {
                Text("Update Set ${editing.setNumber}", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = AppColors.text)
            }
        } else if (!allComplete) {
            Button(
                onClick = {
                    viewModel.logSet(slotIndex, weight, reps)
                    val nextSetIndex = completedSets.size + 1
                    if (nextSetIndex < targetSets) {
                        // Start rest timer
                        val endMs = System.currentTimeMillis() + slot.templateExercise.restSeconds * 1000L
                        restTimerEndMs = endMs
                        showRestTimer = true
                        prefs.edit().putLong(REST_TIMER_PREF_KEY, endMs).apply()
                        // Pre-fill next set values
                        val ts = slot.templateSets.getOrNull(nextSetIndex)
                        if (ts != null && ts.targetWeight > 0) {
                            weight = ts.targetWeight; reps = ts.targetReps
                        }
                    } else {
                        showRestTimer = false
                        prefs.edit().remove(REST_TIMER_PREF_KEY).apply()
                        viewModel.markExerciseComplete(slotIndex)
                    }
                },
                enabled = weight > 0,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp).height(52.dp),
                colors = ButtonDefaults.buttonColors(containerColor = if (weight > 0) AppColors.brand else AppColors.surface3),
                shape = RoundedCornerShape(AppColors.radiusCard.dp),
            ) {
                Text("Log Set ${completedSets.size + 1}", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = AppColors.text)
            }
        } else {
            Button(
                onClick = onBack,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp).height(52.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.success),
                shape = RoundedCornerShape(AppColors.radiusCard.dp),
            ) {
                Text("Done", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = AppColors.text)
            }
        }
    }
}

@Composable
private fun SetsTable(
    completedSets: List<ExerciseSet>,
    targetSets: Int,
    weight: Double,
    reps: Int,
    editingSet: ExerciseSet?,
    templateSets: List<Pair<Double, Int>>,
    onWeightChange: (Double) -> Unit,
    onRepsChange: (Int) -> Unit,
    onBeginEdit: (ExerciseSet) -> Unit,
    onCancelEdit: () -> Unit,
    onSaveEdit: (ExerciseSet) -> Unit,
    onDeleteSet: (ExerciseSet) -> Unit,
    onAddExtraSet: () -> Unit,
    onDeleteExtraRow: () -> Unit,
) {
    Column {
        Row(modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp)) {
            Text("SETS — ${completedSets.size}/$targetSets", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textSecondary, letterSpacing = 0.7.sp, modifier = Modifier.weight(1f))
            if (editingSet != null) {
                Text("Cancel", fontSize = 14.sp, fontWeight = FontWeight.Medium, color = AppColors.textSecondary, modifier = Modifier.clickable { onCancelEdit() })
            }
        }

        Surface(
            shape = RoundedCornerShape(AppColors.radiusCard.dp),
            color = AppColors.surface1,
            modifier = Modifier.fillMaxWidth().border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
        ) {
            Column {
                // Header
                Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
                    Text("SET", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textTertiary, modifier = Modifier.width(32.dp))
                    Text("WEIGHT", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textTertiary, modifier = Modifier.weight(1f))
                    Text("REPS", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textTertiary, modifier = Modifier.weight(1f))
                    Spacer(Modifier.width(40.dp))
                }
                HorizontalDivider(color = AppColors.border, modifier = Modifier.padding(start = 16.dp))

                repeat(targetSets) { i ->
                    if (i > 0) HorizontalDivider(color = AppColors.border, modifier = Modifier.padding(start = 16.dp))

                    val done = i < completedSets.size
                    val set = if (done) completedSets[i] else null
                    val isCurrent = i == completedSets.size && !completedSets.none { true }
                    val isEditing = editingSet?.id == set?.id

                    when {
                        isEditing && set != null -> InputRow(index = i, weight = weight, reps = reps, onWeightChange = onWeightChange, onRepsChange = onRepsChange, isHighlighted = true)
                        done && set != null -> {
                            val swipeState = rememberSwipeToDismissBoxState(
                                confirmValueChange = { v -> if (v == SwipeToDismissBoxValue.EndToStart) { onDeleteSet(set); true } else false }
                            )
                            SwipeToDismissBox(
                                state = swipeState,
                                enableDismissFromStartToEnd = false,
                                backgroundContent = {
                                    Box(Modifier.fillMaxSize().background(AppColors.error.copy(alpha = 0.15f)), contentAlignment = Alignment.CenterEnd) {
                                        Icon(Icons.Default.Close, contentDescription = "Delete", tint = AppColors.error, modifier = Modifier.padding(end = 16.dp).size(18.dp))
                                    }
                                }
                            ) {
                                CompletedRow(index = i, set = set, onTap = { onBeginEdit(set) })
                            }
                        }
                        i == completedSets.size -> InputRow(index = i, weight = weight, reps = reps, onWeightChange = onWeightChange, onRepsChange = onRepsChange, isHighlighted = false)
                        else -> {
                            val (tw, tr) = templateSets.getOrElse(i) { 0.0 to 0 }
                            FutureRow(index = i, weight = tw, reps = tr)
                        }
                    }
                }
            }
        }

        // Add Set button
        Spacer(Modifier.height(8.dp))
        Surface(
            shape = RoundedCornerShape(AppColors.radiusCard.dp),
            color = AppColors.brand.copy(alpha = 0.06f),
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, AppColors.brand.copy(alpha = 0.2f), RoundedCornerShape(AppColors.radiusCard.dp))
                .clickable { onAddExtraSet() },
        ) {
            Row(
                modifier = Modifier.padding(vertical = 10.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("+ Add Set", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = AppColors.brand)
            }
        }
    }
}

@Composable
private fun CompletedRow(index: Int, set: ExerciseSet, onTap: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().clickable { onTap() }.padding(horizontal = 16.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("${index + 1}", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = AppColors.text, modifier = Modifier.width(32.dp))
        Text("${"%.1f".format(set.weight)} kg", fontSize = 15.sp, fontWeight = FontWeight.Medium, color = AppColors.text, modifier = Modifier.weight(1f))
        Text("${set.reps}", fontSize = 15.sp, fontWeight = FontWeight.Medium, color = AppColors.text, modifier = Modifier.weight(1f))
        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = AppColors.success, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(22.dp))
    }
}

@Composable
private fun InputRow(index: Int, weight: Double, reps: Int, onWeightChange: (Double) -> Unit, onRepsChange: (Int) -> Unit, isHighlighted: Boolean) {
    var weightText by remember(weight) { mutableStateOf(if (weight == 0.0) "" else "%.1f".format(weight).trimEnd('0').trimEnd('.')) }
    var repsText by remember(reps) { mutableStateOf(reps.toString()) }

    Row(
        modifier = Modifier.fillMaxWidth().background(AppColors.brand.copy(alpha = 0.05f)).padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("${index + 1}", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = AppColors.brand, modifier = Modifier.width(32.dp))

        OutlinedTextField(
            value = weightText,
            onValueChange = { weightText = it; it.toDoubleOrNull()?.let { v -> onWeightChange(v) } },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.weight(1f).height(48.dp).padding(end = 8.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = AppColors.brand.copy(0.4f), unfocusedBorderColor = AppColors.border,
                focusedContainerColor = AppColors.surface2, unfocusedContainerColor = AppColors.surface2,
                focusedTextColor = AppColors.text, unfocusedTextColor = AppColors.text,
            ),
            shape = RoundedCornerShape(8.dp),
            textStyle = androidx.compose.ui.text.TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold, fontSize = 14.sp),
        )

        OutlinedTextField(
            value = repsText,
            onValueChange = { repsText = it; it.toIntOrNull()?.let { v -> onRepsChange(v) } },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.weight(1f).height(48.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = AppColors.brand.copy(0.4f), unfocusedBorderColor = AppColors.border,
                focusedContainerColor = AppColors.surface2, unfocusedContainerColor = AppColors.surface2,
                focusedTextColor = AppColors.text, unfocusedTextColor = AppColors.text,
            ),
            shape = RoundedCornerShape(8.dp),
            textStyle = androidx.compose.ui.text.TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold, fontSize = 14.sp),
        )
        Spacer(Modifier.width(40.dp))
    }
}

@Composable
private fun FutureRow(index: Int, weight: Double, reps: Int) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("${index + 1}", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = AppColors.textTertiary, modifier = Modifier.width(32.dp))
        Text(if (weight > 0) "${"%.1f".format(weight)} kg" else "— kg", fontSize = 15.sp, fontWeight = FontWeight.Medium, color = AppColors.textTertiary, modifier = Modifier.weight(1f))
        Text("$reps", fontSize = 15.sp, fontWeight = FontWeight.Medium, color = AppColors.textTertiary, modifier = Modifier.weight(1f))
        Spacer(Modifier.width(40.dp))
    }
}
