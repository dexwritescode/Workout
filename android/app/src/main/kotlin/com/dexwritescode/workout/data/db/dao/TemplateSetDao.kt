package com.dexwritescode.workout.data.db.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.dexwritescode.workout.data.model.entity.TemplateSet
import kotlinx.coroutines.flow.Flow

@Dao
interface TemplateSetDao {
    @Query("SELECT * FROM template_sets WHERE templateExerciseId = :templateExerciseId ORDER BY `order` ASC")
    fun getByTemplateExercise(templateExerciseId: String): Flow<List<TemplateSet>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(templateSet: TemplateSet)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(sets: List<TemplateSet>)

    @Update
    suspend fun update(templateSet: TemplateSet)

    @Delete
    suspend fun delete(templateSet: TemplateSet)
}
