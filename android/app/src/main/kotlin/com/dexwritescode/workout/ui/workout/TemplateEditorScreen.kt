package com.dexwritescode.workout.ui.workout

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.TemplateExercise
import com.dexwritescode.workout.data.model.entity.TemplateSet
import com.dexwritescode.workout.ui.theme.AppColors
import kotlinx.coroutines.flow.Flow

data class SetRow(val weight: Double = 0.0, val reps: Int = 10)
data class ExerciseEntry(val exercise: Exercise, val setRows: List<SetRow>, val restSeconds: Int = 90)

private val restOptions = listOf(30 to "30 sec", 60 to "1 min", 90 to "90 sec", 120 to "2 min", 180 to "3 min", 300 to "5 min")

@Composable
fun TemplateEditorScreen(
    existingTemplate: ExistingTemplateData?,
    exercisesFlow: Flow<List<Exercise>>,
    onSave: (name: String, description: String, entries: List<ExerciseEntry>) -> Unit,
    onDismiss: () -> Unit,
) {
    var name by rememberSaveable { mutableStateOf(existingTemplate?.name ?: "") }
    var description by rememberSaveable { mutableStateOf(existingTemplate?.description ?: "") }
    var entries by remember { mutableStateOf(existingTemplate?.entries ?: emptyList()) }
    var showExercisePicker by remember { mutableStateOf(false) }

    val isValid = name.isNotBlank() && entries.isNotEmpty() && entries.all { it.setRows.isNotEmpty() }

    if (showExercisePicker) {
        ExercisePickerSheet(
            exercisesFlow = exercisesFlow,
            onSelect = { exercise ->
                entries = entries + ExerciseEntry(exercise = exercise, setRows = listOf(SetRow(), SetRow(), SetRow()))
                showExercisePicker = false
            },
            onDismiss = { showExercisePicker = false },
        )
        return
    }

    Surface(color = AppColors.background, modifier = Modifier.fillMaxSize()) {
        Column {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                TextButton(onClick = onDismiss) {
                    Text("Cancel", color = AppColors.textSecondary)
                }
                Text(
                    text = if (existingTemplate != null) "Edit Template" else "New Template",
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.text,
                )
                TextButton(onClick = { if (isValid) onSave(name.trim(), description.trim(), entries) }, enabled = isValid) {
                    Text("Save", color = if (isValid) AppColors.brand else AppColors.textTertiary, fontWeight = FontWeight.Bold)
                }
            }

            HorizontalDivider(color = AppColors.border)

            LazyColumn(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp)) {
                // Details section
                item {
                    Spacer(Modifier.height(16.dp))
                    SectionHeader("Details")
                    Spacer(Modifier.height(8.dp))
                    Surface(
                        shape = RoundedCornerShape(AppColors.radiusCard.dp),
                        color = AppColors.surface1,
                        modifier = Modifier.fillMaxWidth().border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
                    ) {
                        Column {
                            EditorTextField(value = name, onValueChange = { name = it }, placeholder = "Template Name")
                            HorizontalDivider(color = AppColors.border, modifier = Modifier.padding(start = 16.dp))
                            EditorTextField(value = description, onValueChange = { description = it }, placeholder = "Description (optional)")
                        }
                    }
                }

                // Exercise sections
                entries.forEachIndexed { idx, entry ->
                    item {
                        Spacer(Modifier.height(20.dp))
                        ExerciseSection(
                            entry = entry,
                            onUpdate = { updated ->
                                entries = entries.toMutableList().also { it[idx] = updated }
                            },
                            onDelete = {
                                entries = entries.toMutableList().also { it.removeAt(idx) }
                            },
                        )
                    }
                }

                // Add Exercise button
                item {
                    Spacer(Modifier.height(16.dp))
                    Surface(
                        shape = RoundedCornerShape(AppColors.radiusCard.dp),
                        color = AppColors.brand.copy(alpha = 0.06f),
                        modifier = Modifier
                            .fillMaxWidth()
                            .border(1.dp, AppColors.brand.copy(alpha = 0.2f), RoundedCornerShape(AppColors.radiusCard.dp))
                            .clickable { showExercisePicker = true },
                    ) {
                        Row(
                            modifier = Modifier.padding(16.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null, tint = AppColors.brand, modifier = Modifier.size(18.dp))
                            Text("Add Exercise", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = AppColors.brand, modifier = Modifier.padding(start = 8.dp))
                        }
                    }
                    Spacer(Modifier.height(32.dp))
                }
            }
        }
    }
}

