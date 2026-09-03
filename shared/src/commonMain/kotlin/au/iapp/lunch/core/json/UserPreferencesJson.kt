package au.iapp.lunch.core.json

import au.iapp.lunch.core.model.UserPreferences
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject

/**
 * Codec for the JSON stored in `users.preferences`.
 *
 * The text must stay byte-compatible with `UserPreferences.toJson()` /
 * `fromJson()` in the Flutter app: camelCase keys, every key written on
 * encode (including `lastKnownLocation: null`), `allergenSafetyLevels` values
 * as enum indexes, and defaults for any key that is missing or null.
 *
 * Keys the Flutter app does not know (for example `nativeAchievements`) are
 * ignored on decode and preserved by [encodePreserving].
 */
object UserPreferencesJson {

    /** Key under which the native apps keep unlocked achievements. */
    const val NATIVE_ACHIEVEMENTS_KEY = "nativeAchievements"

    val json: Json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        explicitNulls = true
        coerceInputValues = true
    }

    /** Decodes [text]; malformed or empty input yields all defaults, like the Flutter mapper. */
    fun decode(text: String): UserPreferences {
        if (text.isBlank()) return UserPreferences()
        return try {
            json.decodeFromString(UserPreferences.serializer(), text)
        } catch (e: SerializationException) {
            UserPreferences()
        } catch (e: IllegalArgumentException) {
            UserPreferences()
        }
    }

    /** Encodes every key of [prefs]. */
    fun encode(prefs: UserPreferences): String =
        json.encodeToString(UserPreferences.serializer(), prefs)

    /**
     * Encodes [prefs] while keeping any keys in [existingText] that the
     * preferences model does not own (the native achievements blob).
     */
    fun encodePreserving(prefs: UserPreferences, existingText: String): String {
        val existing = parseObject(existingText)
        val encoded = json.encodeToJsonElement(UserPreferences.serializer(), prefs).jsonObject
        if (existing.isEmpty()) return json.encodeToString(JsonObject.serializer(), encoded)
        val merged = LinkedHashMap<String, JsonElement>(existing)
        merged.putAll(encoded)
        return json.encodeToString(JsonObject.serializer(), JsonObject(merged))
    }

    /** Reads one extra (non-model) key from the stored text. */
    fun extra(existingText: String, key: String): JsonElement? = parseObject(existingText)[key]

    /** Returns [existingText] with [key] set to [value], leaving every other key untouched. */
    fun withExtra(existingText: String, key: String, value: JsonElement): String {
        val merged = LinkedHashMap<String, JsonElement>(parseObject(existingText))
        merged[key] = value
        return json.encodeToString(JsonObject.serializer(), JsonObject(merged))
    }

    private fun parseObject(text: String): JsonObject {
        if (text.isBlank()) return JsonObject(emptyMap())
        return try {
            json.parseToJsonElement(text).jsonObject
        } catch (e: SerializationException) {
            JsonObject(emptyMap())
        } catch (e: IllegalArgumentException) {
            JsonObject(emptyMap())
        }
    }
}
