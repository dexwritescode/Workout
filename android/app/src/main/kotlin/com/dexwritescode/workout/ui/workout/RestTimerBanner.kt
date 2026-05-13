package com.dexwritescode.workout.ui.workout

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dexwritescode.workout.ui.theme.AppColors
import kotlinx.coroutines.delay

@Composable
fun RestTimerBanner(
    endTimeMs: Long,
    onComplete: () -> Unit,
    onSkip: () -> Unit,
    onAdjust: (Long) -> Unit,
    modifier: Modifier = Modifier,
) {
    var remainingSeconds by remember(endTimeMs) {
        mutableLongStateOf(maxOf(0L, (endTimeMs - System.currentTimeMillis()) / 1000))
    }

    LaunchedEffect(endTimeMs) {
        while (true) {
            val remaining = (endTimeMs - System.currentTimeMillis()) / 1000
            if (remaining <= 0) {
                remainingSeconds = 0
                onComplete()
                break
            }
            remainingSeconds = remaining
            delay(500)
        }
    }

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                color = AppColors.brand.copy(alpha = 0.2f),
                shape = RoundedCornerShape(AppColors.radiusCard.dp),
            ),
        shape = RoundedCornerShape(AppColors.radiusCard.dp),
        color = AppColors.brand.copy(alpha = 0.08f),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 18.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column {
                Text(
                    text = "REST",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.textSecondary,
                    letterSpacing = 0.7.sp,
                )
                Text(
                    text = formatRestTime(remainingSeconds),
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace,
                    color = AppColors.brand,
                )
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TimerChip(label = "−10s") { onAdjust(-10_000L) }
                TimerChip(label = "+10s") { onAdjust(10_000L) }
                TimerChip(label = "Skip") { onSkip() }
            }
        }
    }
}

@Composable
private fun TimerChip(label: String, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        colors = ButtonDefaults.buttonColors(
            containerColor = AppColors.surface3,
            contentColor = AppColors.textSecondary,
        ),
        shape = RoundedCornerShape(10.dp),
    ) {
        Text(text = label, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
    }
}

private fun formatRestTime(seconds: Long): String {
    val m = seconds / 60
    val s = seconds % 60
    return "%d:%02d".format(m, s)
}
