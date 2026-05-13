package com.dexwritescode.workout.ui.workout

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.dexwritescode.workout.data.model.entity.UserSettings
import com.dexwritescode.workout.data.model.enums.WeightUnit
import com.dexwritescode.workout.ui.theme.AppColors
import kotlinx.coroutines.flow.Flow
import kotlin.math.abs

@Composable
fun PlateCalculatorSheet(
    targetWeight: Double,
    settingsFlow: Flow<List<UserSettings>>,
    onDismiss: () -> Unit,
) {
    val settingsList by settingsFlow.collectAsState(initial = emptyList())
    val settings = settingsList.firstOrNull()
    val isKg = settings?.unit == WeightUnit.KG
    val barbellWeight = if (isKg) settings?.barbellWeightKg ?: 20.0 else settings?.barbellWeightLbs ?: 45.0
    val availablePlates = (if (isKg) settings?.availablePlatesKg else settings?.availablePlatesLbs)
        ?.sortedDescending()
        ?: if (isKg) listOf(25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25) else listOf(45.0, 35.0, 25.0, 10.0, 5.0, 2.5, 1.25)
    val unitLabel = if (isKg) "kg" else "lbs"

    val platesPerSide = calculatePlatesPerSide(targetWeight, barbellWeight, availablePlates)
    val loadedWeight = barbellWeight + platesPerSide.sumOf { it.first * it.second } * 2

    Surface(color = AppColors.background, modifier = Modifier.fillMaxSize()) {
        Column {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Plate Calculator", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
                TextButton(onClick = onDismiss) {
                    Text("Done", color = AppColors.brand, fontWeight = FontWeight.Bold)
                }
            }

            HorizontalDivider(color = AppColors.border)

            // Target vs Loaded header
            Row(modifier = Modifier.fillMaxWidth().padding(20.dp)) {
                Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "${formatWeight(targetWeight)} $unitLabel",
                        fontSize = 32.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = AppColors.text,
                    )
                    Text("target", fontSize = 12.sp, color = AppColors.textTertiary)
                }
                Text("→", fontSize = 20.sp, color = AppColors.textTertiary, modifier = Modifier.align(Alignment.CenterVertically))
                Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "${formatWeight(loadedWeight)} $unitLabel",
                        fontSize = 32.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = if (abs(loadedWeight - targetWeight) < 0.01) AppColors.brand else AppColors.textSecondary,
                    )
                    Text("loaded", fontSize = 12.sp, color = AppColors.textTertiary)
                }
            }

            HorizontalDivider(color = AppColors.border)

            Column(modifier = Modifier.verticalScroll(rememberScrollState()).padding(20.dp)) {
                if (platesPerSide.isEmpty()) {
                    // Just the bar
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 60.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Text("Just the bar", fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text)
                        Text(
                            "Target weight equals the barbell — no plates needed.",
                            fontSize = 14.sp,
                            color = AppColors.textSecondary,
                        )
                    }
                } else {
                    // Bar visualization
                    BarVisualization(platesPerSide = platesPerSide)

                    Spacer(Modifier.height(16.dp))

                    // Plate list
                    Row(modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp, start = 4.dp)) {
                        Text(
                            "Per side",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = AppColors.textSecondary,
                            letterSpacing = 0.7.sp,
                            modifier = Modifier.weight(1f),
                        )
                        Text(
                            "Bar: ${formatWeight(barbellWeight)} $unitLabel",
                            fontSize = 12.sp,
                            color = AppColors.textTertiary,
                        )
                    }

                    Surface(
                        shape = RoundedCornerShape(AppColors.radiusCard.dp),
                        color = AppColors.surface1,
                        modifier = Modifier
                            .fillMaxWidth()
                            .border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp)),
                    ) {
                        Column {
                            platesPerSide.forEachIndexed { index, (plate, count) ->
                                if (index > 0) HorizontalDivider(color = AppColors.border, modifier = Modifier.padding(start = 16.dp))
                                PlateRow(plate = plate, count = count, unitLabel = unitLabel)
                            }
                        }
                    }

                    if (abs(loadedWeight - targetWeight) > 0.01) {
                        Spacer(Modifier.height(12.dp))
                        Text(
                            "Nearest loadable weight is ${formatWeight(loadedWeight)} $unitLabel",
                            fontSize = 13.sp,
                            color = AppColors.textTertiary,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun BarVisualization(platesPerSide: List<Pair<Double, Int>>) {
    Surface(
        shape = RoundedCornerShape(AppColors.radiusCard.dp),
        color = AppColors.surface1,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, AppColors.border, RoundedCornerShape(AppColors.radiusCard.dp))
            .height(88.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxSize().padding(16.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // Left plates (reversed)
            Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                platesPerSide.reversed().forEach { (plate, count) ->
                    repeat(count) { PlateSlice(plateKg = plate) }
                }
            }
            // Bar
            Box(
                modifier = Modifier
                    .width(40.dp)
                    .height(8.dp)
                    .background(AppColors.textTertiary.copy(alpha = 0.4f), RoundedCornerShape(2.dp))
            )
            // Right plates
            Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                platesPerSide.forEach { (plate, count) ->
                    repeat(count) { PlateSlice(plateKg = plate) }
                }
            }
        }
    }
}

