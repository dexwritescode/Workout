package com.dexwritescode.workout.ui.workout

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.enums.DifficultyLevel
import com.dexwritescode.workout.ui.theme.AppColors
import kotlinx.coroutines.flow.Flow

@Composable
fun ExercisePickerSheet(
    exercisesFlow: Flow<List<Exercise>>,
    onSelect: (Exercise) -> Unit,
    onDismiss: () -> Unit,
) {
    val allExercises by exercisesFlow.collectAsState(initial = emptyList())
    var query by remember { mutableStateOf("") }

    val filtered = remember(query, allExercises) {
        if (query.isBlank()) allExercises
        else {
            val q = query.lowercase()
            allExercises.filter { ex ->
                ex.name.lowercase().contains(q) ||
                    ex.primaryMuscleGroups.any { it.rawValue.lowercase().contains(q) } ||
                    ex.equipment.any { it.lowercase().contains(q) }
            }
        }
    }

    val grouped = remember(filtered) {
        filtered.groupBy { it.primaryMuscleGroups.firstOrNull()?.rawValue ?: "Other" }
            .entries.sortedBy { it.key }
    }

    Surface(color = AppColors.background, modifier = Modifier.fillMaxSize()) {
        Column {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Add Exercise",
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.text,
                    modifier = Modifier.weight(1f),
                )
                Text(
                    text = "Cancel",
                    fontSize = 15.sp,
                    color = AppColors.textSecondary,
                    modifier = Modifier.clickable { onDismiss() },
                )
            }

            // Search bar
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp)
                    .border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusMedium.dp)),
                shape = RoundedCornerShape(AppColors.radiusMedium.dp),
                color = AppColors.surface2,
            ) {
                TextField(
                    value = query,
                    onValueChange = { query = it },
                    placeholder = {
                        Text("Search exercises", color = AppColors.textTertiary, fontSize = 16.sp)
                    },
                    leadingIcon = {
                        Icon(Icons.Default.Search, contentDescription = null, tint = AppColors.textTertiary)
                    },
                    trailingIcon = if (query.isNotEmpty()) {
                        { IconButton(onClick = { query = "" }) {
                            Icon(Icons.Default.Clear, contentDescription = null, tint = AppColors.textTertiary)
                        }}
                    } else null,
                    singleLine = true,
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = Color.Transparent,
                        unfocusedContainerColor = Color.Transparent,
                        focusedTextColor = AppColors.text,
                        unfocusedTextColor = AppColors.text,
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                    ),
                )
            }

            if (filtered.isEmpty()) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 60.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text("No exercises found", fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
                    Text("Try a different search term.", fontSize = 14.sp, color = AppColors.textSecondary)
                }
            } else {
                LazyColumn(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                    grouped.forEach { (muscleName, exercises) ->
                        item {
                            Text(
                                text = muscleName.uppercase(),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = AppColors.textSecondary,
                                letterSpacing = 0.7.sp,
                                modifier = Modifier.padding(top = 16.dp, bottom = 8.dp, start = 4.dp),
                            )
                        }
                        item {
                            Surface(
                                shape = RoundedCornerShape(AppColors.radiusCard.dp),
                                color = AppColors.surface1,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
                            ) {
                                Column {
                                    exercises.forEachIndexed { index, exercise ->
                                        if (index > 0) HorizontalDivider(color = AppColors.border, modifier = Modifier.padding(start = 16.dp))
                                        ExercisePickerRow(exercise = exercise, onSelect = onSelect)
                                    }
                                }
                            }
                        }
                        item { Spacer(Modifier.size(12.dp)) }
                    }
                }
            }
        }
    }
}

@Composable
private fun ExercisePickerRow(exercise: Exercise, onSelect: (Exercise) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onSelect(exercise) }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(exercise.name, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(top = 3.dp),
            ) {
                DifficultyBadge(exercise.difficulty)
                if (exercise.equipment.isNotEmpty()) {
                    Text(
                        text = exercise.equipment.take(2).joinToString(", "),
                        fontSize = 11.sp,
                        color = AppColors.textTertiary,
                    )
                }
            }
        }
        Icon(
            imageVector = Icons.Default.Add,
            contentDescription = "Add",
            tint = AppColors.brand,
            modifier = Modifier.size(22.dp),
        )
    }
}

@Composable
fun DifficultyBadge(level: DifficultyLevel) {
    val color = when (level) {
        DifficultyLevel.BEGINNER -> AppColors.success
        DifficultyLevel.INTERMEDIATE -> AppColors.warning
        DifficultyLevel.ADVANCED -> AppColors.error
    }
    Surface(
        shape = RoundedCornerShape(5.dp),
        color = color.copy(alpha = 0.13f),
    ) {
        Text(
            text = level.rawValue,
            fontSize = 10.sp,
            fontWeight = FontWeight.SemiBold,
            color = color,
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
        )
    }
}
