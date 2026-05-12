package com.dexwritescode.workout.data.model.enums

enum class WeightUnit(val rawValue: String, val abbreviation: String) {
    KG("Kilograms", "kg"),
    LBS("Pounds", "lbs");

    fun convert(weight: Double, to: WeightUnit): Double {
        if (this == to) return weight
        return when {
            this == KG && to == LBS -> weight * 2.20462
            this == LBS && to == KG -> weight / 2.20462
            else -> weight
        }
    }

    companion object {
        fun fromRawValue(value: String): WeightUnit? = entries.find { it.rawValue == value }
    }
}
