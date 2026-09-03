/**
 * @file UpsellRow.kt
 * @description Inline Lunch Pro gate: a soft container with a lock, the gate title carrying a
 * ProBadge, a one-line body, and the primary call to action.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

/**
 * @param ctaLabel The button label, e.g. "See Lunch Pro" or "Start free trial".
 */
@Composable
fun UpsellRow(
    title: String,
    body: String,
    ctaLabel: String,
    onCta: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LunchTheme.colors
    val shape = LunchTheme.shapes.container
    Column(
        modifier = modifier
            .background(colors.primarySoft, shape)
            .border(ComponentDefaults.hairlineWidth, colors.hairline, shape)
            .padding(TokenSpacing.md),
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm + TokenSpacing.xs), verticalAlignment = Alignment.Top) {
            LunchIconView(icon = LunchIcon.Lock, tint = colors.primary)
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm), verticalAlignment = Alignment.CenterVertically) {
                    LunchText(text = title, role = LunchTextRole.Heading, modifier = Modifier.weight(1f, fill = false))
                    ProBadge()
                }
                LunchText(text = body, role = LunchTextRole.BodySmall, color = colors.textSecondary)
            }
        }
        LunchButton(text = ctaLabel, onClick = onCta, modifier = Modifier.fillMaxWidth(), style = LunchButtonStyle.Primary)
    }
}

@LunchPreviews
@Composable
private fun UpsellRowPreview() {
    LunchPreviewSurface {
        UpsellRow(
            title = stringResource(R.string.gate_host_title),
            body = stringResource(R.string.gate_host_body),
            ctaLabel = stringResource(R.string.gate_host_cta),
            onCta = {},
            modifier = Modifier.fillMaxWidth(),
        )
    }
}
