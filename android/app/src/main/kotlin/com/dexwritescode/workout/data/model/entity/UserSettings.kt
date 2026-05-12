package com.dexwritescode.workout.data.model.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.dexwritescode.workout.data.model.enums.SplitType
import com.dexwritescode.workout.data.model.enums.WeightUnit
import java.util.UUID

@Entity(tableName = "user_settings")
data class UserSettings(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val weightUnit: String = WeightUnit.KG.rawValue,
    val defaultRestTime: Int = 90,
    val notificationsEnabled: Boolean = false,
    val notificationTime: Long? = null,
    val preferredEquipment: List<String> = emptyList(),
    val preferredSplitType: String? = null,
    val createdDate: Long = System.currentTimeMillis(),
    val availablePlatesKg: List<Double> = listOf(25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25),
    val availablePlatesLbs: List<Double> = listOf(45.0, 35.0, 25.0, 10.0, 5.0, 2.5, 1.25),
    val barbellWeightKg: Double = 20.0,
    val barbellWeightLbs: Double = 45.0,
) {
    val unit: WeightUnit
        get() = WeightUnit.fromRawValue(weightUnit) ?: WeightUnit.KG

    val splitType: SplitType?
        get() = preferredSplitType?.let { SplitType.fromRawValue(it) }
}
