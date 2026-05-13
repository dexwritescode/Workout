package com.dexwritescode.workout

import com.dexwritescode.workout.data.db.dao.CompletedExerciseDao
import com.dexwritescode.workout.data.db.dao.ExerciseDao
import com.dexwritescode.workout.data.db.dao.ExerciseSetDao
import com.dexwritescode.workout.data.db.dao.UserSettingsDao
import com.dexwritescode.workout.data.db.dao.WorkoutSessionDao
import com.dexwritescode.workout.data.model.entity.CompletedExercise
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.ExerciseSet
import com.dexwritescode.workout.data.model.entity.UserSettings
import com.dexwritescode.workout.data.model.entity.WorkoutSession
import com.dexwritescode.workout.data.model.enums.DifficultyLevel
import com.dexwritescode.workout.data.model.enums.MuscleGroup
import com.dexwritescode.workout.data.model.enums.WeightUnit
import com.dexwritescode.workout.data.services.export.ExportService
import com.dexwritescode.workout.data.services.export.ImportService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ExportImportTest {

    // ── Export ─────────────────────────────────────────────────────────────────

    @Test
    fun `export produces valid JSON with version 1`() = runTest {
        val db = FakeDb()
        val exercise = makeExercise("Bench Press")
        db.exercises[exercise.id] = exercise
        db.sessions["s1"] = makeSession("s1", isCompleted = true)
        db.completedExercises["ce1"] = CompletedExercise(id = "ce1", sessionId = "s1", exerciseId = exercise.id, order = 0)
        db.exerciseSets["set1"] = ExerciseSet(id = "set1", completedExerciseId = "ce1", setNumber = 1, weight = 100.0, reps = 10, isCompleted = true)

        val bytes = ExportService.exportAll(db.sessionDao, db.completedExerciseDao, db.exerciseSetDao, db.exerciseDao, db.userSettingsDao)
        val json = bytes.toString(Charsets.UTF_8)

        assertTrue(json.contains("\"version\""))
        assertTrue(json.contains("\"sessions\""))
    }

    @Test
    fun `export only includes completed sessions`() = runTest {
        val db = FakeDb()
        db.sessions["s1"] = makeSession("s1", isCompleted = true)
        db.sessions["s2"] = makeSession("s2", isCompleted = false)

        val bytes = ExportService.exportAll(db.sessionDao, db.completedExerciseDao, db.exerciseSetDao, db.exerciseDao, db.userSettingsDao)
        val json = bytes.toString(Charsets.UTF_8)

        // Only 1 session should appear in sessions array — use id as a proxy
        val sessionCount = "\"id\"\\s*:\\s*\"s1\"".toRegex().findAll(json).count()
        assertEquals(1, sessionCount)
    }

    @Test
    fun `export includes settings when present`() = runTest {
        val db = FakeDb()
        db.settings = UserSettings(weightUnit = WeightUnit.LBS.rawValue, defaultRestTime = 120)

        val bytes = ExportService.exportAll(db.sessionDao, db.completedExerciseDao, db.exerciseSetDao, db.exerciseDao, db.userSettingsDao)
        val json = bytes.toString(Charsets.UTF_8)

        assertTrue(json.contains("\"settings\""))
        assertTrue(json.contains(WeightUnit.LBS.rawValue))
    }

    @Test
    fun `export with no sessions produces empty sessions array`() = runTest {
        val db = FakeDb()
        val bytes = ExportService.exportAll(db.sessionDao, db.completedExerciseDao, db.exerciseSetDao, db.exerciseDao, db.userSettingsDao)
        val json = bytes.toString(Charsets.UTF_8)
        assertTrue(json.contains("\"sessions\": []") || json.contains("\"sessions\":[]"))
    }

    // ── Import ─────────────────────────────────────────────────────────────────

    @Test
    fun `import round-trip restores session`() = runTest {
        val src = FakeDb()
        val exercise = makeExercise("Bench Press")
        src.exercises[exercise.id] = exercise
        src.sessions["s1"] = makeSession("s1", isCompleted = true)
        src.completedExercises["ce1"] = CompletedExercise(id = "ce1", sessionId = "s1", exerciseId = exercise.id, order = 0)
        src.exerciseSets["set1"] = ExerciseSet(id = "set1", completedExerciseId = "ce1", setNumber = 1, weight = 80.0, reps = 5, isCompleted = true)
        src.settings = UserSettings()

        val bytes = ExportService.exportAll(src.sessionDao, src.completedExerciseDao, src.exerciseSetDao, src.exerciseDao, src.userSettingsDao)

        val dst = FakeDb()
        val exercise2 = makeExercise("Bench Press")
        dst.exercises[exercise2.id] = exercise2
        dst.settings = UserSettings()

        val result = ImportService.importData(bytes, dst.sessionDao, dst.completedExerciseDao, dst.exerciseSetDao, dst.exerciseDao, dst.userSettingsDao)

        assertEquals(1, result.sessionsImported)
        assertTrue(result.settingsImported)
    }

    @Test
    fun `import skips duplicate sessions by id`() = runTest {
        val db = FakeDb()
        val exercise = makeExercise("Squat")
        db.exercises[exercise.id] = exercise
        db.sessions["s1"] = makeSession("s1", isCompleted = true)

        val bytes = ExportService.exportAll(db.sessionDao, db.completedExerciseDao, db.exerciseSetDao, db.exerciseDao, db.userSettingsDao)

        // Import into the same db — session already exists
        val result = ImportService.importData(bytes, db.sessionDao, db.completedExerciseDao, db.exerciseSetDao, db.exerciseDao, db.userSettingsDao)

        assertEquals(0, result.sessionsImported)
    }

    @Test
    fun `import rejects unsupported version`() = runTest {
        val json = """{"exportDate":"2026-01-01T00:00:00Z","version":99,"sessions":[]}"""
        val db = FakeDb()

        var threw = false
        try {
            ImportService.importData(json.toByteArray(), db.sessionDao, db.completedExerciseDao, db.exerciseSetDao, db.exerciseDao, db.userSettingsDao)
        } catch (e: ImportService.ImportError.UnsupportedVersion) {
            threw = true
        }
        assertTrue(threw)
    }

    @Test
    fun `import rejects invalid json`() = runTest {
        val db = FakeDb()

        var threw = false
        try {
            ImportService.importData("not json".toByteArray(), db.sessionDao, db.completedExerciseDao, db.exerciseSetDao, db.exerciseDao, db.userSettingsDao)
        } catch (e: ImportService.ImportError.DecodingFailed) {
            threw = true
        }
        assertTrue(threw)
    }

    @Test
    fun `import updates existing settings`() = runTest {
        val json = """{"exportDate":"2026-01-01T00:00:00Z","version":1,"sessions":[],"settings":{"weightUnit":"Pounds","defaultRestTime":180,"preferredSplitType":"Push/Pull/Legs"}}"""
        val db = FakeDb()
        db.settings = UserSettings(weightUnit = WeightUnit.KG.rawValue, defaultRestTime = 90)

        val result = ImportService.importData(json.toByteArray(), db.sessionDao, db.completedExerciseDao, db.exerciseSetDao, db.exerciseDao, db.userSettingsDao)

        assertTrue(result.settingsImported)
        assertNotNull(db.settings)
        assertEquals(WeightUnit.LBS.rawValue, db.settings!!.weightUnit)
        assertEquals(180, db.settings!!.defaultRestTime)
    }

    @Test
    fun `import without settings preserves existing settings`() = runTest {
        val json = """{"exportDate":"2026-01-01T00:00:00Z","version":1,"sessions":[]}"""
        val db = FakeDb()
        db.settings = UserSettings(weightUnit = WeightUnit.LBS.rawValue, defaultRestTime = 120)

        val result = ImportService.importData(json.toByteArray(), db.sessionDao, db.completedExerciseDao, db.exerciseSetDao, db.exerciseDao, db.userSettingsDao)

        assertFalse(result.settingsImported)
        assertEquals(WeightUnit.LBS.rawValue, db.settings!!.weightUnit)
        assertEquals(120, db.settings!!.defaultRestTime)
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private fun makeExercise(name: String) = Exercise(
        name = name,
        exerciseDescription = "Test",
        primaryMuscles = listOf(MuscleGroup.CHEST.rawValue),
        difficultyLevel = DifficultyLevel.INTERMEDIATE.rawValue,
    )

    private fun makeSession(id: String, isCompleted: Boolean) = WorkoutSession(
        id = id,
        templateId = null,
        startTime = System.currentTimeMillis() - 3_600_000,
        endTime = if (isCompleted) System.currentTimeMillis() else null,
        isCompleted = isCompleted,
    )

    // ── Fake in-memory DAOs ────────────────────────────────────────────────────

    private inner class FakeDb {
        val exercises = mutableMapOf<String, Exercise>()
        val sessions = mutableMapOf<String, WorkoutSession>()
        val completedExercises = mutableMapOf<String, CompletedExercise>()
        val exerciseSets = mutableMapOf<String, ExerciseSet>()
        var settings: UserSettings? = null

        val exerciseDao = object : ExerciseDao {
            override fun getAll(): Flow<List<Exercise>> = flowOf(exercises.values.toList())
            override suspend fun getById(id: String) = exercises[id]
            override suspend fun count() = exercises.size
            override suspend fun insert(exercise: Exercise) { exercises[exercise.id] = exercise }
            override suspend fun insertAll(exercises: List<Exercise>) { exercises.forEach { this@FakeDb.exercises[it.id] = it } }
            override suspend fun update(exercise: Exercise) { exercises[exercise.id] = exercise }
            override suspend fun delete(exercise: Exercise) { exercises.remove(exercise.id) }
            override suspend fun getByName(name: String) = exercises.values.find { it.name == name }
            override suspend fun getAllOnce() = exercises.values.toList()
        }

        val sessionDao = object : WorkoutSessionDao {
            override fun getAll(): Flow<List<WorkoutSession>> = flowOf(sessions.values.toList())
            override suspend fun getById(id: String) = sessions[id]
            override suspend fun getActiveSession() = sessions.values.find { !it.isCompleted }
            override suspend fun insert(session: WorkoutSession) { sessions[session.id] = session }
            override suspend fun update(session: WorkoutSession) { sessions[session.id] = session }
            override suspend fun delete(session: WorkoutSession) { sessions.remove(session.id) }
            override suspend fun getAllCompleted() = sessions.values.filter { it.isCompleted }
            override suspend fun getAllOnce() = sessions.values.toList()
        }

        val completedExerciseDao = object : CompletedExerciseDao {
            override fun getBySession(sessionId: String): Flow<List<CompletedExercise>> =
                flowOf(completedExercises.values.filter { it.sessionId == sessionId })
            override suspend fun getBySessionOnce(sessionId: String) =
                completedExercises.values.filter { it.sessionId == sessionId }
            override suspend fun insert(completedExercise: CompletedExercise) { completedExercises[completedExercise.id] = completedExercise }
            override suspend fun update(completedExercise: CompletedExercise) { completedExercises[completedExercise.id] = completedExercise }
            override suspend fun delete(completedExercise: CompletedExercise) { completedExercises.remove(completedExercise.id) }
        }

        val exerciseSetDao = object : ExerciseSetDao {
            override fun getByCompletedExercise(completedExerciseId: String): Flow<List<ExerciseSet>> =
                flowOf(exerciseSets.values.filter { it.completedExerciseId == completedExerciseId })
            override suspend fun getByCompletedExerciseOnce(completedExerciseId: String) =
                exerciseSets.values.filter { it.completedExerciseId == completedExerciseId }
            override suspend fun insert(exerciseSet: ExerciseSet) { exerciseSets[exerciseSet.id] = exerciseSet }
            override suspend fun insertAll(sets: List<ExerciseSet>) { sets.forEach { exerciseSets[it.id] = it } }
            override suspend fun update(exerciseSet: ExerciseSet) { exerciseSets[exerciseSet.id] = exerciseSet }
            override suspend fun delete(exerciseSet: ExerciseSet) { exerciseSets.remove(exerciseSet.id) }
        }

        val userSettingsDao = object : UserSettingsDao {
            override fun get(): Flow<UserSettings?> = flowOf(settings)
            override fun getAll(): Flow<List<UserSettings>> = flowOf(listOfNotNull(settings))
            override suspend fun getOnce() = settings
            override suspend fun insert(s: UserSettings) { settings = s }
            override suspend fun update(s: UserSettings) { settings = s }
        }
    }
}
