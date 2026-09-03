package au.iapp.lunch.core.platform

import au.iapp.lunch.core.api.Clock
import java.time.Instant
import java.time.ZoneId

/** Android clock over java.time (API 26+). */
actual object SystemClock : Clock {
    override fun nowEpochSeconds(): Long = Instant.now().epochSecond
    override fun timeZoneId(): String = ZoneId.systemDefault().id
}
