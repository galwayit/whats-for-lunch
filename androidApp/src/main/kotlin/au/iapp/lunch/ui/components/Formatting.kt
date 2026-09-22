/**
 * @file Formatting.kt
 * @description Date and time formatting shared by the group components. The shared module will
 * own locale rules eventually; these keep the components honest until then.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import java.math.BigDecimal
import java.math.RoundingMode
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

private val timeFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("h:mm a", Locale.getDefault())
private val dateFormatter: DateTimeFormatter = DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM).withLocale(Locale.getDefault())

/** "12:30 pm" in the device time zone. */
fun formatLunchTime(epochSeconds: Long): String =
    timeFormatter.format(Instant.ofEpochSecond(epochSeconds).atZone(ZoneId.systemDefault())).lowercase(Locale.getDefault())

/** "3 Sep 2026" in the device time zone. */
fun formatLunchDate(epochSeconds: Long): String =
    dateFormatter.format(Instant.ofEpochSecond(epochSeconds).atZone(ZoneId.systemDefault()))

/**
 * One fraction digit, rounded half-up on the exact binary value, the way Dart's
 * `double.toStringAsFixed(1)` does (2.25 -> "2.3", 0.15 -> "0.1"). Platform formatters
 * round half-even and would disagree with the reason strings the shared engine builds
 * ("Highly rated (4.5/5)", "Only 1.2km away"), so every rating and distance the screens
 * format goes through here.
 *
 * This mirrors `au.iapp.lunch.core.platform.toFixed1`, which is `internal` to :shared and
 * therefore not callable from this module; make that helper public and this copy can go.
 */
fun dartOneDecimal(value: Double): String {
    if (!value.isFinite()) return value.toString()
    return BigDecimal(value).setScale(1, RoundingMode.HALF_UP).toPlainString()
}
