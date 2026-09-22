/**
 * @file Intents.kt
 * @description Hands off to other apps: directions and map views, the share sheet, web links
 * and calendar events. Every launcher swallows the "no app" case so a bare emulator never
 * crashes the flow. Mirrors MapsLauncher and ShareSheet in iosApp/.../Shared.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.Restaurant

object Intents {
    private const val LUNCH_LENGTH_MS = 60L * 60L * 1000L

    private fun Restaurant.destination(): String =
        if (latitude != null && longitude != null) "$latitude,$longitude" else Uri.encode(address ?: name)

    fun directions(context: Context, restaurant: Restaurant) =
        open(context, Intent(Intent.ACTION_VIEW, Uri.parse("google.navigation:q=${restaurant.destination()}")))
            || openUrl(context, "https://www.google.com/maps/dir/?api=1&destination=${restaurant.destination()}")

    fun showOnMap(context: Context, restaurant: Restaurant) =
        open(context, Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q=${restaurant.destination()}")))
            || openUrl(context, "https://www.google.com/maps/search/?api=1&query=${restaurant.destination()}")

    fun directions(context: Context, group: LunchGroup) =
        openUrl(context, "https://www.google.com/maps/dir/?api=1&destination=" + Uri.encode(group.placeAddress ?: group.placeName ?: ""))

    fun openUrl(context: Context, url: String): Boolean =
        open(context, Intent(Intent.ACTION_VIEW, Uri.parse(url)))

    fun share(context: Context, text: String, subject: String? = null): Boolean {
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            subject?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
        }
        return open(context, Intent.createChooser(send, null))
    }

    fun addToCalendar(context: Context, group: LunchGroup): Boolean {
        val start = group.scheduledAtEpochSeconds * 1000L
        val insert = Intent(Intent.ACTION_INSERT).apply {
            data = CalendarContract.Events.CONTENT_URI
            putExtra(CalendarContract.Events.TITLE, group.name)
            putExtra(CalendarContract.Events.EVENT_LOCATION, listOfNotNull(group.placeName, group.placeAddress).joinToString(", "))
            putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, start)
            putExtra(CalendarContract.EXTRA_EVENT_END_TIME, start + LUNCH_LENGTH_MS)
        }
        return open(context, insert)
    }

    fun openAppSettings(context: Context): Boolean = open(
        context,
        Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null)),
    )

    private fun open(context: Context, intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}
