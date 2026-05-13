package com.dexwritescode.workout.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.dexwritescode.workout.data.model.entity.MuscleRecoveryState
import kotlinx.coroutines.flow.Flow

@Dao
interface MuscleRecoveryStateDao {
    @Query("SELECT * FROM muscle_recovery_states")
    fun getAll(): Flow<List<MuscleRecoveryState>>

    @Query("SELECT * FROM muscle_recovery_states WHERE muscleGroup = :muscleGroup")
    suspend fun getByMuscleGroup(muscleGroup: String): MuscleRecoveryState?

    @Query("SELECT COUNT(*) FROM muscle_recovery_states")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(state: MuscleRecoveryState)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(states: List<MuscleRecoveryState>)

    @Update
    suspend fun update(state: MuscleRecoveryState)
}
