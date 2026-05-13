package com.dexwritescode.workout.ui.workout

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.dexwritescode.workout.data.db.dao.CompletedExerciseDao
import com.dexwritescode.workout.data.db.dao.ExerciseDao
import com.dexwritescode.workout.data.db.dao.ExerciseSetDao
import com.dexwritescode.workout.data.db.dao.MuscleRecoveryStateDao
import com.dexwritescode.workout.data.db.dao.TemplateExerciseDao
import com.dexwritescode.workout.data.db.dao.TemplateSetDao
import com.dexwritescode.workout.data.db.dao.WorkoutSessionDao
import com.dexwritescode.workout.data.db.dao.WorkoutTemplateDao
import com.dexwritescode.workout.data.model.entity.CompletedExercise
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.ExerciseSet
import com.dexwritescode.workout.data.model.entity.TemplateExercise
import com.dexwritescode.workout.data.model.entity.TemplateSet
import com.dexwritescode.workout.data.model.entity.WorkoutSession
import com.dexwritescode.workout.data.model.entity.WorkoutTemplate
import com.dexwritescode.workout.data.model.enums.MuscleGroup
import com.dexwritescode.workout.data.services.model.CompletedExerciseDetail
import com.dexwritescode.workout.data.services.model.WorkoutSessionDetail
import com.dexwritescode.workout.data.services.recovery.RecoveryEngine
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

// One slot in the active workout — pairs template metadata with live session data.
data class ExerciseSlot(
    val templateExercise: TemplateExercise,
    val exercise: Exercise?,
    val templateSets: List<TemplateSet>,
    val completedExercise: CompletedExercise,
    val completedSets: List<ExerciseSet>,
    val isAdhoc: Boolean = false,
)

data class WorkoutSummary(
    val durationMs: Long,
    val exercisesCompleted: Int,
    val totalExercises: Int,
    val totalSets: Int,
    val totalVolume: Double,
    val exerciseBreakdowns: List<ExerciseBreakdown>,
    val musclesWorked: Map<MuscleGroup, Double>,
) {
    data class ExerciseBreakdown(val name: String, val sets: List<SetDetail>)
    data class SetDetail(val setNumber: Int, val weight: Double, val reps: Int)
}

sealed class WorkoutState {
    object Loading : WorkoutState()
    data class NotStarted(val template: WorkoutTemplate, val slots: List<ExerciseSlot>) : WorkoutState()
    data class InProgress(
        val template: WorkoutTemplate,
        val session: WorkoutSession,
        val slots: List<ExerciseSlot>,
        val currentIndex: Int,
        val elapsedSeconds: Long,
    ) : WorkoutState()
    data class Finished(val session: WorkoutSession, val summary: WorkoutSummary) : WorkoutState()
}

