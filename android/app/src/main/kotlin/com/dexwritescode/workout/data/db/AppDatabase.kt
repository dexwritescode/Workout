package com.dexwritescode.workout.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.dexwritescode.workout.data.db.dao.CompletedExerciseDao
import com.dexwritescode.workout.data.db.dao.ExerciseDao
import com.dexwritescode.workout.data.db.dao.ExerciseSetDao
import com.dexwritescode.workout.data.db.dao.MuscleRecoveryStateDao
import com.dexwritescode.workout.data.db.dao.TemplateExerciseDao
import com.dexwritescode.workout.data.db.dao.TemplateSetDao
import com.dexwritescode.workout.data.db.dao.UserSettingsDao
import com.dexwritescode.workout.data.db.dao.WorkoutSessionDao
import com.dexwritescode.workout.data.db.dao.WorkoutTemplateDao
import com.dexwritescode.workout.data.model.entity.CompletedExercise
import com.dexwritescode.workout.data.model.entity.Exercise
import com.dexwritescode.workout.data.model.entity.ExerciseSet
import com.dexwritescode.workout.data.model.entity.MuscleRecoveryState
import com.dexwritescode.workout.data.model.entity.TemplateExercise
import com.dexwritescode.workout.data.model.entity.TemplateSet
import com.dexwritescode.workout.data.model.entity.UserSettings
import com.dexwritescode.workout.data.model.entity.WorkoutSession
import com.dexwritescode.workout.data.model.entity.WorkoutTemplate

@Database(
    entities = [
        Exercise::class,
        WorkoutTemplate::class,
        TemplateExercise::class,
        TemplateSet::class,
        WorkoutSession::class,
        CompletedExercise::class,
        ExerciseSet::class,
        UserSettings::class,
        MuscleRecoveryState::class,
    ],
    version = 1,
    exportSchema = true,
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun exerciseDao(): ExerciseDao
    abstract fun workoutTemplateDao(): WorkoutTemplateDao
    abstract fun templateExerciseDao(): TemplateExerciseDao
    abstract fun templateSetDao(): TemplateSetDao
    abstract fun workoutSessionDao(): WorkoutSessionDao
    abstract fun completedExerciseDao(): CompletedExerciseDao
    abstract fun exerciseSetDao(): ExerciseSetDao
    abstract fun userSettingsDao(): UserSettingsDao
    abstract fun muscleRecoveryStateDao(): MuscleRecoveryStateDao

    companion object {
        @Volatile private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "workout.db",
                ).build().also { INSTANCE = it }
            }
    }
}
