package au.iapp.lunch.core.platform

import au.iapp.lunch.core.api.Clock
import platform.Foundation.NSDate
import platform.Foundation.NSTimeZone
import platform.Foundation.localTimeZone
import platform.Foundation.timeIntervalSince1970

/** iOS clock over Foundation. */
actual object SystemClock : Clock {
    override fun nowEpochSeconds(): Long = NSDate().timeIntervalSince1970.toLong()
    override fun timeZoneId(): String = NSTimeZone.localTimeZone.name
}
