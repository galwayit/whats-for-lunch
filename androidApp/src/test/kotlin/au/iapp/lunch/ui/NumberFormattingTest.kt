/**
 * @file NumberFormattingTest.kt
 * @description Ratings and distances on screen must round the way the shared engine's reason
 * strings do: half-up on the exact binary value, as Dart's toStringAsFixed(1) does.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui

import au.iapp.lunch.ui.components.dartOneDecimal
import au.iapp.lunch.ui.features.shared.LunchFormat
import org.junit.Assert.assertEquals
import org.junit.Test

class NumberFormattingTest {

    @Test
    fun should_round_half_up_on_the_exact_value_when_formatting_one_decimal() {
        // Same vectors as shared/src/commonTest/.../DartNumberFormatTest.kt.
        assertEquals("2.3", dartOneDecimal(2.25))
        assertEquals("0.1", dartOneDecimal(0.15))
        assertEquals("-2.3", dartOneDecimal(-2.25))
        assertEquals("-0.1", dartOneDecimal(-0.05))
        assertEquals("0.0", dartOneDecimal(0.0))
        assertEquals("4.3", dartOneDecimal(4.25))
    }

    @Test
    fun should_use_the_dart_rounding_when_formatting_distances() {
        assertEquals("1.3 km", LunchFormat.kilometres(1.25))
        assertEquals("0.8 km", LunchFormat.kilometres(0.8))
        assertEquals("5", LunchFormat.compact(5.0))
        assertEquals("2.5", LunchFormat.compact(2.5))
    }
}
