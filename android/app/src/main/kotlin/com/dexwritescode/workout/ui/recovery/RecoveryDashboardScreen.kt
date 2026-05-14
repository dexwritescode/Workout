package com.dexwritescode.workout.ui.recovery

import android.app.Application
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.dexwritescode.workout.ui.theme.AppColors

@Composable
fun RecoveryDashboardScreen() {
    val app = LocalContext.current.applicationContext as Application
    val vm: RecoveryViewModel = viewModel(factory = RecoveryViewModel.Factory(app))
    val state by vm.uiState.collectAsState()

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.background)
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
        contentPadding = PaddingValues(bottom = 32.dp),
    ) {
        item {
            Column(modifier = Modifier.padding(top = 16.dp)) {
                Text(
                    "TODAY",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    color = AppColors.textTertiary,
                    letterSpacing = 0.6.sp,
                )
                Text(
                    "Recovery",
                    fontSize = 26.sp,
                    fontWeight = FontWeight.Black,
                    color = AppColors.text,
                )
            }
        }

        if (!state.hasEverWorkedOut) {
            item { EmptyState() }
        } else {
            item { StatsRow(state) }
            if (state.upperBody.isNotEmpty()) {
                item { MuscleSection("Upper Body", state.upperBody) }
            }
            if (state.lowerBody.isNotEmpty()) {
                item { MuscleSection("Lower Body", state.lowerBody) }
            }
        }
    }
}

@Composable
private fun EmptyState() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 64.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(
            Icons.Default.Favorite,
            contentDescription = null,
            modifier = Modifier.size(40.dp),
            tint = AppColors.textTertiary,
        )
        Text("No Recovery Data", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
        Text(
            "Complete a workout to start tracking muscle recovery.",
            fontSize = 14.sp,
            color = AppColors.textTertiary,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun StatsRow(state: RecoveryUiState) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        StatCard(
            value = state.daysSinceLastWorkout?.toString() ?: "—",
            label = "Days since last\nworkout",
            valueColor = AppColors.text,
            modifier = Modifier.weight(1f),
        )
        StatCard(
            value = "${(state.overallRecovery * 100).toInt()}%",
            label = "Overall\nrecovery",
            valueColor = RecoveryViewModel.recoveryColor(state.overallRecovery),
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun StatCard(
    value: String,
    label: String,
    valueColor: Color,
    modifier: Modifier = Modifier,
) {
    Surface(
        modifier = modifier.border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
        shape = RoundedCornerShape(AppColors.radiusCard.dp),
        color = AppColors.surface1,
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Text(value, fontSize = 28.sp, fontWeight = FontWeight.Black, color = valueColor)
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                label,
                fontSize = 10.sp,
                fontWeight = FontWeight.SemiBold,
                color = AppColors.textTertiary,
                letterSpacing = 0.6.sp,
                lineHeight = 14.sp,
            )
        }
    }
}

@Composable
private fun MuscleSection(title: String, rows: List<MuscleRowUiState>) {
    Column {
        Text(
            title.uppercase(),
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            color = AppColors.textSecondary,
            letterSpacing = 0.7.sp,
            modifier = Modifier.padding(bottom = 8.dp),
        )
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
            shape = RoundedCornerShape(AppColors.radiusCard.dp),
            color = AppColors.surface1,
        ) {
            Column {
                rows.forEachIndexed { index, row ->
                    MuscleRow(row)
                    if (index < rows.lastIndex) {
                        HorizontalDivider(
                            color = AppColors.border,
                            modifier = Modifier.padding(start = 64.dp),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MuscleRow(row: MuscleRowUiState) {
    val animatedPct by animateFloatAsState(
        targetValue = row.recoveryPct,
        animationSpec = tween(durationMillis = 800),
        label = "recovery_${row.name}",
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            "${(row.recoveryPct * 100).toInt()}%",
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = AppColors.textSecondary,
            modifier = Modifier.width(36.dp),
        )
        Spacer(modifier = Modifier.width(8.dp))
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(row.name, fontSize = 14.sp, fontWeight = FontWeight.Medium, color = AppColors.text)
                Text(row.statusLabel, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = row.color)
            }
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(AppColors.surface3),
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(animatedPct)
                        .fillMaxHeight()
                        .clip(RoundedCornerShape(2.dp))
                        .background(row.color),
                )
            }
        }
    }
}
