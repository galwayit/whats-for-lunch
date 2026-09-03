/**
 * @file Formatting.kt
 * @description Date and time formatting shared by the group components. The shared module will
 * own locale rules eventually; these keep the components honest until then.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

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
