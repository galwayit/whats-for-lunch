package au.iapp.lunch.core.support

import au.iapp.lunch.core.json.UserPreferencesJson
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.UserPreferences
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.double
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Typed access to fixtures/engine_vectors.json, which was produced by running
 * the Flutter functions themselves (see BUILD_NOTES.md), so expected values
 * carry Dart's arithmetic and `toStringAsFixed` formatting.
 */
class EngineVectors private constructor(val root: JsonObject) {

    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    val restaurants: Map<String, Restaurant> = root.getValue("restaurants").jsonArray
        .map { json.decodeFromJsonElement(Restaurant.serializer(), it) }
        .associateBy { it.placeId }

    val restaurantOrder: List<String> = root.getValue("restaurants").jsonArray
        .map { it.jsonObject.getValue("placeId").jsonPrimitive.content }

    val prefs: Map<String, UserPreferences?> = root.getValue("prefs").jsonObject
        .mapValues { (_, v) -> if (v is JsonNull) null else UserPreferencesJson.decode(v.toString()) }

    fun cases(key: String): List<JsonObject> = root.getValue(key).jsonArray.map { it.jsonObject }

    fun budgetCases(key: String): List<JsonObject> = root.getValue("budget").jsonObject.getValue(key).jsonArray.map { it.jsonObject }

    companion object {
        fun load(): EngineVectors = EngineVectors(Json.parseToJsonElement(readFixture("engine_vectors.json")).jsonObject)
    }
}

fun JsonObject.str(key: String): String = getValue(key).jsonPrimitive.content
fun JsonObject.strOrNull(key: String): String? = get(key)?.let { if (it is JsonNull) null else it.jsonPrimitive.content }
fun JsonObject.dbl(key: String): Double = getValue(key).jsonPrimitive.double
fun JsonObject.dblOrNull(key: String): Double? = get(key)?.let { if (it is JsonNull) null else it.jsonPrimitive.double }
fun JsonObject.int(key: String): Int = getValue(key).jsonPrimitive.int
fun JsonObject.bool(key: String): Boolean = getValue(key).jsonPrimitive.boolean
fun JsonObject.strings(key: String): List<String> = getValue(key).jsonArray.map { it.jsonPrimitive.content }
fun JsonObject.obj(key: String): JsonObject = getValue(key).jsonObject
fun JsonElementIsNull(e: kotlinx.serialization.json.JsonElement) = e is JsonNull
