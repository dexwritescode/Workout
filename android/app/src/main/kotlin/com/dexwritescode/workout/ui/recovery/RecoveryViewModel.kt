package com.dexwritescode.workout.ui.recovery

import android.app.Application
import androidx.compose.ui.graphics.Color
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.dexwritescode.workout.data.db.AppDatabase
import com.dexwritescode.workout.data.model.enums.MuscleCategory
import com.dexwritescode.workout.data.services.recovery.RecoveryEngine
import com.dexwritescode.workout.ui.theme.AppColors
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.stateIn
import kotlin.math.roundToInt

data class MuscleRowUiState(
    val name: String,
    val recoveryPct: Float,
    val statusLabel: String,
    val color: Color,
)

data class RecoveryUiState(
    val upperBody: List<MuscleRowUiState> = emptyList(),
    val lowerBody: List<MuscleRowUiState> = emptyList(),
    val overallRecovery: Double = 0.0,
    val daysSinceLastWorkout: Int? = null,
    val hasEverWorkedOut: Boolean = false,
)

class RecoveryViewModel(application: Application) : AndroidViewModel(application) {

    private val dao = AppDatabase.getInstance(application).muscleRecoveryStateDao()

    private val tickerFlow = flow {
        while (true) { emit(Unit); delay(60_000) }
    }

    val uiState = combine(dao.getAll(), tickerFlow) { states, _ ->
        if (states.isEmpty()) return@combine RecoveryUiState()

        val nowMs = System.currentTimeMillis()
        val rows = states.mapNotNull { state ->
            val muscle = state.muscle ?: return@mapNotNull null
            val rawPct = RecoveryEngine.currentRecoveryPercentage(state, nowMs)
            val pct = (rawPct * 100).roundToInt() / 100.0
            Pair(
                MuscleRowUiState(
                    name = muscle.rawValue,
                    recoveryPct = pct.toFloat(),
                    statusLabel = statusLabel(pct),
                    color = recoveryColor(pct),
                ),
                muscle,
            )
        }

        val upperBody = rows
            .filter { (_, m) -> m.category == MuscleCategory.UPPER_BODY }
            .sortedBy { (_, m) -> m.rawValue }
            .map { (row, _) -> row }

        val lowerBody = rows
            .filter { (_, m) -> m.category == MuscleCategory.LOWER_BODY }
            .sortedBy { (_, m) -> m.rawValue }
            .map { (row, _) -> row }

        val overallRecovery = if (rows.isEmpty()) 1.0
            else rows.map { (row, _) -> row.recoveryPct.toDouble() }.average()

        val daysSinceLastWorkout = states
            .maxOfOrNull { it.lastWorkedDate }
            ?.let { latestMs -> ((nowMs - latestMs) / 86_400_000L).toInt() }

        RecoveryUiState(
            upperBody = upperBody,
            lowerBody = lowerBody,
            overallRecovery = overallRecovery,
            daysSinceLastWorkout = daysSinceLastWorkout,
            hasEverWorkedOut = true,
        )
    }
        .flowOn(Dispatchers.Default)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), RecoveryUiState())

    companion object {
        fun statusLabel(pct: Double): String = when {
            pct >= 0.75 -> "Recovered"
            pct >= 0.50 -> "Recovering"
            else -> "Fatigued"
        }

        fun recoveryColor(pct: Double): Color = when {
            pct >= 0.75 -> AppColors.success
            pct >= 0.25 -> AppColors.warning
            else -> AppColors.error
        }
    }

    class Factory(private val application: Application) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            RecoveryViewModel(application) as T
    }
}
