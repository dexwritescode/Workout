package com.dexwritescode.workout.data.model.enums

enum class SplitType(val rawValue: String) {
    FULL_BODY("Full Body"),
    UPPER_LOWER("Upper/Lower"),
    PUSH_PULL_LEGS("Push/Pull/Legs"),
    BODYPART_SPLIT("Body Part Split");

    val description: String
        get() = when (this) {
            FULL_BODY -> "Train all major muscle groups in each workout"
            UPPER_LOWER -> "Alternate between upper body and lower body workouts"
            PUSH_PULL_LEGS -> "Split workouts into push muscles, pull muscles, and legs"
            BODYPART_SPLIT -> "Dedicate each workout to specific muscle groups"
        }

    val frequency: String
        get() = when (this) {
            FULL_BODY -> "3 days per week"
            UPPER_LOWER -> "4 days per week"
            PUSH_PULL_LEGS -> "6 days per week"
            BODYPART_SPLIT -> "5-6 days per week"
        }

    companion object {
        fun fromRawValue(value: String): SplitType? = entries.find { it.rawValue == value }
    }
}
