package au.iapp.lunch.core.engine

import au.iapp.lunch.core.platform.toFixed1
import au.iapp.lunch.core.platform.toFixed2
import au.iapp.lunch.core.platform.toStringAsFixed
import au.iapp.lunch.core.support.EngineVectors
import au.iapp.lunch.core.support.dbl
import au.iapp.lunch.core.support.str
import kotlin.test.Test
import kotlin.test.assertEquals

class DartNumberFormatTest {
    @Test
    fun toFixed_matchesDartToStringAsFixedIncludingBinaryTies() {
        for (case in EngineVectors.load().cases("toStringAsFixed1")) {
            val value = case.dbl("value")
            assertEquals(case.str("expected"), value.toFixed1(), "toFixed1($value)")
            assertEquals(case.str("expected2"), value.toFixed2(), "toFixed2($value)")
        }
    }

    @Test
    fun toFixed_handlesSignsZeroAndNonFinite() {
        assertEquals("-2.3", (-2.25).toFixed1())
        assertEquals("-0.1", (-0.05).toFixed1())
        assertEquals("0.0", 0.0.toFixed1())
        assertEquals("3", 2.5.toStringAsFixed(0))
        assertEquals("2", 1.5.toStringAsFixed(0))
        assertEquals("0.125", 0.125.toStringAsFixed(3))
        assertEquals("NaN", Double.NaN.toFixed1())
        assertEquals("Infinity", Double.POSITIVE_INFINITY.toFixed1())
    }
}
