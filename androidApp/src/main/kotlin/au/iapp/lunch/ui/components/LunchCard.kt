/**
 * @file LunchCard.kt
 * @description The base container: 16dp corners, hairline border, the `card` elevation, and an
 * optional full-bleed image header.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchElevation
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing
import au.iapp.lunch.ui.theme.pressable

object LunchCardDefaults {
    /** Height of the image header. */
    val headerHeight: Dp = TokenSpacing.xxl * 4
    val contentPadding: PaddingValues = PaddingValues(TokenSpacing.md)
}

/**
 * @param onClick Makes the whole card tappable (with press feedback) when set.
 * @param header Optional full-width slot above the content, clipped to the card corners.
 * @param headerHeight Height of the header slot.
 * @param content Laid out in a column inside [contentPadding].
 */
@Composable
fun LunchCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    header: (@Composable BoxScope.() -> Unit)? = null,
    headerHeight: Dp = LunchCardDefaults.headerHeight,
    contentPadding: PaddingValues = LunchCardDefaults.contentPadding,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = LunchTheme.colors
    val shape = LunchTheme.shapes.container
    val interactionSource = remember { MutableInteractionSource() }
    val shadowColor = colors.text.copy(alpha = LunchElevation.card.colorAlpha)

    Column(
        modifier = modifier
            .then(if (onClick != null) Modifier.pressable(interactionSource) else Modifier)
            .shadow(LunchElevation.card.elevation, shape, ambientColor = shadowColor, spotColor = shadowColor)
            .clip(shape)
            .background(colors.surface)
            .border(ComponentDefaults.hairlineWidth, colors.hairline, shape)
            .then(
                if (onClick != null) {
                    Modifier.clickable(interactionSource = interactionSource, indication = ripple(), onClick = onClick)
                } else {
                    Modifier
                },
            ),
    ) {
        if (header != null) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(headerHeight),
                content = header,
            )
        }
        Column(modifier = Modifier.padding(contentPadding), content = content)
    }
}

@LunchPreviews
@Composable
private fun LunchCardPreview() {
    LunchPreviewSurface {
        Column(modifier = Modifier.fillMaxWidth()) {
            LunchCard(modifier = Modifier.fillMaxWidth(), onClick = {}) {
                LunchText("Plain card", LunchTextRole.Heading)
                LunchText("Tap anywhere on it.", LunchTextRole.BodySmall, color = LunchTheme.colors.textSecondary)
            }
            Box(modifier = Modifier.height(TokenSpacing.md))
            LunchCard(
                modifier = Modifier.fillMaxWidth(),
                header = { RestaurantPhoto(url = null, contentDescription = null, modifier = Modifier.fillMaxWidth()) },
            ) {
                LunchText("Card with header", LunchTextRole.Heading)
            }
        }
    }
}
