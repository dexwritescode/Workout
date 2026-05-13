package com.dexwritescode.workout.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    background = AppColors.background,
    surface = AppColors.surface1,
    surfaceVariant = AppColors.surface2,
    primary = AppColors.brand,
    onPrimary = AppColors.text,
    onBackground = AppColors.text,
    onSurface = AppColors.text,
    outline = AppColors.border,
    error = AppColors.error,
)

@Composable
fun WorkoutTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        content = content
    )
}
