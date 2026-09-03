package au.iapp.lunch.core.db

import kotlinx.serialization.SerializationException
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json

/**
 * JSON encoding for the TEXT columns that hold lists and maps, matching
 * Dart's `json.encode` output (no whitespace) and `EntityMappers._safeDecode`
 * (malformed text falls back to the empty value).
 */
internal object DbJson {
    val json: Json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    private val stringList = ListSerializer(String.serializer())
    private val doubleMap = MapSerializer(String.serializer(), Double.serializer())

    fun encode(list: List<String>): String = json.encodeToString(stringList, list)

    fun encode(map: Map<String, Double>): String = json.encodeToString(doubleMap, map)

    fun stringList(text: String): List<String> = safe(text, emptyList()) { json.decodeFromString(stringList, it) }

    fun doubleMap(text: String): Map<String, Double> = safe(text, emptyMap()) { json.decodeFromString(doubleMap, it) }

    private inline fun <T> safe(text: String, fallback: T, decode: (String) -> T): T {
        if (text.isBlank()) return fallback
        return try {
            decode(text)
        } catch (e: SerializationException) {
            fallback
        } catch (e: IllegalArgumentException) {
            fallback
        }
    }
}
