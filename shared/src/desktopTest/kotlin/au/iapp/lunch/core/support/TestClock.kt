package au.iapp.lunch.core.support

import au.iapp.lunch.core.api.Clock

/** Frozen clock; tests move it with [advance]. Default: 2026-09-03 11:46:40 AEST (Thursday). */
class TestClock(var now: Long = DEFAULT_NOW, private val zone: String = "Australia/Sydney") : Clock {
    override fun nowEpochSeconds(): Long = now
    override fun timeZoneId(): String = zone
    fun advance(seconds: Long) { now += seconds }

    companion object {
        const val DEFAULT_NOW = 1_788_400_000L
        const val HOUR = 3_600L
        const val DAY = 86_400L
    }
}
