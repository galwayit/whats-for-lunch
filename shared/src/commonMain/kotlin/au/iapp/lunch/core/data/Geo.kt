package au.iapp.lunch.core.data

import kotlin.math.PI
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.round
import kotlin.math.sin
import kotlin.math.sqrt

/** Small geographic helpers shared by the restaurant cache. */
internal object Geo {
    private const val EARTH_RADIUS_KM = 6371.0

    /** Great-circle distance in kilometres (haversine), like Geolocator.distanceBetween / 1000. */
    fun distanceKm(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
        val dLat = (lat2 - lat1).toRadians()
        val dLng = (lng2 - lng1).toRadians()
        val a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1.toRadians()) * cos(lat2.toRadians()) * sin(dLng / 2) * sin(dLng / 2)
        return 2 * EARTH_RADIUS_KM * asin(sqrt(a))
    }

    /** Rounds a coordinate to three decimals (about 110 m), the cache key granularity. */
    fun roundCoordinate(value: Double): Double = round(value * 1000.0) / 1000.0

    private fun Double.toRadians(): Double = this * PI / 180.0
}
