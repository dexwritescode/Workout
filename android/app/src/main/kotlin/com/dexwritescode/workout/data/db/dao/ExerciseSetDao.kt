package com.dexwritescode.workout.data.db.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.dexwritescode.workout.data.model.entity.ExerciseSet
import kotlinx.coroutines.flow.Flow

@Dao
interface ExerciseSetDao {
    @Query("SELECT * FROM exercise_sets WHERE completedExerciseId = :completedExerciseId ORDER BY setNumber ASC")
    fun getByCompletedExercise(completedExerciseId: String): Flow<List<ExerciseSet>>

    @Query("SELECT * FROM exercise_sets WHERE completedExerciseId = :completedExerciseId ORDER BY setNumber ASC")
    suspend fun getByCompletedExerciseOnce(completedExerciseId: String): List<ExerciseSet>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(exerciseSet: ExerciseSet)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(sets: List<ExerciseSet>)

    @Update
    suspend fun update(exerciseSet: ExerciseSet)

    @Delete
    suspend fun delete(exerciseSet: ExerciseSet)
}
