/**
 * @file InviteQrSheet.kt
 * @description The "Scan to join" sheet opened from `Show QR code` on the group detail screen
 * (design/screens.md section 10): the invite URL as a QR code, the scan hint, and the link text.
 * The code is always dark modules on a light background, whatever the theme, so any camera reads it.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.ui.features.groups

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import au.iapp.lunch.R
import au.iapp.lunch.ui.components.SheetContainer
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenColors
import au.iapp.lunch.ui.theme.TokenSpacing

/**
 * @param inviteUrl The link to encode; the screen only offers the sheet when it is not empty.
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalComposeUiApi::class)
@Composable
fun InviteQrSheet(inviteUrl: String, onDismiss: () -> Unit) {
    val colors = LunchTheme.colors
    val qr = rememberInviteQrBitmap(inviteUrl)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        modifier = Modifier.statusBarsPadding(),
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = colors.surface,
        dragHandle = null,
    ) {
        SheetContainer(
            title = stringResource(R.string.group_qr_title),
            modifier = Modifier
                // The sheet is its own window, so the root's resource-id exposure stops here.
                .semantics { testTagsAsResourceId = true }
                .verticalScroll(rememberScrollState()),
        ) {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
            ) {
                Image(
                    bitmap = qr,
                    contentDescription = inviteUrl,
                    // Nearest-neighbour scaling keeps every module a sharp square.
                    filterQuality = FilterQuality.None,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier
                        .fillMaxWidth(InviteQrDefaults.WIDTH_FRACTION)
                        .aspectRatio(1f)
                        .testTag(InviteQrDefaults.IMAGE_TAG),
                )
                LunchText(
                    text = stringResource(R.string.group_qr_body),
                    role = LunchTextRole.BodySmall,
                    color = colors.textSecondary,
                    modifier = Modifier.fillMaxWidth(),
                )
                LunchText(text = inviteUrl, role = LunchTextRole.BodySmall, modifier = Modifier.fillMaxWidth())
            }
        }
    }
}

/**
 * The QR bitmap for [url], encoded once per URL. The colours are the light theme's darkest text
 * and its white surface in both themes: a dark-mode (inverted) code does not scan on many cameras.
 */
@Composable
private fun rememberInviteQrBitmap(url: String): ImageBitmap = remember(url) {
    val matrix = InviteQrCode.encode(url)
    val pixels = InviteQrCode.pixels(
        matrix,
        darkArgb = TokenColors.Light.text.toArgb(),
        lightArgb = TokenColors.Light.surface.toArgb(),
    )
    Bitmap.createBitmap(pixels, matrix.width, matrix.height, Bitmap.Config.ARGB_8888).asImageBitmap()
}
