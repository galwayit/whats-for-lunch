/**
 * @file SubscriptionRow.kt
 * @description Profile row for an active Lunch Pro subscription: badge, plan, renewal or end
 * date, and a chevron into the store's subscription management.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
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

/** Whether the subscription auto-renews or has been cancelled and runs out. */
enum class Renewal { Renews, Ends }

/**
 * @param planName "Yearly" or "Monthly".
 * @param date The formatted renewal or end date.
 * @param onManage Opens the store's subscription management.
 */
@Composable
fun SubscriptionRow(
    planName: String,
    renewal: Renewal,
    date: String,
    onManage: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LunchTheme.colors
    val dateLine = stringResource(
        if (renewal == Renewal.Renews) R.string.profile_pro_active_renews else R.string.profile_pro_active_expires,
        date,
    )
    LunchCard(modifier = modifier, onClick = onManage) {
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm + TokenSpacing.xs), verticalAlignment = Alignment.CenterVertically) {
            ProBadge()
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
                LunchText(text = stringResource(R.string.profile_pro_active_title, planName), role = LunchTextRole.Heading)
                LunchText(text = dateLine, role = LunchTextRole.Caption, color = colors.textSecondary)
            }
            LunchIconView(icon = LunchIcon.ChevronRight, tint = colors.textSecondary)
        }
    }
}

@LunchPreviews
@Composable
private fun SubscriptionRowPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            SubscriptionRow("Yearly", Renewal.Renews, "3 Sep 2027", onManage = {}, modifier = Modifier.fillMaxWidth())
            SubscriptionRow("Monthly", Renewal.Ends, "3 Oct 2026", onManage = {}, modifier = Modifier.fillMaxWidth())
        }
    }
}
