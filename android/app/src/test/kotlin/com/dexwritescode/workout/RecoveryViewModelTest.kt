package com.dexwritescode.workout

import androidx.compose.ui.graphics.Color
import com.dexwritescode.workout.ui.recovery.RecoveryViewModel
import com.dexwritescode.workout.ui.theme.AppColors
import org.junit.Assert.assertEquals
import org.junit.Test

class RecoveryViewModelTest {

    // MARK: - statusLabel

    @Test
    fun `statusLabel at 100 percent is Recovered`() {
        assertEquals("Recovered", RecoveryViewModel.statusLabel(1.0))
    }

    @Test
    fun `statusLabel at 75 percent boundary is Recovered`() {
        assertEquals("Recovered", RecoveryViewModel.statusLabel(0.75))
    }

    @Test
    fun `statusLabel just below 75 percent is Recovering`() {
        assertEquals("Recovering", RecoveryViewModel.statusLabel(0.74))
    }

    @Test
    fun `statusLabel at 50 percent boundary is Recovering`() {
        assertEquals("Recovering", RecoveryViewModel.statusLabel(0.50))
    }

    @Test
    fun `statusLabel just below 50 percent is Fatigued`() {
        assertEquals("Fatigued", RecoveryViewModel.statusLabel(0.49))
    }

    @Test
    fun `statusLabel at 0 percent is Fatigued`() {
        assertEquals("Fatigued", RecoveryViewModel.statusLabel(0.0))
    }

    // MARK: - recoveryColor

    @Test
    fun `recoveryColor at 100 percent is success`() {
        assertEquals(AppColors.success, RecoveryViewModel.recoveryColor(1.0))
    }

    @Test
    fun `recoveryColor at 75 percent is success`() {
        assertEquals(AppColors.success, RecoveryViewModel.recoveryColor(0.75))
    }

    @Test
    fun `recoveryColor at 60 percent is warning`() {
        assertEquals(AppColors.warning, RecoveryViewModel.recoveryColor(0.60))
    }

    @Test
    fun `recoveryColor at 25 percent is warning`() {
        assertEquals(AppColors.warning, RecoveryViewModel.recoveryColor(0.25))
    }

    @Test
    fun `recoveryColor below 25 percent is error`() {
        assertEquals(AppColors.error, RecoveryViewModel.recoveryColor(0.24))
    }

    @Test
    fun `recoveryColor at 0 percent is error`() {
        assertEquals(AppColors.error, RecoveryViewModel.recoveryColor(0.0))
    }
}
