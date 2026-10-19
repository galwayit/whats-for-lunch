/**
 * @file BillSplitEngineTest.kt
 * @description Pins BillSplitEngine to fixtures/bill_split_vectors.json, the same cases the
 * Swift port is tested against.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.core.engine

import au.iapp.lunch.core.support.readFixture
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertTrue

class BillSplitEngineTest {
    private val cases: List<JsonObject> = Json.parseToJsonElement(readFixture("bill_split_vectors.json"))
        .jsonObject.getValue("cases").jsonArray.map { it.jsonObject }

    private fun JsonObject.long(key: String) = getValue(key).jsonPrimitive.long

    private fun JsonObject.request() = BillSplitRequest(
        billCents = long("billCents"),
        people = getValue("people").jsonPrimitive.int,
        surchargeBps = getValue("surchargeBps").jsonPrimitive.int,
        fixedCents = getValue("fixed").jsonObject.entries.associate { (k, v) -> k.toInt() to v.jsonPrimitive.long },
    )

    @Test
    fun should_match_every_vector_when_splitting() {
        assertTrue(cases.size >= 17, "vectors loaded")
        for (case in cases) {
            val name = case.getValue("name").jsonPrimitive.content
            val result = BillSplitEngine.split(case.request())
            if ("error" in case) {
                val invalid = assertIs<BillSplitResult.Invalid>(result, name)
                assertEquals(BillSplitError.valueOf(case.getValue("error").jsonPrimitive.content), invalid.error, name)
                assertEquals(case.long("differenceCents"), invalid.differenceCents, name)
            } else {
                val split = assertIs<BillSplitResult.Split>(result, name)
                assertEquals(case.long("totalCents"), split.totalCents, name)
                assertEquals(case.long("surchargeCents"), split.surchargeCents, name)
                assertEquals(case.getValue("shares").jsonArray.map { it.jsonPrimitive.long }, split.sharesCents, name)
            }
        }
    }

    @Test
    fun should_always_add_up_to_the_total_when_the_split_is_valid() {
        for (bill in listOf(1L, 99L, 1_000L, 12_345L, 99_999L)) {
            for (people in 1..12) {
                for (bps in listOf(0, 150, 1000, 1500)) {
                    val split = assertIs<BillSplitResult.Split>(BillSplitEngine.split(BillSplitRequest(bill, people, bps)))
                    assertEquals(split.totalCents, split.sharesCents.sum(), "bill=$bill people=$people bps=$bps")
                    assertTrue(split.sharesCents.max() - split.sharesCents.min() <= 1, "even shares differ by at most a cent")
                }
            }
        }
    }

    @Test
    fun should_reject_caller_bugs_when_fixed_amounts_are_malformed() {
        assertFailsWith<IllegalArgumentException> { BillSplitEngine.split(BillSplitRequest(1_000, 2, fixedCents = mapOf(2 to 100))) }
        assertFailsWith<IllegalArgumentException> { BillSplitEngine.split(BillSplitRequest(1_000, 2, fixedCents = mapOf(0 to -1))) }
    }

    @Test
    fun should_convert_typed_values_when_parsing_dollars_and_percent() {
        assertEquals(1_850L, BillSplitEngine.dollarsToCents(18.5))
        assertEquals(29L, BillSplitEngine.dollarsToCents(0.29), "0.29 * 100 is 28.999... in binary")
        assertEquals(150, BillSplitEngine.percentToBps(1.5))
        assertEquals(1_000, BillSplitEngine.percentToBps(10.0))
    }
}
