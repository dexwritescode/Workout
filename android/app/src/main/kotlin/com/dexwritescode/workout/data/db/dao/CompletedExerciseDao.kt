package com.dexwritescode.workout.data.db.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.dexwritescode.workout.data.model.entity.CompletedExercise
import kotlinx.coroutines.flow.Flow

@Dao
interface CompletedExerciseDao {
    @Query("SELECT * FROM completed_exercises WHERE sessionId = :sessionId ORDER BY `order` ASC")
    fun getBySession(sessionId: String): Flow<List<CompletedExercise>>

    @Query("SELECT * FROM completed_exercises WHERE sessionId = :sessionId ORDER BY `order` ASC")
    suspend fun getBySessionOnce(sessionId: String): List<CompletedExercise>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(completedExercise: CompletedExercise)

    @Update
    suspend fun update(completedExercise: CompletedExercise)

    @Delete
    suspend fun delete(completedExercise: CompletedExercise)
}
