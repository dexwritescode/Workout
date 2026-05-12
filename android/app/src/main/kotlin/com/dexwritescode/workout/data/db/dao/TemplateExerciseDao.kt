package com.dexwritescode.workout.data.db.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.dexwritescode.workout.data.model.entity.TemplateExercise
import kotlinx.coroutines.flow.Flow

@Dao
interface TemplateExerciseDao {
    @Query("SELECT * FROM template_exercises WHERE templateId = :templateId ORDER BY `order` ASC")
    fun getByTemplate(templateId: String): Flow<List<TemplateExercise>>

    @Query("SELECT * FROM template_exercises WHERE id = :id")
    suspend fun getById(id: String): TemplateExercise?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(templateExercise: TemplateExercise)

    @Update
    suspend fun update(templateExercise: TemplateExercise)

    @Delete
    suspend fun delete(templateExercise: TemplateExercise)
}
