package com.dexwritescode.workout.data.model.enums

enum class MuscleGroup(val rawValue: String) {
    CHEST("Chest"),
    SHOULDERS("Shoulders"),
    BICEPS("Biceps"),
    TRICEPS("Triceps"),
    FOREARMS("Forearms"),
    LATS("Lats"),
    TRAPS("Traps"),
    LOWER_BACK("Lower Back"),
    NECK("Neck"),
    ABS("Abs"),
    GLUTES("Glutes"),
    HAMSTRINGS("Hamstrings"),
    QUADRICEPS("Quadriceps"),
    CALVES("Calves");

    val category: MuscleCategory
        get() = when (this) {
            CHEST, SHOULDERS, BICEPS, TRICEPS, FOREARMS,
            LATS, TRAPS, LOWER_BACK, NECK, ABS -> MuscleCategory.UPPER_BODY
            GLUTES, HAMSTRINGS, QUADRICEPS, CALVES -> MuscleCategory.LOWER_BODY
        }

    val defaultRecoveryHours: Int
        get() = when (this) {
            NECK, FOREARMS, CALVES, ABS -> 24
            BICEPS, TRICEPS, SHOULDERS, TRAPS -> 48
            CHEST, LATS, LOWER_BACK, QUADRICEPS, HAMSTRINGS, GLUTES -> 72
        }

    companion object {
        fun fromRawValue(value: String): MuscleGroup? = entries.find { it.rawValue == value }
    }
}