@Composable
private fun PlateSlice(plateKg: Double) {
    val height = when {
        plateKg >= 25 -> 48.dp
        plateKg >= 20 -> 42.dp
        plateKg >= 15 -> 36.dp
        plateKg >= 10 -> 30.dp
        plateKg >= 5  -> 24.dp
        else          -> 18.dp
    }
    val color = when {
        plateKg >= 25 -> Color(0xFFD92626)
        plateKg >= 20 -> Color(0xFF1A73D9)
        plateKg >= 15 -> Color(0xFFE6B300)
        plateKg >= 10 -> Color(0xFF339952)
        plateKg >= 5  -> Color(0xFF8C8C99)
        else          -> Color(0xFFCCBFB3)
    }
    Box(
        modifier = Modifier
            .width(10.dp)
            .height(height)
            .background(color, RoundedCornerShape(2.dp))
    )
}

@Composable
private fun PlateRow(plate: Double, count: Int, unitLabel: String) {
    val color = when {
        plate >= 25 -> Color(0xFFD92626)
        plate >= 20 -> Color(0xFF1A73D9)
        plate >= 15 -> Color(0xFFE6B300)
        plate >= 10 -> Color(0xFF339952)
        plate >= 5  -> Color(0xFF8C8C99)
        else        -> Color(0xFFCCBFB3)
    }
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(modifier = Modifier.size(12.dp).background(color, CircleShape))
        Spacer(Modifier.width(8.dp))
        Text("${formatWeight(plate)} $unitLabel", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = AppColors.text, modifier = Modifier.weight(1f))
        Text("× $count", fontFamily = FontFamily.Monospace, fontSize = 15.sp, color = AppColors.textSecondary)
        Spacer(Modifier.width(8.dp))
        Text("= ${formatWeight(plate * count)} $unitLabel", fontSize = 13.sp, color = AppColors.textTertiary, modifier = Modifier.width(72.dp))
    }
}

private fun calculatePlatesPerSide(target: Double, barbell: Double, plates: List<Double>): List<Pair<Double, Int>> {
    var remaining = maxOf(0.0, (target - barbell) / 2)
    val result = mutableListOf<Pair<Double, Int>>()
    for (plate in plates.sortedDescending()) {
        val count = (remaining / plate).toInt()
        if (count > 0) {
            result.add(plate to count)
            remaining -= count * plate
        }
    }
    return result
}

private fun formatWeight(value: Double): String =
    if (value % 1.0 == 0.0) "%.0f".format(value) else "%.2g".format(value)

// Pure logic exposed for tests
fun platesPerSideFor(target: Double, barbell: Double, plates: List<Double>): List<Pair<Double, Int>> =
    calculatePlatesPerSide(target, barbell, plates)
