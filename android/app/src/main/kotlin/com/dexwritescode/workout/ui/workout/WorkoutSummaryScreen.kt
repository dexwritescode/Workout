package com.dexwritescode.workout.ui.workout

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.FlowRowScope
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dexwritescode.workout.ui.theme.AppColors
import kotlinx.coroutines.delay

@Composable
fun WorkoutSummaryScreen(
    viewModel: ActiveWorkoutViewModel,
    onSaved: () -> Unit,
    onDiscarded: () -> Unit,
) {
    val state by viewModel.state.collectAsState()
    val finished = state as? WorkoutState.Finished ?: return
    val summary = finished.summary

    var showContent by remember { mutableStateOf(false) }
    var notes by remember { mutableStateOf("") }
    var showDiscardDialog by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        delay(100)
        showContent = true
    }

    val scale by animateFloatAsState(
        targetValue = if (showContent) 1f else 0.6f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 200f),
        label = "trophy_scale",
    )

    Surface(color = AppColors.background, modifier = Modifier.fillMaxSize()) {
        Column {
            LazyColumn(modifier = Modifier.weight(1f)) {
                // Trophy
                item {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(top = 32.dp, bottom = 16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Surface(
                            shape = RoundedCornerShape(24.dp),
                            color = AppColors.success.copy(alpha = 0.1f),
                            modifier = Modifier
                                .size(80.dp)
                                .graphicsLayer { scaleX = scale; scaleY = scale }
                                .border(2.dp, AppColors.success.copy(alpha = 0.25f), RoundedCornerShape(24.dp)),
                        ) {
                            Column(modifier = Modifier.fillMaxSize(), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
                                Icon(Icons.Default.Check, contentDescription = null, tint = AppColors.success, modifier = Modifier.size(32.dp))
                            }
                        }
                    }
                }

                item {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(bottom = 28.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Text("Workout Complete!", fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, color = AppColors.text)
                    }
                }

                // Stats grid
                item {
                    androidx.compose.foundation.layout.Box(
                        modifier = Modifier.graphicsLayer { if (!showContent) { translationY = 20f; alpha = 0f } }
                    ) {
                        StatGrid(summary = summary, modifier = Modifier.padding(horizontal = 20.dp))
                    }
                    Spacer(Modifier.height(24.dp))
                }

                // Muscles trained
                if (summary.musclesWorked.isNotEmpty()) {
                    item {
                        Surface(
                            shape = RoundedCornerShape(AppColors.radiusCard.dp),
                            color = AppColors.surface1,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 20.dp)
                                .border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
                        ) {
                            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                SectionHeader("Muscles Trained")
                                FlowRow(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    verticalArrangement = Arrangement.spacedBy(8.dp),
                                ) {
                                    summary.musclesWorked.keys.sortedBy { it.rawValue }.forEach { muscle ->
                                        Surface(shape = RoundedCornerShape(100.dp), color = AppColors.brand.copy(alpha = 0.1f)) {
                                            Text(muscle.rawValue, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = AppColors.brand, modifier = Modifier.padding(horizontal = 12.dp, vertical = 5.dp))
                                        }
                                    }
                                }
                            }
                        }
                        Spacer(Modifier.height(16.dp))
                    }
                }

                // Exercise breakdown
                itemsIndexed(summary.exerciseBreakdowns) { index, breakdown ->
                    Surface(
                        shape = RoundedCornerShape(AppColors.radiusMedium.dp),
                        color = AppColors.surface1,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 20.dp)
                            .border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusMedium.dp)),
                    ) {
                        Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(breakdown.name, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
                            breakdown.sets.forEach { set ->
                                Row {
                                    Text("Set ${set.setNumber}", fontSize = 13.sp, color = AppColors.textTertiary, modifier = Modifier.weight(0f).padding(end = 8.dp).run { this })
                                    Text(
                                        "${"%.1f".format(set.weight)} kg × ${set.reps}",
                                        fontSize = 13.sp,
                                        fontFamily = FontFamily.Monospace,
                                        color = AppColors.textSecondary,
                                    )
                                }
                            }
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                }

                item { Spacer(Modifier.height(8.dp)) }
            }

            // Bottom buttons
            Column(modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = {
                        viewModel.saveWorkout(notes.takeIf { it.isNotBlank() })
                        onSaved()
                    },
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.brand),
                    shape = RoundedCornerShape(AppColors.radiusCard.dp),
                ) {
                    Text("Save Workout", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = AppColors.text)
                }
                Button(
                    onClick = { showDiscardDialog = true },
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.surface2),
                    shape = RoundedCornerShape(AppColors.radiusCard.dp),
                ) {
                    Text("Discard", fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textSecondary)
                }
            }
        }
    }

    if (showDiscardDialog) {
        AlertDialog(
            onDismissRequest = { showDiscardDialog = false },
            containerColor = AppColors.surface2,
            title = { Text("Discard Workout?", color = AppColors.text) },
            text = { Text("This workout will be permanently deleted.", color = AppColors.textSecondary) },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.discardWorkout()
                    onDiscarded()
                }) { Text("Discard Workout", color = AppColors.error) }
            },
            dismissButton = {
                TextButton(onClick = { showDiscardDialog = false }) { Text("Keep", color = AppColors.textSecondary) }
            },
        )
    }
}

@Composable
private fun StatGrid(summary: WorkoutSummary, modifier: Modifier = Modifier) {
    val durationSec = summary.durationMs / 1000
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        StatCard(value = ActiveWorkoutViewModel.formatDuration(durationSec), label = "Duration", modifier = Modifier.weight(1f))
        StatCard(value = "${summary.totalSets}", label = "Sets", modifier = Modifier.weight(1f))
    }
    Spacer(Modifier.height(10.dp))
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        StatCard(value = "${summary.exercisesCompleted}", label = "Exercises", modifier = Modifier.weight(1f))
        StatCard(value = formatVolume(summary.totalVolume), label = "Volume", modifier = Modifier.weight(1f))
    }
}

@Composable
private fun StatCard(value: String, label: String, modifier: Modifier = Modifier) {
    Surface(
        shape = RoundedCornerShape(AppColors.radiusCard.dp),
        color = AppColors.surface1,
        modifier = modifier.border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
    ) {
        Column(
            modifier = Modifier.padding(16.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(value, fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, color = AppColors.brand)
            Text(label, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = AppColors.textSecondary)
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(text.uppercase(), fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textSecondary, letterSpacing = 0.7.sp)
}

private fun formatVolume(volume: Double): String =
    if (volume >= 1000) "${"%.1f".format(volume / 1000)}k" else "%.0f".format(volume)
