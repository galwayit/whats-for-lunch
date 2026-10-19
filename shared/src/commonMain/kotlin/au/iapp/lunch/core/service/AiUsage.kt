package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.data.DbDispatcher
import au.iapp.lunch.core.db.LunchDatabase
import kotlinx.coroutines.withContext
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.plus
import kotlinx.datetime.toLocalDateTime

/**
 * Reads and writes `a_i_usage_metrics`, the table the Flutter app used for the
 * same purpose (`request_type` 'recommendation' or 'feedback').
 */
internal class AiUsage(private val db: LunchDatabase, private val clock: Clock) {

    /** Successful recommendation requests inside today's UTC calendar day. */
    suspend fun usedToday(userId: Long): Int = withContext(DbDispatcher) {
        val (start, end) = localDayBounds()
        db.aiUsageMetricsQueries.countSuccessfulInRange(userId, RECOMMENDATION, start, end).executeAsOne().toInt()
    }

    suspend fun record(userId: Long, requestType: String, responseTimeMs: Long, successful: Boolean, errorMessage: String?) {
        withContext(DbDispatcher) {
            db.aiUsageMetricsQueries.insert(
                user_id = userId,
                request_type = requestType,
                tokens_used = 0,
                cost_in_cents = 0.0,
                response_time_ms = responseTimeMs,
                was_successful = successful,
                error_message = errorMessage,
                timestamp = clock.nowEpochSeconds(),
            )
        }
    }

    /** [start, end) epoch seconds of the current UTC day, independent of the device time zone. */
    fun localDayBounds(): Pair<Long, Long> {
        val zone = TimeZone.UTC
        val today = Instant.fromEpochSeconds(clock.nowEpochSeconds()).toLocalDateTime(zone).date
        val start = today.atStartOfDayIn(zone).epochSeconds
        val end = today.plus(1, DateTimeUnit.DAY).atStartOfDayIn(zone).epochSeconds
        return start to end
    }

    companion object {
        const val RECOMMENDATION = "recommendation"
        const val FEEDBACK = "feedback"
    }
}