@Composable
private fun ExerciseSection(
    entry: ExerciseEntry,
    onUpdate: (ExerciseEntry) -> Unit,
    onDelete: () -> Unit,
) {
    Column {
        // Section header
        Row(modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(entry.exercise.name, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
                Text(
                    entry.exercise.primaryMuscleGroups.joinToString(", ") { it.rawValue },
                    fontSize = 11.sp,
                    color = AppColors.textSecondary,
                )
            }
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Remove", tint = AppColors.error, modifier = Modifier.size(18.dp))
            }
        }

        Surface(
            shape = RoundedCornerShape(AppColors.radiusCard.dp),
            color = AppColors.surface1,
            modifier = Modifier.fillMaxWidth().border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
        ) {
            Column {
                // Column headers
                Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
                    Text("SET", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textTertiary, modifier = Modifier.weight(0.15f))
                    Spacer(Modifier.weight(0.05f))
                    Text("WEIGHT", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textTertiary, modifier = Modifier.weight(0.35f))
                    Spacer(Modifier.weight(0.05f))
                    Text("REPS", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textTertiary, modifier = Modifier.weight(0.25f))
                    Spacer(Modifier.weight(0.15f))
                }
                HorizontalDivider(color = AppColors.border)

                // Set rows
                entry.setRows.forEachIndexed { setIdx, row ->
                    if (setIdx > 0) HorizontalDivider(color = AppColors.border, modifier = Modifier.padding(start = 16.dp))
                    SetEditorRow(
                        index = setIdx,
                        row = row,
                        canDelete = entry.setRows.size > 1,
                        onWeightChange = { newWeight ->
                            val updated = entry.setRows.toMutableList()
                            val old = updated[setIdx]
                            // Cascade identical values to subsequent rows
                            for (k in setIdx + 1 until updated.size) {
                                if (kotlin.math.abs(updated[k].weight - old.weight) < 0.001) updated[k] = updated[k].copy(weight = newWeight)
                                else break
                            }
                            updated[setIdx] = old.copy(weight = newWeight)
                            onUpdate(entry.copy(setRows = updated))
                        },
                        onRepsChange = { newReps ->
                            val updated = entry.setRows.toMutableList()
                            val old = updated[setIdx]
                            for (k in setIdx + 1 until updated.size) {
                                if (updated[k].reps == old.reps) updated[k] = updated[k].copy(reps = newReps)
                                else break
                            }
                            updated[setIdx] = old.copy(reps = newReps)
                            onUpdate(entry.copy(setRows = updated))
                        },
                        onDelete = {
                            if (entry.setRows.size > 1) {
                                onUpdate(entry.copy(setRows = entry.setRows.toMutableList().also { it.removeAt(setIdx) }))
                            }
                        },
                    )
                }

                HorizontalDivider(color = AppColors.border)

                // Add Set
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable {
                            val last = entry.setRows.lastOrNull()
                            onUpdate(entry.copy(setRows = entry.setRows + SetRow(weight = last?.weight ?: 0.0, reps = last?.reps ?: 10)))
                        }
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Default.Add, contentDescription = null, tint = AppColors.brand, modifier = Modifier.size(16.dp))
                    Text("Add Set", fontSize = 14.sp, fontWeight = FontWeight.Medium, color = AppColors.brand, modifier = Modifier.padding(start = 8.dp))
                }

                HorizontalDivider(color = AppColors.border)

                // Rest picker
                RestPicker(
                    restSeconds = entry.restSeconds,
                    onSelect = { onUpdate(entry.copy(restSeconds = it)) },
                )
            }
        }
    }
}

