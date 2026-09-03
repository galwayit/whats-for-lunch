//
//  DartNumberFormat.swift
//  LunchApp
//
//  @file DartNumberFormat.swift
//  @description Dart-compatible fixed-point formatting, ported from the Kotlin core's
//  DartNumberFormat.kt. Dart's `double.toStringAsFixed(n)` rounds the EXACT binary value half-up
//  (2.25 -> "2.3", but 0.15 -> "0.1" because the nearest double is just below 0.15). Reason strings
//  such as "Highly rated (4.5/5)" must match the Kotlin core and the original Flutter app byte for
//  byte, so this reproduces the algorithm with integer arithmetic on the IEEE-754 mantissa instead of
//  `String(format:)`, which rounds ties to even.
//  @author AI Assistant
//  @date 2026-09-03
//

import Foundation

nonisolated extension Double {
    /// Dart `toStringAsFixed(1)` / Kotlin `toFixed1()`: one decimal, dot separator, no grouping.
    var fixed1: String { dartFixed(1) }

    /// Dart `toStringAsFixed(fractionDigits)` for 0...3 fraction digits. Non-finite values and
    /// magnitudes beyond 64-bit integer arithmetic fall back to `description`.
    func dartFixed(_ fractionDigits: Int) -> String {
        precondition((0...3).contains(fractionDigits), "fractionDigits must be 0...3")
        guard isFinite else { return description }
        let negative = self < 0 || (self == 0 && sign == .minus)
        let unit = Self.pow10[fractionDigits]
        guard let scaled = Self.roundedScaled(magnitude, scale: unit) else { return description }
        let whole = scaled / unit
        let frac = scaled % unit
        var body = String(whole)
        if fractionDigits > 0 {
            let digits = String(frac)
            body += "." + String(repeating: "0", count: fractionDigits - digits.count) + digits
        }
        // Dart keeps the sign of a negative input ("-0.0"), matching JavaScript's toFixed.
        return negative ? "-" + body : body
    }

    private static let pow10: [UInt64] = [1, 10, 100, 1000]

    /// round-half-up(value * scale) computed exactly from the binary representation, or nil when the
    /// value is too large for 64-bit arithmetic.
    private static func roundedScaled(_ value: Double, scale: UInt64) -> UInt64? {
        let bits = value.bitPattern
        let exponentField = Int((bits >> 52) & 0x7FF)
        let fraction = bits & 0xF_FFFF_FFFF_FFFF
        let mantissa: UInt64
        let exponent: Int
        if exponentField == 0 {
            mantissa = fraction // subnormal
            exponent = -1074
        } else {
            mantissa = fraction | (1 << 52)
            exponent = exponentField - 1075
        }
        if mantissa == 0 { return 0 }
        let scaledMantissa = mantissa * scale // < 2^53 * 10^3 < 2^64
        if exponent >= 0 {
            // Integer value; guard against overflow of the shift.
            if exponent > 63 || scaledMantissa > (UInt64.max >> UInt64(exponent)) { return nil }
            return scaledMantissa << UInt64(exponent)
        }
        let k = -exponent
        // value * scale = scaledMantissa / 2^k; round half up on the exact quotient.
        if k >= 64 { return 0 } // scaledMantissa < 2^64 <= 2^(k-1): below one half
        let quotient = scaledMantissa >> UInt64(k)
        let halfBitSet = (scaledMantissa >> UInt64(k - 1)) & 1 == 1
        return halfBitSet ? quotient + 1 : quotient
    }
}
