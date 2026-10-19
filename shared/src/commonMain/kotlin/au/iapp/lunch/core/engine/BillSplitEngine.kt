/**
 * @file BillSplitEngine.kt
 * @description Splits a restaurant bill between people in whole cents: optional surcharge,
 * even shares, and per-person adjusted amounts with the rest rebalanced.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.core.engine

import kotlin.math.roundToLong

/**
 * What the user entered. Money is in whole cents and the surcharge in basis points
 * (1000 = 10%), so the arithmetic is exact and the Swift port gets identical results.
 *
 * @property fixedCents person index to the final amount (after surcharge) they chose to pay.
 */
data class BillSplitRequest(
    val billCents: Long,
    val people: Int,
    val surchargeBps: Int = 0,
    val fixedCents: Map<Int, Long> = emptyMap(),
)

enum class BillSplitError {
    NO_BILL,
    NO_PEOPLE,
    TOO_MANY_PEOPLE,
    SURCHARGE_OUT_OF_RANGE,

    /** The adjusted amounts add up to more than the bill; [BillSplitResult.Invalid.differenceCents] is the excess. */
    OVER_ALLOCATED,

    /** Everyone was adjusted and together they fall short; the difference is what is left unpaid. */
    UNDER_ALLOCATED,
}

sealed interface BillSplitResult {
    /** [sharesCents] has one entry per person, in order, and always sums to [totalCents]. */
    data class Split(val totalCents: Long, val surchargeCents: Long, val sharesCents: List<Long>) : BillSplitResult

    data class Invalid(val error: BillSplitError, val differenceCents: Long = 0) : BillSplitResult
}

object BillSplitEngine {
    const val MAX_PEOPLE = 50

    /** 50%: well above any real surcharge, low enough to catch a mistyped amount. */
    const val MAX_SURCHARGE_BPS = 5000

    /**
     * Splits [request]. Leftover cents from an uneven division go one each to the earliest
     * people who were not adjusted, so the payer (listed first) absorbs them.
     *
     * @throws IllegalArgumentException for a fixed index outside the people list or a
     * negative fixed amount; both are caller bugs, not user input.
     * @example BillSplitEngine.split(BillSplitRequest(billCents = 10_000, people = 3)) // 3334, 3333, 3333
     */
    fun split(request: BillSplitRequest): BillSplitResult {
        val (billCents, people, surchargeBps, fixed) = request
        if (billCents <= 0) return BillSplitResult.Invalid(BillSplitError.NO_BILL)
        if (people < 1) return BillSplitResult.Invalid(BillSplitError.NO_PEOPLE)
        if (people > MAX_PEOPLE) return BillSplitResult.Invalid(BillSplitError.TOO_MANY_PEOPLE)
        if (surchargeBps !in 0..MAX_SURCHARGE_BPS) return BillSplitResult.Invalid(BillSplitError.SURCHARGE_OUT_OF_RANGE)
        require(fixed.keys.all { it in 0 until people }) { "fixed index outside 0 until $people: ${fixed.keys}" }
        require(fixed.values.all { it >= 0 }) { "fixed amounts must not be negative: ${fixed.values}" }

        // Integer half-up rounding: + 5000 before dividing by 10000 basis points.
        val surchargeCents = (billCents * surchargeBps + 5_000) / 10_000
        val totalCents = billCents + surchargeCents
        val remainingCents = totalCents - fixed.values.sum()
        val open = (0 until people).filter { it !in fixed }

        if (remainingCents < 0) return BillSplitResult.Invalid(BillSplitError.OVER_ALLOCATED, -remainingCents)
        if (open.isEmpty() && remainingCents > 0) {
            return BillSplitResult.Invalid(BillSplitError.UNDER_ALLOCATED, remainingCents)
        }

        val shares = LongArray(people) { fixed[it] ?: 0L }
        if (open.isNotEmpty()) {
            val base = remainingCents / open.size
            val leftover = (remainingCents % open.size).toInt()
            open.forEachIndexed { position, person -> shares[person] = base + if (position < leftover) 1 else 0 }
        }
        return BillSplitResult.Split(totalCents, surchargeCents, shares.toList())
    }

    /** Dollars as typed (e.g. 18.5) to cents, rounding half up. */
    fun dollarsToCents(dollars: Double): Long = (dollars * 100).roundToLong()

    /** A percent as typed (e.g. 1.5) to basis points. */
    fun percentToBps(percent: Double): Int = (percent * 100).roundToLong().toInt()
}