class ActiveWorkoutViewModel(
    private val templateId: String,
    private val templateDao: WorkoutTemplateDao,
    private val templateExerciseDao: TemplateExerciseDao,
    private val templateSetDao: TemplateSetDao,
    private val exerciseDao: ExerciseDao,
    private val sessionDao: WorkoutSessionDao,
    private val completedExerciseDao: CompletedExerciseDao,
    private val exerciseSetDao: ExerciseSetDao,
    private val recoveryDao: MuscleRecoveryStateDao,
) : ViewModel() {

    private val _state = MutableStateFlow<WorkoutState>(WorkoutState.Loading)
    val state: StateFlow<WorkoutState> = _state.asStateFlow()

    private var sessionStartTime: Long = 0L

    init {
        viewModelScope.launch { loadTemplate() }
    }

    private suspend fun loadTemplate() {
        val template = templateDao.getById(templateId) ?: return
        val templateExercises = templateExerciseDao.getByTemplate(templateId).first()
        val slots = buildSlotsFromTemplateExercises(templateExercises.sortedBy { it.order })
        _state.value = WorkoutState.NotStarted(template, slots)
    }

    private suspend fun buildSlotsFromTemplateExercises(
        templateExercises: List<TemplateExercise>,
        adhocFlags: Set<String> = emptySet(),
    ): List<ExerciseSlot> = templateExercises.map { te ->
        val exercise = te.exerciseId?.let { exerciseDao.getById(it) }
        val templateSets = templateSetDao.getByTemplateExercise(te.id).first().sortedBy { it.order }
        ExerciseSlot(
            templateExercise = te,
            exercise = exercise,
            templateSets = templateSets,
            completedExercise = CompletedExercise(sessionId = null, exerciseId = te.exerciseId, order = te.order),
            completedSets = emptyList(),
            isAdhoc = te.id in adhocFlags,
        )
    }

    // MARK: - Session Lifecycle

    fun startWorkout() {
        val current = _state.value as? WorkoutState.NotStarted ?: return
        viewModelScope.launch {
            val session = WorkoutSession(templateId = templateId)
            sessionDao.insert(session)
            sessionStartTime = session.startTime
            templateDao.update(current.template.copy(lastUsedDate = System.currentTimeMillis()))

            val updatedSlots = current.slots.map { slot ->
                val ce = CompletedExercise(
                    sessionId = session.id,
                    exerciseId = slot.templateExercise.exerciseId,
                    order = slot.templateExercise.order,
                )
                completedExerciseDao.insert(ce)
                slot.copy(completedExercise = ce)
            }

            _state.value = WorkoutState.InProgress(
                template = current.template,
                session = session,
                slots = updatedSlots,
                currentIndex = 0,
                elapsedSeconds = 0L,
            )
            startElapsedTimer()
        }
    }

    fun finishWorkout() {
        val current = _state.value as? WorkoutState.InProgress ?: return
        viewModelScope.launch {
            val endTime = System.currentTimeMillis()
            val finished = current.session.copy(endTime = endTime, isCompleted = true)
            sessionDao.update(finished)
            val summary = buildSummary(finished, current.slots)
            _state.value = WorkoutState.Finished(session = finished, summary = summary)
        }
    }

    fun cancelWorkout() {
        val current = _state.value as? WorkoutState.InProgress ?: return
        viewModelScope.launch {
            current.slots.filter { it.isAdhoc }.forEach { templateExerciseDao.delete(it.templateExercise) }
            sessionDao.delete(current.session)
            val slots = buildSlotsFromTemplateExercises(
                current.slots.filter { !it.isAdhoc }.map { it.templateExercise }.sortedBy { it.order }
            )
            _state.value = WorkoutState.NotStarted(current.template, slots)
        }
    }

    fun addExercise(exercise: Exercise) {
        val current = _state.value as? WorkoutState.InProgress ?: return
        viewModelScope.launch {
            val order = current.slots.size
            val te = TemplateExercise(
                templateId = null,
                exerciseId = exercise.id,
                order = order,
                targetSets = 3,
                targetReps = 10,
                restSeconds = 90,
            )
            templateExerciseDao.insert(te)

            val ce = CompletedExercise(sessionId = current.session.id, exerciseId = exercise.id, order = order)
            completedExerciseDao.insert(ce)

            val newSlot = ExerciseSlot(
                templateExercise = te,
                exercise = exercise,
                templateSets = emptyList(),
                completedExercise = ce,
                completedSets = emptyList(),
                isAdhoc = true,
            )
            _state.value = current.copy(slots = current.slots + newSlot)
        }
    }

    fun removeExercise(index: Int) {
        val current = _state.value as? WorkoutState.InProgress ?: return
        if (index !in current.slots.indices) return
        viewModelScope.launch {
            val slot = current.slots[index]
            completedExerciseDao.delete(slot.completedExercise)
            if (slot.isAdhoc) templateExerciseDao.delete(slot.templateExercise)
            val updatedSlots = current.slots.toMutableList().also { it.removeAt(index) }
            val newIndex = minOf(current.currentIndex, maxOf(0, updatedSlots.size - 1))
            _state.value = current.copy(slots = updatedSlots, currentIndex = newIndex)
        }
    }

    fun selectExercise(index: Int) {
        val current = _state.value as? WorkoutState.InProgress ?: return
        if (index !in current.slots.indices) return
        _state.value = current.copy(currentIndex = index)
    }

    fun markExerciseComplete(index: Int) {
        val current = _state.value as? WorkoutState.InProgress ?: return
        val next = current.slots.indices.drop(index + 1).firstOrNull { i ->
            val slot = current.slots[i]
            slot.completedSets.count { it.isCompleted } < slot.templateExercise.targetSets
        }
        if (next != null) _state.value = current.copy(currentIndex = next)
    }

    // MARK: - Set Logging

    fun logSet(slotIndex: Int, weight: Double, reps: Int) {
        val current = _state.value as? WorkoutState.InProgress ?: return
        if (slotIndex !in current.slots.indices) return
        viewModelScope.launch {
            val slot = current.slots[slotIndex]
            val setNumber = slot.completedSets.count { it.isCompleted } + 1
            val newSet = ExerciseSet(
                completedExerciseId = slot.completedExercise.id,
                setNumber = setNumber,
                weight = weight,
                reps = reps,
                isCompleted = true,
                completedAt = System.currentTimeMillis(),
            )
            exerciseSetDao.insert(newSet)
            val updatedSlots = current.slots.toMutableList()
            updatedSlots[slotIndex] = slot.copy(completedSets = slot.completedSets + newSet)
            _state.value = current.copy(slots = updatedSlots)
        }
    }

    fun updateSet(slotIndex: Int, set: ExerciseSet, weight: Double, reps: Int) {
        val current = _state.value as? WorkoutState.InProgress ?: return
        if (slotIndex !in current.slots.indices) return
        viewModelScope.launch {
            val updated = set.copy(weight = weight, reps = reps)
            exerciseSetDao.update(updated)
            val updatedSlots = current.slots.toMutableList()
            val slot = updatedSlots[slotIndex]
            updatedSlots[slotIndex] = slot.copy(
                completedSets = slot.completedSets.map { if (it.id == set.id) updated else it }
            )
            _state.value = current.copy(slots = updatedSlots)
        }
    }

    fun deleteSet(slotIndex: Int, set: ExerciseSet) {
        val current = _state.value as? WorkoutState.InProgress ?: return
        if (slotIndex !in current.slots.indices) return
        viewModelScope.launch {
            exerciseSetDao.delete(set)
            val updatedSlots = current.slots.toMutableList()
            val slot = updatedSlots[slotIndex]
            val remaining = slot.completedSets
                .filter { it.id != set.id }
                .mapIndexed { i, s -> s.copy(setNumber = i + 1) }
            remaining.forEach { exerciseSetDao.update(it) }
            updatedSlots[slotIndex] = slot.copy(completedSets = remaining)
            _state.value = current.copy(slots = updatedSlots)
        }
    }

    // MARK: - Save / Discard

    fun saveWorkout(notes: String?) {
        val current = _state.value as? WorkoutState.Finished ?: return
        viewModelScope.launch {
            val updated = current.session.copy(notes = notes?.takeIf { it.isNotBlank() })
            sessionDao.update(updated)
            val allCompleted = completedExerciseDao.getBySessionOnce(updated.id)
            val details = allCompleted.mapNotNull { ce ->
                ce.exerciseId?.let { exerciseDao.getById(it) }?.let { ex ->
                    CompletedExerciseDetail(ce, ex, exerciseSetDao.getByCompletedExerciseOnce(ce.id))
                }
            }
            val detail = WorkoutSessionDetail(session = updated, completedExercises = details)
            RecoveryEngine.updateRecoveryStates(detail, recoveryDao)
        }
    }

    fun discardWorkout() {
        val current = _state.value as? WorkoutState.Finished ?: return
        viewModelScope.launch { sessionDao.delete(current.session) }
    }

    // MARK: - Helpers

    private fun startElapsedTimer() {
        viewModelScope.launch {
            while (true) {
                delay(1_000)
                val current = _state.value as? WorkoutState.InProgress ?: break
                _state.value = current.copy(
                    elapsedSeconds = (System.currentTimeMillis() - sessionStartTime) / 1000
                )
            }
        }
    }

    private suspend fun buildSummary(session: WorkoutSession, slots: List<ExerciseSlot>): WorkoutSummary {
        val allCompleted = completedExerciseDao.getBySessionOnce(session.id)
        val allSets = allCompleted.flatMap { exerciseSetDao.getByCompletedExerciseOnce(it.id) }
            .filter { it.isCompleted }

        val details = allCompleted.mapNotNull { ce ->
            ce.exerciseId?.let { exerciseDao.getById(it) }?.let { ex ->
                CompletedExerciseDetail(ce, ex, exerciseSetDao.getByCompletedExerciseOnce(ce.id))
            }
        }
        val musclesWorked = RecoveryEngine.calculateFatigueDeltas(
            WorkoutSessionDetail(session = session, completedExercises = details)
        )

        val breakdowns = slots.mapNotNull { slot ->
            val done = slot.completedSets.filter { it.isCompleted }.sortedBy { it.setNumber }
            if (done.isEmpty()) return@mapNotNull null
            WorkoutSummary.ExerciseBreakdown(
                name = slot.exercise?.name ?: "Unknown",
                sets = done.map { WorkoutSummary.SetDetail(it.setNumber, it.weight, it.reps) },
            )
        }

        return WorkoutSummary(
            durationMs = session.durationMs ?: 0L,
            exercisesCompleted = slots.count { it.completedSets.any { s -> s.isCompleted } },
            totalExercises = slots.size,
            totalSets = allSets.size,
            totalVolume = allSets.sumOf { it.weight * it.reps },
            exerciseBreakdowns = breakdowns,
            musclesWorked = musclesWorked,
        )
    }

    companion object {
        fun formatDuration(seconds: Long): String {
            val h = seconds / 3600
            val m = (seconds % 3600) / 60
            val s = seconds % 60
            return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%d:%02d".format(m, s)
        }
    }

    class Factory(
        private val templateId: String,
        private val templateDao: WorkoutTemplateDao,
        private val templateExerciseDao: TemplateExerciseDao,
        private val templateSetDao: TemplateSetDao,
        private val exerciseDao: ExerciseDao,
        private val sessionDao: WorkoutSessionDao,
        private val completedExerciseDao: CompletedExerciseDao,
        private val exerciseSetDao: ExerciseSetDao,
        private val recoveryDao: MuscleRecoveryStateDao,
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T = ActiveWorkoutViewModel(
            templateId, templateDao, templateExerciseDao, templateSetDao,
            exerciseDao, sessionDao, completedExerciseDao, exerciseSetDao, recoveryDao,
        ) as T
    }
}
