package com.dexwritescode.workout.data.db

import androidx.room.TypeConverter
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class Converters {
    @TypeConverter fun stringListToJson(value: List<String>): String = Json.encodeToString(value)
    @TypeConverter fun jsonToStringList(value: String): List<String> = Json.decodeFromString(value)

    @TypeConverter fun doubleListToJson(value: List<Double>): String = Json.encodeToString(value)
    @TypeConverter fun jsonToDoubleList(value: String): List<Double> = Json.decodeFromString(value)
}
