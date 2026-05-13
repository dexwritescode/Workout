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
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dexwritescode.workout.data.model.entity.WorkoutTemplate
import com.dexwritescode.workout.ui.theme.AppColors
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale
import java.util.concurrent.TimeUnit

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TemplatePickerScreen(
    templatesFlow: Flow<List<WorkoutTemplate>>,
    onSmartWorkout: () -> Unit,
    onTemplateSelected: (WorkoutTemplate) -> Unit,
    onCreateTemplate: () -> Unit,
    onEditTemplate: (WorkoutTemplate) -> Unit,
    onDeleteTemplate: (WorkoutTemplate) -> Unit,
) {
    val templates by templatesFlow.collectAsState(initial = emptyList())
    var templateToDelete by remember { mutableStateOf<WorkoutTemplate?>(null) }

    Surface(color = AppColors.background, modifier = Modifier.fillMaxSize()) {
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            // Header
            item {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text(
                            text = dayOfWeek().uppercase(),
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium,
                            color = AppColors.textTertiary,
                            letterSpacing = 0.6.sp,
                        )
                        Text("Workouts", fontSize = 26.sp, fontWeight = FontWeight.ExtraBold, color = AppColors.text)
                    }
                    IconButton(onClick = onCreateTemplate) {
                        Icon(Icons.Default.Add, contentDescription = "New template", tint = AppColors.brand)
                    }
                }
            }

            // Smart Workout card
            item {
                SmartWorkoutCard(
                    onClick = onSmartWorkout,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                )
            }

            if (templates.isEmpty()) {
                item {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 60.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Icon(
                            imageVector = Icons.Default.FitnessCenter,
                            contentDescription = null,
                            tint = AppColors.textTertiary,
                            modifier = Modifier.size(40.dp),
                        )
                        Text("No Templates Yet", fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
                        Text(
                            "Tap + to create your first workout template",
                            fontSize = 14.sp,
                            color = AppColors.textSecondary,
                        )
                    }
                }
            } else {
                item {
                    Text(
                        text = "MY TEMPLATES",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = AppColors.textSecondary,
                        letterSpacing = 0.7.sp,
                        modifier = Modifier.padding(start = 16.dp, top = 8.dp, bottom = 10.dp),
                    )
                }
                items(templates, key = { it.id }) { template ->
                    val dismissState = rememberSwipeToDismissBoxState(
                        confirmValueChange = { value ->
                            when (value) {
                                SwipeToDismissBoxValue.EndToStart -> {
                                    templateToDelete = template
                                    false // don't auto-dismiss; wait for dialog
                                }
                                SwipeToDismissBoxValue.StartToEnd -> {
                                    onEditTemplate(template)
                                    false
                                }
                                else -> false
                            }
                        }
                    )
                    SwipeToDismissBox(
                        state = dismissState,
                        backgroundContent = {
                            val isEnd = dismissState.dismissDirection == SwipeToDismissBoxValue.EndToStart
                            val isStart = dismissState.dismissDirection == SwipeToDismissBoxValue.StartToEnd
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .padding(horizontal = 16.dp, vertical = 4.dp)
                                    .clip(RoundedCornerShape(AppColors.radiusCard.dp))
                                    .background(if (isEnd) AppColors.error.copy(alpha = 0.15f) else if (isStart) AppColors.brand.copy(alpha = 0.15f) else Color.Transparent),
                                contentAlignment = if (isEnd) Alignment.CenterEnd else Alignment.CenterStart,
                            ) {
                                if (isEnd) Icon(Icons.Default.Delete, contentDescription = "Delete", tint = AppColors.error, modifier = Modifier.padding(end = 24.dp))
                                if (isStart) Icon(Icons.Default.Edit, contentDescription = "Edit", tint = AppColors.brand, modifier = Modifier.padding(start = 24.dp))
                            }
                        },
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
                    ) {
                        TemplateRow(
                            template = template,
                            onClick = { onTemplateSelected(template) },
                        )
                    }
                }
                item { Spacer(Modifier.height(16.dp)) }
            }
        }
    }

    templateToDelete?.let { template ->
        AlertDialog(
            onDismissRequest = { templateToDelete = null },
            containerColor = AppColors.surface2,
            title = { Text("Delete \"${template.name}\"?", color = AppColors.text) },
            text = { Text("This cannot be undone.", color = AppColors.textSecondary) },
            confirmButton = {
                TextButton(onClick = {
                    onDeleteTemplate(template)
                    templateToDelete = null
                }) { Text("Delete", color = AppColors.error) }
            },
            dismissButton = {
                TextButton(onClick = { templateToDelete = null }) { Text("Cancel", color = AppColors.textSecondary) }
            },
        )
    }
}

