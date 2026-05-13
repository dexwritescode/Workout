package com.dexwritescode.workout.data.db.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.dexwritescode.workout.data.model.entity.WorkoutTemplate
import kotlinx.coroutines.flow.Flow

@Dao
interface WorkoutTemplateDao {
    @Query("SELECT * FROM workout_templates ORDER BY name ASC")
    fun getAll(): Flow<List<WorkoutTemplate>>

    @Query("SELECT * FROM workout_templates WHERE id = :id")
    suspend fun getById(id: String): WorkoutTemplate?

    @Query("SELECT COUNT(*) FROM workout_templates")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(template: WorkoutTemplate)

    @Update
    suspend fun update(template: WorkoutTemplate)

    @Delete
    suspend fun delete(template: WorkoutTemplate)
}
