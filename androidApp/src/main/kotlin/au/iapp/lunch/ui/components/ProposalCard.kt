/**
 * @file ProposalCard.kt
 * @description One of the host's proposed restaurants: a short photo, name and rating, meta
 * line, and the Choose action.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.preview.PreviewData
import au.iapp.lunch.ui.preview.Restaurant
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

object ProposalCardDefaults {
    val photoHeight: Dp = TokenSpacing.xxl * 3

    fun testTag(index: Int) = "proposal_card_$index"
    fun chooseTag(index: Int) = "proposal_card_${index}_choose"
}

/**
 * @param index Position in the proposal list; drives the test tags.
 * @param choosing True while this proposal's choice is being saved.
 */
@Composable
fun ProposalCard(
    restaurant: Restaurant,
    index: Int,
    onChoose: () -> Unit,
    modifier: Modifier = Modifier,
    choosing: Boolean = false,
) {
    val colors = LunchTheme.colors
    LunchCard(
        modifier = modifier.testTag(ProposalCardDefaults.testTag(index)),
        header = { RestaurantPhoto(url = restaurant.photoUrl, contentDescription = null, modifier = Modifier.fillMaxSize()) },
        headerHeight = ProposalCardDefaults.photoHeight,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            LunchText(text = restaurant.name, role = LunchTextRole.Heading, modifier = Modifier.weight(1f), maxLines = 1)
            restaurant.rating?.let { RatingLabel(rating = it) }
        }
        LunchText(
            text = restaurantMeta(restaurant),
            role = LunchTextRole.Caption,
            color = colors.textSecondary,
            modifier = Modifier.padding(top = TokenSpacing.xs, bottom = TokenSpacing.md),
        )
        LunchButton(
            text = stringResource(R.string.group_proposals_choose),
            onClick = onChoose,
            modifier = Modifier
                .fillMaxWidth()
                .testTag(ProposalCardDefaults.chooseTag(index)),
            style = LunchButtonStyle.Primary,
            loading = choosing,
        )
    }
}

@LunchPreviews
@Composable
private fun ProposalCardPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            ProposalCard(PreviewData.greenGardenBowls, index = 0, onChoose = {}, modifier = Modifier.fillMaxWidth())
            ProposalCard(PreviewData.sakuraSushi, index = 1, onChoose = {}, modifier = Modifier.fillMaxWidth(), choosing = true)
        }
    }
}
