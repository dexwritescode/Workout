package com.dexwritescode.workout.ui.theme

import androidx.compose.ui.graphics.Color

object AppColors {
    // Surfaces
    val background = Color(0xFF0C0C0E)
    val surface1 = Color(0xFF141416)
    val surface2 = Color(0xFF1C1C1F)
    val surface3 = Color(0xFF252528)

    // Text
    val text = Color(0xFFF0F0F3)
    val textSecondary = Color(0xFF86868F)
    val textTertiary = Color(0xFF55555C)

    // Borders
    val border = Color.White.copy(alpha = 0.07f)
    val borderStrong = Color.White.copy(alpha = 0.12f)

    // Brand (Forge theme)
    val brand = Color(0xFFFF8C32)

    // Smart Workout gradient end colour
    val brandGradientEnd = Color(0xFFCC3520)

    // Semantic
    val success = Color(0xFF34C76A)
    val error = Color(0xFFFF4444)
    val warning = Color(0xFFF5A623)

    // Exercise type badges
    val compound = Color(0xFF50A0FF)
    val isolation = Color(0xFFA070FF)

    // Radius values (dp)
    const val radiusSmall = 8
    const val radiusMedium = 12
    const val radiusCard = 14
    const val radiusLarge = 16
}