@Composable
private fun SmartWorkoutCard(onClick: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(AppColors.radiusLarge.dp))
            .background(Brush.linearGradient(listOf(AppColors.brand, AppColors.brandGradientEnd)))
            .clickable { onClick() }
            .padding(horizontal = 20.dp, vertical = 18.dp),
    ) {
        // Decorative circles
        Box(
            modifier = Modifier
                .size(100.dp)
                .offset(x = 20.dp, y = (-20).dp)
                .background(Color.White.copy(alpha = 0.08f), CircleShape)
                .align(Alignment.TopEnd)
        )
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("✦", fontSize = 16.sp, color = Color.White.copy(alpha = 0.95f))
                Text("Smart Workout", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.95f))
            }
            Text("AI-generated based on your recovery", fontSize = 14.sp, color = Color.White.copy(alpha = 0.7f))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(top = 6.dp)) {
                SmartWorkoutPill("Push Day")
                SmartWorkoutPill("~44 min")
                SmartWorkoutPill("5 exercises")
            }
        }
    }
}

@Composable
private fun SmartWorkoutPill(text: String) {
    Surface(shape = RoundedCornerShape(8.dp), color = Color.Black.copy(alpha = 0.2f)) {
        Text(text, fontSize = 11.sp, fontWeight = FontWeight.Medium, color = Color.White.copy(alpha = 0.85f), modifier = Modifier.padding(horizontal = 10.dp, vertical = 3.dp))
    }
}

@Composable
private fun TemplateRow(template: WorkoutTemplate, onClick: () -> Unit) {
    Surface(
        shape = RoundedCornerShape(AppColors.radiusCard.dp),
        color = AppColors.surface1,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp))
            .clickable { onClick() },
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // Icon
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(AppColors.brand.copy(alpha = 0.1f))
                    .border(1.dp, AppColors.brand.copy(alpha = 0.2f), RoundedCornerShape(12.dp)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Default.FitnessCenter, contentDescription = null, tint = AppColors.brand, modifier = Modifier.size(18.dp))
            }

            Spacer(Modifier.width(14.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(template.name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
                if (template.templateDescription.isNotEmpty()) {
                    Text(
                        template.templateDescription,
                        fontSize = 13.sp,
                        color = AppColors.textSecondary,
                        maxLines = 1,
                    )
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.padding(top = 3.dp)) {
                    template.lastUsedDate?.let { lastUsed ->
                        Text(relativeTime(lastUsed), fontSize = 11.sp, color = AppColors.textTertiary)
                    }
                }
            }
        }
    }
}

private fun dayOfWeek(): String =
    LocalDate.now().dayOfWeek.getDisplayName(TextStyle.FULL, Locale.getDefault())

private fun relativeTime(ms: Long): String {
    val diff = System.currentTimeMillis() - ms
    val days = TimeUnit.MILLISECONDS.toDays(diff)
    return when {
        days == 0L -> "Today"
        days == 1L -> "Yesterday"
        days < 7   -> "$days days ago"
        else       -> "${days / 7} weeks ago"
    }
}
