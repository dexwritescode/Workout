package com.dexwritescode.workout.data.model.enums

enum class MuscleCategory(val rawValue: String) {
    UPPER_BODY("Upper Body"),
    LOWER_BODY("Lower Body");

    val muscles: List<MuscleGroup>
        get() = MuscleGroup.entries.filter { it.category == this }
}
