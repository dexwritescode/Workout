package com.dexwritescode.workout.data.model.enums

enum class DifficultyLevel(val rawValue: String) {
    BEGINNER("Beginner"),
    INTERMEDIATE("Intermediate"),
    ADVANCED("Advanced");

    val description: String
        get() = when (this) {
            BEGINNER -> "Suitable for beginners and those learning proper form"
            INTERMEDIATE -> "Requires some experience and good form"
            ADVANCED -> "For experienced lifters with excellent form"
        }

    companion object {
        fun fromRawValue(value: String): DifficultyLevel? = entries.find { it.rawValue == value }
    }
}
