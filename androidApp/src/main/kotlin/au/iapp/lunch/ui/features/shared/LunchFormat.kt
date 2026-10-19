/**
 * @file LunchFormat.kt
 * @description Date, distance and currency formatting shared by the screens. Dates format in
 * the device zone; amounts in Australian dollars. Mirrors iosApp/.../LunchFormat+Dates.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import au.iapp.lunch.ui.components.dartOneDecimal
import java.math.BigDecimal
import java.text.NumberFormat
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Currency
import java.util.Locale

object LunchFormat {
    private val locale = Locale("en", "AU")
    private val dayTimeFormatter = DateTimeFormatter.ofPattern("EEE d MMM, h:mm a", locale)
    private val timeFormatter = DateTimeFormatter.ofPattern("h:mm a", locale)
    private val shortDayFormatter = DateTimeFormatter.ofPattern("d MMM", locale)
    private val dayFormatter = DateTimeFormatter.ofPattern("d MMM yyyy", locale)

    private val wholeDollars: NumberFormat = NumberFormat.getCurrencyInstance(locale).apply {
        currency = Currency.getInstance("AUD")
        maximumFractionDigits = 0
    }
    private val centsDollars: NumberFormat = NumberFormat.getCurrencyInstance(locale).apply {
        currency = Currency.getInstance("AUD")
        minimumFractionDigits = 2
        maximumFractionDigits = 2
    }

    /** "Thu 4 Sep, 12:30 pm". */
    fun dayTime(epochSeconds: Long, zone: ZoneId = ZoneId.systemDefault()): String =
        lowercaseMeridiem(dayTimeFormatter.format(Instant.ofEpochSecond(epochSeconds).atZone(zone)))

    /** "12:30 pm". */
    fun time(epochSeconds: Long, zone: ZoneId = ZoneId.systemDefault()): String =
        lowercaseMeridiem(timeFormatter.format(Instant.ofEpochSecond(epochSeconds).atZone(zone)))

    /** "Today", "Yesterday" or "26 Aug". */
    fun relativeDay(epochSeconds: Long, nowEpochSeconds: Long, today: String, yesterday: String, zone: ZoneId = ZoneId.systemDefault()): String {
        val date = Instant.ofEpochSecond(epochSeconds).atZone(zone).toLocalDate()
        val now = Instant.ofEpochSecond(nowEpochSeconds).atZone(zone).toLocalDate()
        return when (date) {
            now -> today
            now.minusDays(1) -> yesterday
            else -> shortDayFormatter.format(date)
        }
    }

    /** "4 Sep 2026". */
    fun day(epochSeconds: Long, zone: ZoneId = ZoneId.systemDefault()): String =
        dayFormatter.format(Instant.ofEpochSecond(epochSeconds).atZone(zone))

    /** "0.8 km". */
    fun kilometres(distance: Double): String = dartOneDecimal(distance) + " km"

    /** "5" or "2.5", for slider labels. */
    fun compact(value: Double): String =
        if (value == Math.floor(value)) value.toLong().toString() else dartOneDecimal(value)

    /** "$18.50" for meal costs; "$200" when the amount is whole. */
    fun currency(amount: Double): String =
        if (amount == Math.floor(amount)) wholeDollars.format(amount) else centsDollars.format(amount)

    /** "$33.34" and "$200.00": whole cents, always two decimals, for bill splits. */
    fun cents(amountCents: Long): String = centsDollars.format(BigDecimal.valueOf(amountCents, 2))

    fun localDate(epochSeconds: Long, zone: ZoneId = ZoneId.systemDefault()): LocalDate =
        Instant.ofEpochSecond(epochSeconds).atZone(zone).toLocalDate()

    private fun lowercaseMeridiem(text: String): String = text.replace("AM", "am").replace("PM", "pm")
}
