/**
 * @file IconSetTest.kt
 * @description Keeps the Android design system in step with the shared design sources:
 * the LunchIcon enum against icons.set in design/tokens.json, and the components' and screens'
 * Maestro test tags against the identifiers listed in design/screens.md.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui

import au.iapp.lunch.ui.components.HeroHungryButtonDefaults
import au.iapp.lunch.ui.components.InviteShareRowDefaults
import au.iapp.lunch.ui.components.PaywallDefaults
import au.iapp.lunch.ui.components.ProposalCardDefaults
import au.iapp.lunch.ui.components.RecommendationCardDefaults
import au.iapp.lunch.ui.components.RestaurantCardDefaults
import au.iapp.lunch.ui.features.groups.InviteQrDefaults
import au.iapp.lunch.ui.features.split.SplitBillDefaults
import au.iapp.lunch.ui.features.track.MealLogDefaults
import au.iapp.lunch.ui.theme.LunchIcon
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class IconSetTest {

    /** Walks up from the unit-test working directory (androidApp/) to the repo's design/ folder. */
    private fun designFile(name: String): File {
        var dir: File? = File(System.getProperty("user.dir")).absoluteFile
        while (dir != null) {
            val candidate = File(dir, "design/$name")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("design/$name not found above ${System.getProperty("user.dir")}")
    }

    @Test
    fun should_match_icon_set_in_tokens_json() {
        val tokens = Json.parseToJsonElement(designFile("tokens.json").readText()).jsonObject
        val expected = tokens.getValue("icons").jsonObject.getValue("set").jsonArray.map { it.jsonPrimitive.content }
        val actual = LunchIcon.entries.map { it.materialName }

        assertEquals("LunchIcon must list every icon in tokens.json, in order", expected, actual)
        assertEquals(63, actual.size)
    }

    @Test
    fun should_use_test_ids_listed_in_screens_md() {
        val screens = designFile("screens.md").readText()
        val summary = screens.substringAfter("Test ids summary")
        val listed = Regex("`([a-z_{}]+)`").findAll(summary).map { it.groupValues[1] }.toSet()
        assertTrue("screens.md must contain a test ids summary", listed.isNotEmpty())

        val index = 2
        val used = mapOf(
            HeroHungryButtonDefaults.TEST_TAG to "hero_hungry_button",
            RecommendationCardDefaults.TEST_TAG to "recommendation_card",
            PaywallDefaults.CTA_TEST_TAG to "paywall_cta",
            InviteShareRowDefaults.LINK_TEST_TAG to "invite_link_text",
            InviteShareRowDefaults.QR_BUTTON_TEST_TAG to "invite_qr_button",
            InviteQrDefaults.IMAGE_TAG to "invite_qr_image",
            RestaurantCardDefaults.testTag(index) to "restaurant_card_{i}",
            RestaurantCardDefaults.favouriteTag(index, selected = false) to "favourite_button_{i}",
            RestaurantCardDefaults.favouriteTag(index, selected = true) to "favourite_button_{i}_selected",
            ProposalCardDefaults.testTag(index) to "proposal_card_{i}",
            ProposalCardDefaults.chooseTag(index) to "proposal_card_{i}_choose",
            MealLogDefaults.PLACE_TEST_TAG to "meal_place_field",
            MealLogDefaults.COST_TEST_TAG to "meal_cost_field",
            SplitBillDefaults.TRACK_BUTTON_TAG to "split_bill_button",
            SplitBillDefaults.GROUP_BUTTON_TAG to "group_split_button",
            SplitBillDefaults.BILL_FIELD_TAG to "split_bill_field",
            SplitBillDefaults.SURCHARGE_FIELD_TAG to "split_surcharge_field",
            SplitBillDefaults.PEOPLE_STEPPER_TAG to "split_people_stepper",
            SplitBillDefaults.amountTag(index) to "split_person_{i}_amount",
            SplitBillDefaults.resetTag(index) to "split_person_{i}_reset",
            SplitBillDefaults.PAYID_FIELD_TAG to "split_payid_field",
            SplitBillDefaults.SHARE_BUTTON_TAG to "split_share_button",
            SplitBillDefaults.USE_SHARE_BUTTON_TAG to "split_use_share_button",
        )
        used.forEach { (tag, pattern) ->
            assertTrue("$pattern is not listed in design/screens.md", pattern in listed)
            assertEquals("$tag does not follow $pattern", pattern.replace("{i}", index.toString()), tag)
        }
    }
}
