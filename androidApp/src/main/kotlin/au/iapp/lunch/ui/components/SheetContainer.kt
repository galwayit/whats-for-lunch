/**
 * @file SheetContainer.kt
 * @description Content chrome for a ModalBottomSheet: drag handle, title, content, and the
 * secondary + primary action row. The sheet itself comes from Material 3.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

object SheetContainerDefaults {
    val handleWidth: Dp = TokenSpacing.xl + TokenSpacing.sm
    val handleHeight: Dp = TokenSpacing.xs + 1.dp
}

/** A sheet action: label plus handler; [loading] and [enabled] pass through to the button. */
data class SheetAction(
    val label: String,
    val onClick: () -> Unit,
    val enabled: Boolean = true,
    val loading: Boolean = false,
)

/**
 * @param primaryAction Filled `primary` button at the end of the action row.
 * @param secondaryAction Text button before it, e.g. Cancel or Clear filters.
 */
@Composable
fun SheetContainer(
    title: String,
    modifier: Modifier = Modifier,
    primaryAction: SheetAction? = null,
    secondaryAction: SheetAction? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = LunchTheme.colors
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(colors.surface, LunchTheme.shapes.sheet)
            .padding(horizontal = TokenSpacing.pageWide)
            .padding(bottom = TokenSpacing.lg)
            .navigationBarsPadding(),
    ) {
        Box(
            modifier = Modifier
                .padding(vertical = TokenSpacing.sm + TokenSpacing.xs)
                .width(SheetContainerDefaults.handleWidth)
                .height(SheetContainerDefaults.handleHeight)
                .background(colors.hairlineStrong, LunchTheme.shapes.chip)
                .align(Alignment.CenterHorizontally),
        )
        LunchText(text = title, role = LunchTextRole.Title, modifier = Modifier.padding(bottom = TokenSpacing.md))
        content()
        if (primaryAction != null || secondaryAction != null) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = TokenSpacing.lg),
                horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm, Alignment.End),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (secondaryAction != null) {
                    LunchButton(
                        text = secondaryAction.label,
                        onClick = secondaryAction.onClick,
                        style = LunchButtonStyle.Text,
                        enabled = secondaryAction.enabled,
                        loading = secondaryAction.loading,
                    )
                }
                if (primaryAction != null) {
                    LunchButton(
                        text = primaryAction.label,
                        onClick = primaryAction.onClick,
                        style = LunchButtonStyle.Primary,
                        enabled = primaryAction.enabled,
                        loading = primaryAction.loading,
                    )
                }
            }
        }
    }
}

@LunchPreviews
@Composable
private fun SheetContainerPreview() {
    LunchPreviewSurface {
        SheetContainer(
            title = "Maximum price level",
            primaryAction = SheetAction("Apply", {}),
            secondaryAction = SheetAction("Clear filters", {}),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                Chip("$", selected = false, onClick = {})
                Chip("$$", selected = true, onClick = {})
                Chip("$$$", selected = false, onClick = {})
            }
        }
    }
}
