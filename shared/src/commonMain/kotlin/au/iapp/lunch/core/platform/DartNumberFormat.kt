package au.iapp.lunch.core.platform

/*
 * Dart-compatible fixed-point formatting.
 *
 * Dart's `double.toStringAsFixed(n)` rounds the EXACT binary value half-up
 * (ties away from zero), e.g. 2.25 -> "2.3" but 0.15 -> "0.1" because the
 * double nearest 0.15 is slightly below it. Reason strings such as
 * "Highly rated (4.5/5)" must match the Flutter app byte for byte, so this
 * reproduces that algorithm with integer arithmetic on the IEEE-754 mantissa
 * instead of relying on platform formatters (which are round-half-even).
 */

/** Dart `toStringAsFixed(1)`. */
internal fun Double.toFixed1(): String = toStringAsFixed(1)

/** Dart `toStringAsFixed(2)`. */
internal fun Double.toFixed2(): String = toStringAsFixed(2)

/**
 * Dart `double.toStringAsFixed(fractionDigits)` for 0..3 fraction digits and
 * magnitudes below 2^63 / 10^digits. Non-finite values fall back to
 * [Double.toString].
 */
internal fun Double.toStringAsFixed(fractionDigits: Int): String {
    require(fractionDigits in 0..3) { "fractionDigits must be 0..3" }
    if (!isFinite()) return toString()
    val negative = this < 0.0 || (this == 0.0 && 1.0 / this < 0.0)
    val magnitude = kotlin.math.abs(this)
    val scaledInt = roundedScaled(magnitude, POW10[fractionDigits]) ?: return toString()
    val unit = POW10[fractionDigits]
    val whole = scaledInt / unit
    val frac = scaledInt % unit
    val body = if (fractionDigits == 0) {
        whole.toString()
    } else {
        whole.toString() + "." + frac.toString().padStart(fractionDigits, '0')
    }
    // Dart prints "-0.0" for negative zero only when the result is still zero;
    // it keeps the sign of the input, matching JavaScript's toFixed.
    return if (negative && scaledInt != 0L) "-$body" else if (negative && this != 0.0) "-$body" else body
}

private val POW10 = longArrayOf(1L, 10L, 100L, 1000L)

/**
 * Returns round-half-up(|value| * scale) computed exactly from the binary
 * representation, or null when the value is too large for Long arithmetic.
 */
private fun roundedScaled(value: Double, scale: Long): Long? {
    val bits = value.toRawBits()
    val exponentField = ((bits ushr 52) and 0x7FFL).toInt()
    val fraction = bits and 0xFFFFFFFFFFFFFL
    val mantissa: Long
    val exponent: Int
    if (exponentField == 0) {
        mantissa = fraction // subnormal
        exponent = -1074
    } else {
        mantissa = fraction or (1L shl 52)
        exponent = exponentField - 1075
    }
    if (mantissa == 0L) return 0L
    val scaledMantissa = mantissa * scale // < 2^53 * 10^3 < 2^63
    if (exponent >= 0) {
        // Integer value; guard against overflow of the shift.
        if (exponent > 62 || scaledMantissa > (Long.MAX_VALUE shr exponent)) return null
        return scaledMantissa shl exponent
    }
    val k = -exponent
    // value * scale = scaledMantissa / 2^k ; round half up on the exact quotient.
    if (k >= 63) return 0L // scaledMantissa < 2^63 <= 2^(k-1): below one half
    val quotient = scaledMantissa ushr k
    val halfBitSet = ((scaledMantissa ushr (k - 1)) and 1L) == 1L
    return if (halfBitSet) quotient + 1 else quotient
}
