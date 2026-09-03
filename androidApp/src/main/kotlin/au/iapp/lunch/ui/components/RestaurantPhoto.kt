/**
 * @file RestaurantPhoto.kt
 * @description A cropped restaurant photo loaded with Coil, drawn over a `primarySoft`
 * placeholder with the restaurant icon so the slot never flashes empty.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalInspectionMode
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import coil3.compose.AsyncImage

object RestaurantPhotoDefaults {
    val placeholderIconSize: Dp = TokenSize.iconDefault * 2
}

/**
 * @param url The photo URL; null (or a load failure) leaves the placeholder visible.
 * @param contentDescription Null when the photo is decorative next to the restaurant name.
 */
@Composable
fun RestaurantPhoto(
    url: String?,
    contentDescription: String?,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier.background(LunchTheme.colors.primarySoft),
        contentAlignment = Alignment.Center,
    ) {
        LunchIconView(
            icon = LunchIcon.Restaurant,
            size = RestaurantPhotoDefaults.placeholderIconSize,
            tint = LunchTheme.colors.primary,
        )
        // Previews have no network; keep the placeholder instead of a blank image.
        if (url != null && !LocalInspectionMode.current) {
            AsyncImage(
                model = url,
                contentDescription = contentDescription,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
            )
        }
    }
}

@LunchPreviews
@Composable
private fun RestaurantPhotoPreview() {
    LunchPreviewSurface {
        RestaurantPhoto(
            url = null,
            contentDescription = null,
            modifier = Modifier
                .fillMaxWidth()
                .height(LunchCardDefaults.headerHeight),
        )
    }
}
