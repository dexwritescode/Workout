package com.dexwritescode.workout

import com.dexwritescode.workout.ui.workout.platesPerSideFor
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

class PlateCalculatorTest {

    private val standardPlates = listOf(25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25)
    private val barbell = 20.0

    @Test
    fun `just the bar returns empty list`() {
        val result = platesPerSideFor(target = 20.0, barbell = barbell, plates = standardPlates)
        assertTrue(result.isEmpty())
    }

    @Test
    fun `target below barbell returns empty list`() {
        val result = platesPerSideFor(target = 10.0, barbell = barbell, plates = standardPlates)
        assertTrue(result.isEmpty())
    }

    @Test
    fun `100kg loads correct plates per side`() {
        // (100 - 20) / 2 = 40 per side → greedy: 1×25 + 1×15
        val result = platesPerSideFor(target = 100.0, barbell = barbell, plates = standardPlates)
        val loaded = barbell + result.sumOf { it.first * it.second } * 2
        assertEquals(100.0, loaded, 0.001)
    }

    @Test
    fun `60kg loads one 20kg per side`() {
        val result = platesPerSideFor(target = 60.0, barbell = barbell, plates = standardPlates)
        val loaded = barbell + result.sumOf { it.first * it.second } * 2
        assertEquals(60.0, loaded, 0.001)
    }

    @Test
    fun `102_5kg loads correct combination`() {
        // (102.5 - 20) / 2 = 41.25 per side → 1×25 + 1×10 + 1×5 + 1×1.25 = 41.25
        val result = platesPerSideFor(target = 102.5, barbell = barbell, plates = standardPlates)
        val loaded = barbell + result.sumOf { it.first * it.second } * 2
        assertEquals(102.5, loaded, 0.001)
    }

    @Test
    fun `greedy algorithm uses largest plates first`() {
        val result = platesPerSideFor(target = 70.0, barbell = barbell, plates = standardPlates)
        // (70 - 20) / 2 = 25 per side → one 25kg plate
        assertEquals(1, result.size)
        assertEquals(25.0, result[0].first, 0.001)
        assertEquals(1, result[0].second)
    }

    @Test
    fun `result plates are always sorted largest first`() {
        val result = platesPerSideFor(target = 120.0, barbell = barbell, plates = standardPlates)
        val plateWeights = result.map { it.first }
        assertEquals(plateWeights.sortedDescending(), plateWeights)
    }

    @Test
    fun `loaded weight never exceeds target by more than smallest plate times 2`() {
        listOf(60.0, 80.0, 100.0, 102.5, 120.0, 140.0, 185.0).forEach { target ->
            val result = platesPerSideFor(target = target, barbell = barbell, plates = standardPlates)
            val loaded = barbell + result.sumOf { it.first * it.second } * 2
            val overshoot = loaded - target
            assertTrue("Overshoot $overshoot for target $target", overshoot <= 0.001)
        }
    }

    @Test
    fun `custom plates are used when provided`() {
        val customPlates = listOf(45.0, 25.0, 10.0, 5.0, 2.5)
        val result = platesPerSideFor(target = 115.0, barbell = 20.0, plates = customPlates)
        val loaded = 20.0 + result.sumOf { it.first * it.second } * 2
        // (115 - 20) / 2 = 47.5 per side → 1×45 + 2×1.25? Wait, 47.5 → 1×45 = 45, remaining 2.5 → 1×2.5
        // 20 + (45 + 2.5) * 2 = 20 + 95 = 115
        assertEquals(115.0, loaded, 0.001)
    }
}
