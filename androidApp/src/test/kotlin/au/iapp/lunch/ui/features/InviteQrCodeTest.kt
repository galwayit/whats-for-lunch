/**
 * @file InviteQrCodeTest.kt
 * @description Checks the invite QR code the group detail sheet draws: it decodes back to the
 * invite URL with ZXing's reader, uses error correction M, and keeps a light 4-module quiet zone.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.ui.features

import androidx.compose.ui.graphics.toArgb
import au.iapp.lunch.ui.features.groups.InviteQrCode
import au.iapp.lunch.ui.theme.TokenColors
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.ResultMetadataType
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class InviteQrCodeTest {

    private val url = "https://lunch.iapp.au/i/ABC123"
    private val dark = TokenColors.Light.text.toArgb()
    private val light = TokenColors.Light.surface.toArgb()

    /** Upscales the one-pixel-per-module image the way the sheet does, so the reader sees modules, not pixels. */
    private fun scaled(pixels: IntArray, size: Int, scale: Int): IntArray =
        IntArray(size * scale * size * scale) { index ->
            val x = (index % (size * scale)) / scale
            val y = (index / (size * scale)) / scale
            pixels[y * size + x]
        }

    @Test
    fun should_decode_to_the_invite_url_when_read_back_with_zxing() {
        val matrix = InviteQrCode.encode(url)
        val scale = 8
        val side = matrix.width * scale
        val pixels = scaled(InviteQrCode.pixels(matrix, dark, light), matrix.width, scale)

        val bitmap = BinaryBitmap(HybridBinarizer(RGBLuminanceSource(side, side, pixels)))
        val result = QRCodeReader().decode(bitmap, mapOf(DecodeHintType.TRY_HARDER to true))

        assertEquals(url, result.text)
        assertEquals(ErrorCorrectionLevel.M.toString(), result.resultMetadata[ResultMetadataType.ERROR_CORRECTION_LEVEL])
    }

    @Test
    fun should_keep_a_light_quiet_zone_of_four_modules_when_encoded() {
        val matrix = InviteQrCode.encode(url)
        val margin = InviteQrCode.QUIET_ZONE_MODULES
        assertEquals(4, margin)
        assertEquals("one cell per module", matrix.width, matrix.height)

        for (y in 0 until matrix.height) {
            for (x in 0 until matrix.width) {
                val inQuietZone = x < margin || y < margin || x >= matrix.width - margin || y >= matrix.height - margin
                if (inQuietZone) assertFalse("module ($x, $y) must be light", matrix[x, y])
            }
        }
        // The finder pattern starts right after the quiet zone, so the margin is exactly four, not more.
        assertEquals(true, matrix[margin, margin])
    }

    @Test
    fun should_place_the_token_colours_when_flattening_to_pixels() {
        val matrix = InviteQrCode.encode(url)
        val pixels = InviteQrCode.pixels(matrix, dark, light)
        val margin = InviteQrCode.QUIET_ZONE_MODULES

        assertEquals(light, pixels[0])
        assertEquals(dark, pixels[margin * matrix.width + margin])
        assertEquals(matrix.width * matrix.height, pixels.size)
    }
}
