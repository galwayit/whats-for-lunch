/**
 * @file ScreenHeader.kt
 * @description Title row for pushed and modal screens: back or close control, title, and an
 * optional trailing action. Mirrors iosApp/.../Shared/ScreenHeader.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import au.iapp.lunch.R
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

/** How the header's leading control dismisses the screen. */
enum class HeaderDismiss { Back, Close, None }

@Composable
fun ScreenHeader(
    title: String,
    modifier: Modifier = Modifier,
    dismiss: HeaderDismiss = HeaderDismiss.Back,
    onDismiss: () -> Unit = {},
    trailing: (@Composable () -> Unit)? = null,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = TokenSpacing.sm, vertical = TokenSpacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        when (dismiss) {
            HeaderDismiss.Back -> HeaderIconButton(LunchIcon.ArrowBack, stringResource(R.string.action_back), onDismiss)
            HeaderDismiss.Close -> HeaderIconButton(LunchIcon.Close, stringResource(R.string.action_close), onDismiss)
            HeaderDismiss.None -> Box(Modifier.size(TokenSpacing.sm))
        }
        LunchText(
            text = title,
            role = LunchTextRole.Title,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = TokenSpacing.sm),
        )
        trailing?.invoke()
    }
}

/** A 44 dp icon control used by headers and inline rows. */
@Composable
fun HeaderIconButton(icon: LunchIcon, contentDescription: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val interactionSource = remember { MutableInteractionSource() }
    Box(
        modifier = modifier
            .size(TokenSize.touchTarget)
            .clip(LunchTheme.shapes.chip)
            .clickable(interactionSource = interactionSource, indication = ripple(bounded = false), role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        LunchIconView(icon = icon, contentDescription = contentDescription)
    }
}