@Composable
private fun SetEditorRow(
    index: Int,
    row: SetRow,
    canDelete: Boolean,
    onWeightChange: (Double) -> Unit,
    onRepsChange: (Int) -> Unit,
    onDelete: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            "Set ${index + 1}",
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = AppColors.brand,
            modifier = Modifier.weight(0.15f),
        )
        Spacer(Modifier.weight(0.05f))

        // Weight input
        var weightText by remember(row.weight) { mutableStateOf(if (row.weight == 0.0) "" else row.weight.let { if (it % 1.0 == 0.0) "%.0f".format(it) else "%.1f".format(it) }) }
        CompactNumberField(
            value = weightText,
            onValueChange = { str ->
                weightText = str
                str.toDoubleOrNull()?.let { onWeightChange(it) }
            },
            modifier = Modifier.weight(0.30f),
            suffix = "kg",
        )
        Spacer(Modifier.weight(0.05f))

        // Reps input
        var repsText by remember(row.reps) { mutableStateOf(row.reps.toString()) }
        CompactNumberField(
            value = repsText,
            onValueChange = { str ->
                repsText = str
                str.toIntOrNull()?.let { onRepsChange(it) }
            },
            modifier = Modifier.weight(0.25f),
            suffix = "reps",
            isInteger = true,
        )
        Spacer(Modifier.weight(0.05f))

        IconButton(onClick = onDelete, enabled = canDelete, modifier = Modifier.size(32.dp)) {
            Icon(
                Icons.Default.Remove,
                contentDescription = "Remove set",
                tint = if (canDelete) AppColors.error else AppColors.textTertiary,
                modifier = Modifier.size(18.dp),
            )
        }
    }
}

@Composable
private fun CompactNumberField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    suffix: String = "",
    isInteger: Boolean = false,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = if (isInteger) KeyboardType.Number else KeyboardType.Decimal),
        placeholder = { Text("0", fontSize = 14.sp, color = AppColors.textTertiary, fontFamily = FontFamily.Monospace) },
        suffix = { Text(suffix, fontSize = 11.sp, color = AppColors.textTertiary) },
        modifier = modifier.height(48.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = AppColors.brand.copy(alpha = 0.4f),
            unfocusedBorderColor = AppColors.border,
            focusedContainerColor = AppColors.surface2,
            unfocusedContainerColor = AppColors.surface2,
            focusedTextColor = AppColors.text,
            unfocusedTextColor = AppColors.text,
        ),
        shape = RoundedCornerShape(8.dp),
    )
}

@Composable
private fun RestPicker(restSeconds: Int, onSelect: (Int) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    val label = restOptions.firstOrNull { it.first == restSeconds }?.second ?: "$restSeconds sec"
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("Rest", fontSize = 14.sp, color = AppColors.textSecondary, modifier = Modifier.weight(1f))
        Box {
            Text(label, fontSize = 14.sp, color = AppColors.brand, modifier = Modifier.clickable { expanded = true })
            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false },
                containerColor = AppColors.surface2,
            ) {
                restOptions.forEach { (seconds, display) ->
                    DropdownMenuItem(
                        text = { Text(display, color = AppColors.text) },
                        onClick = { onSelect(seconds); expanded = false },
                    )
                }
            }
        }
    }
}

@Composable
private fun EditorTextField(value: String, onValueChange: (String) -> Unit, placeholder: String) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = { Text(placeholder, color = AppColors.textTertiary) },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = Color.Transparent,
            unfocusedBorderColor = Color.Transparent,
            focusedContainerColor = Color.Transparent,
            unfocusedContainerColor = Color.Transparent,
            focusedTextColor = AppColors.text,
            unfocusedTextColor = AppColors.text,
        ),
    )
}

@Composable
private fun SectionHeader(text: String) {
    Text(text.uppercase(), fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.textSecondary, letterSpacing = 0.7.sp)
}

// Carries existing template data into the editor
data class ExistingTemplateData(
    val name: String,
    val description: String,
    val entries: List<ExerciseEntry>,
)
