/**
 * @file InviteQrCode.kt
 * @description Encodes a group invite URL as a QR code on the device (design/screens.md
 * section 10): error correction M and a 4-module quiet zone, one pixel per module. Pure JVM code
 * so the unit tests can decode what the sheet draws.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.ui.features.groups

import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.common.BitMatrix
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel

/** Test ids from design/screens.md section 10. */
object InviteQrDefaults {
    const val IMAGE_TAG = "invite_qr_image"

    /** Share of the sheet's width the code takes; big enough to scan from arm's length. */
    const val WIDTH_FRACTION = 0.8f
}

object InviteQrCode {
    /** The QR spec's minimum quiet zone; cameras struggle to find the code with less. */
    const val QUIET_ZONE_MODULES = 4

    /**
     * @description Encodes [url] as a QR code with error correction M and a
     * [QUIET_ZONE_MODULES] margin on every side. Asking for size 0 makes ZXing return the
     * smallest matrix: exactly one cell per module, so the caller scales it without resampling.
     * @param url The invite link; must not be empty.
     * @returns A square matrix where `true` is a dark module.
     * @throws IllegalArgumentException When [url] is empty.
     * @throws com.google.zxing.WriterException When the text does not fit in a QR code.
     */
    fun encode(url: String): BitMatrix = QRCodeWriter().encode(
        url,
        BarcodeFormat.QR_CODE,
        0,
        0,
        mapOf(
            EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M,
            EncodeHintType.MARGIN to QUIET_ZONE_MODULES,
        ),
    )

    /**
     * @description Flattens [matrix] into ARGB pixels, row by row, for `Bitmap.createBitmap`.
     * @param darkArgb Colour of the dark modules.
     * @param lightArgb Colour of the light modules and the quiet zone.
     * @returns `width * height` pixels.
     */
    fun pixels(matrix: BitMatrix, darkArgb: Int, lightArgb: Int): IntArray {
        val width = matrix.width
        return IntArray(width * matrix.height) { index ->
            if (matrix[index % width, index / width]) darkArgb else lightArgb
        }
    }
}
