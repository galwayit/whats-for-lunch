/**
 * @file InviteShareRow.kt
 * @description The host's invite link in a raised box plus the Share invite button.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.preview.PreviewData
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

object InviteShareRowDefaults {
    const val LINK_TEST_TAG = "invite_link_text"
}

/**
 * @param inviteUrl The full https link; shown verbatim so it can be read back in tests.
 */
@Composable
fun InviteShareRow(
    inviteUrl: String,
    onShare: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LunchTheme.colors
    val linkLabel = stringResource(R.string.a11y_invite_link)
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm + TokenSpacing.xs)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(colors.surfaceRaised, LunchTheme.shapes.toast)
                .padding(horizontal = TokenSpacing.md, vertical = TokenSpacing.sm + TokenSpacing.xs),
            horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            LunchIconView(icon = LunchIcon.Mail, tint = colors.textSecondary)
            LunchText(
                text = inviteUrl,
                role = LunchTextRole.BodySmall,
                modifier = Modifier
                    .weight(1f)
                    .testTag(InviteShareRowDefaults.LINK_TEST_TAG)
                    .semantics { contentDescription = "$linkLabel $inviteUrl" },
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        LunchButton(
            text = stringResource(R.string.group_detail_share),
            onClick = onShare,
            modifier = Modifier.fillMaxWidth(),
            style = LunchButtonStyle.Primary,
            icon = LunchIcon.Share,
        )
    }
}

@LunchPreviews
@Composable
private fun InviteShareRowPreview() {
    LunchPreviewSurface {
        InviteShareRow(inviteUrl = PreviewData.INVITE_URL, onShare = {}, modifier = Modifier.fillMaxWidth())
    }
}
