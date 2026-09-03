package au.iapp.lunch.core.json

import au.iapp.lunch.core.model.UserPreferences
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class UserPreferencesJsonTest {

    private val expectedKeys = listOf(
        "dietaryRestrictions", "cuisinePreferences", "allergens", "allergenSafetyLevels", "contextualPreferences",
        "cuisineRatings", "restaurantVisitCounts", "budgetLevel", "maxTravelDistance", "includeChains",
        "mealFrequencyPerDay", "weeklyBudget", "enableLocationServices", "showMapView", "mapZoomLevel",
        "lastKnownLocation", "requireDietaryVerification", "minimumRating", "preferredPriceRanges",
        "avoidBusyTimes", "accessibilityRequirements",
    )

    @Test
    fun emptyObject_decodesToFlutterDefaults() {
        val prefs = UserPreferencesJson.decode("{}")
        assertEquals(UserPreferences(), prefs)
        assertEquals(2, prefs.budgetLevel)
        assertEquals(5.0, prefs.maxTravelDistance)
        assertEquals(200.0, prefs.weeklyBudget)
        assertEquals(listOf("$", "$$"), prefs.preferredPriceRanges)
        assertTrue(prefs.includeChains)
        assertEquals(3.0, prefs.minimumRating)
        assertEquals(14, prefs.mapZoomLevel)
        assertEquals(3, prefs.mealFrequencyPerDay)
        assertNull(prefs.lastKnownLocation)
        assertTrue(prefs.requireDietaryVerification)
        assertTrue(prefs.enableLocationServices)
        assertTrue(prefs.showMapView)
        assertEquals(false, prefs.avoidBusyTimes)
    }

    @Test
    fun blankMalformedAndNullValues_fallBackToDefaults() {
        assertEquals(UserPreferences(), UserPreferencesJson.decode(""))
        assertEquals(UserPreferences(), UserPreferencesJson.decode("not json"))
        assertEquals(UserPreferences(), UserPreferencesJson.decode("[1,2]"))
        val nulls = UserPreferencesJson.decode("""{"budgetLevel":null,"maxTravelDistance":null,"lastKnownLocation":null,"preferredPriceRanges":null}""")
        assertEquals(UserPreferences(), nulls)
        // Integers where Dart wrote doubles are accepted, as `.toDouble()` did.
        assertEquals(7.0, UserPreferencesJson.decode("""{"maxTravelDistance":7}""").maxTravelDistance)
    }

    @Test
    fun encode_writesEveryKeyInFlutterOrder() {
        val text = UserPreferencesJson.encode(UserPreferences())
        val obj = Json.parseToJsonElement(text).jsonObject
        assertEquals(expectedKeys, obj.keys.toList())
        assertEquals("null", obj.getValue("lastKnownLocation").toString())
        assertEquals("""["$","$$"]""", obj.getValue("preferredPriceRanges").toString())
        assertEquals("5.0", obj.getValue("maxTravelDistance").toString())
        assertEquals("200.0", obj.getValue("weeklyBudget").toString())
        assertEquals("2", obj.getValue("budgetLevel").toString())
        assertEquals("{}", obj.getValue("allergenSafetyLevels").toString())
    }

    @Test
    fun fullDocument_roundTrips() {
        val flutterJson = """
            {"dietaryRestrictions":["vegetarian","gluten_free"],"cuisinePreferences":["Thai","Japanese"],
             "allergens":["peanuts"],"allergenSafetyLevels":{"peanuts":2,"dairy":0},
             "contextualPreferences":{"lunch":["quick","light"],"dinner":[]},
             "cuisineRatings":{"Thai":4.5,"Japanese":5.0},"restaurantVisitCounts":{"ChIJ123":3},
             "budgetLevel":3,"maxTravelDistance":7.5,"includeChains":false,"mealFrequencyPerDay":2,
             "weeklyBudget":150.0,"enableLocationServices":false,"showMapView":true,"mapZoomLevel":12,
             "lastKnownLocation":[-33.8688,151.2093],"requireDietaryVerification":false,"minimumRating":4.0,
             "preferredPriceRanges":["$$","$$$"],"avoidBusyTimes":true,"accessibilityRequirements":{"wheelchair":true}}
        """.trimIndent()
        val decoded = UserPreferencesJson.decode(flutterJson)
        assertEquals(listOf("vegetarian", "gluten_free"), decoded.dietaryRestrictions)
        assertEquals(mapOf("peanuts" to 2, "dairy" to 0), decoded.allergenSafetyLevels)
        assertEquals(mapOf("lunch" to listOf("quick", "light"), "dinner" to emptyList()), decoded.contextualPreferences)
        assertEquals(listOf(-33.8688, 151.2093), decoded.lastKnownLocation)
        assertEquals(3, decoded.budgetLevel)
        assertEquals(false, decoded.includeChains)
        assertEquals(mapOf("wheelchair" to true), decoded.accessibilityRequirements)

        val reencoded = UserPreferencesJson.encode(decoded)
        assertEquals(Json.parseToJsonElement(flutterJson), Json.parseToJsonElement(reencoded))
        assertEquals(decoded, UserPreferencesJson.decode(reencoded))
    }

    @Test
    fun unknownKeys_areIgnoredOnDecodeAndPreservedByEncodePreserving() {
        val stored = """{"budgetLevel":4,"nativeAchievements":[{"id":"first_experience"}],"futureKey":1}"""
        val decoded = UserPreferencesJson.decode(stored)
        assertEquals(4, decoded.budgetLevel)

        val updated = UserPreferencesJson.encodePreserving(decoded.copy(budgetLevel = 1), stored)
        val obj = Json.parseToJsonElement(updated).jsonObject
        assertEquals(1, obj.getValue("budgetLevel").jsonPrimitive.content.toInt())
        assertEquals("""[{"id":"first_experience"}]""", obj.getValue("nativeAchievements").toString())
        assertEquals("1", obj.getValue("futureKey").toString())
        assertEquals(expectedKeys.size + 2, obj.size)

        val withExtra = UserPreferencesJson.withExtra("{}", "nativeAchievements", JsonPrimitive("x"))
        assertEquals("\"x\"", UserPreferencesJson.extra(withExtra, "nativeAchievements").toString())
        assertNull(UserPreferencesJson.extra("{}", "nativeAchievements"))
    }
}
