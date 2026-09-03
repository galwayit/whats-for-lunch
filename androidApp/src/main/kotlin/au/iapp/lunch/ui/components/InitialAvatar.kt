/**
 * @file InitialAvatar.kt
 * @description A disc showing the first letter of a name, tinted 10% with a 20% border, used for
 * guests and hosts who have no photo.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchColors
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

/**
 * @param name The full display name; only its first character is drawn, but the whole name is
 * announced.
 * @param tint The disc colour; defaults to `primary`.
 * @param textRole Drop to [LunchTextRole.Caption] for small stacked avatars.
 */
@Composable
fun InitialAvatar(
    name: String,
    modifier: Modifier = Modifier,
    size: Dp = TokenSize.touchTarget,
    tint: Color = LunchTheme.colors.primary,
    textRole: LunchTextRole = LunchTextRole.Heading,
) {
    Box(
        modifier = modifier
            .size(size)
            .background(tint.copy(alpha = LunchColors.SOFT_TINT_ALPHA), LunchTheme.shapes.chip)
            .border(ComponentDefaults.hairlineWidth, tint.copy(alpha = ComponentDefaults.AVATAR_BORDER_ALPHA), LunchTheme.shapes.chip)
            .semantics { contentDescription = name },
        contentAlignment = Alignment.Center,
    ) {
        LunchText(
            text = name.firstOrNull()?.uppercaseChar()?.toString().orEmpty(),
            role = textRole,
            color = tint,
            maxLines = 1,
        )
    }
}

@LunchPreviews
@Composable
private fun InitialAvatarPreview() {
    LunchPreviewSurface {
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            InitialAvatar("Ray")
            InitialAvatar("Mei", tint = LunchTheme.colors.action)
            InitialAvatar("Tom", size = TokenSize.iconDefault + TokenSpacing.sm, textRole = LunchTextRole.Caption)
        }
    }
}
