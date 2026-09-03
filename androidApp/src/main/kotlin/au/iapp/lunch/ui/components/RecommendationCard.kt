/**
 * @file RecommendationCard.kt
 * @description The AI result card on Home: photo, "TODAY'S PICK" eyebrow with a confidence chip,
 * up to three reasons, Directions and Log actions, and the Why / More / Reject text row.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
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
import au.iapp.lunch.ui.theme.LunchColors
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

/** Bands for the engine's 0..1 confidence score. */
enum class Confidence {
    High, Medium, Low;

    companion object {
        const val HIGH_FROM = 0.8f
        const val MEDIUM_FROM = 0.6f

        fun from(score: Float): Confidence = when {
            score >= HIGH_FROM -> High
            score >= MEDIUM_FROM -> Medium
            else -> Low
        }
    }
}

object RecommendationCardDefaults {
    const val TEST_TAG = "recommendation_card"
    const val MAX_REASONS = 3
    val reasonIconSize: Dp = TokenSize.iconDefault - TokenSpacing.sm
}

/**
 * @param confidence The engine's score in 0..1, shown as a High / Medium / Low chip.
 * @param reasons Engine reason strings; only the first three are shown.
 */
@Composable
fun RecommendationCard(
    restaurant: Restaurant,
    reasons: List<String>,
    confidence: Float,
    onDirections: () -> Unit,
    onLogMeal: () -> Unit,
    onWhy: () -> Unit,
    onShowMore: () -> Unit,
    onReject: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LunchTheme.colors
    LunchCard(
        modifier = modifier.testTag(RecommendationCardDefaults.TEST_TAG),
        header = {
            RestaurantPhoto(url = restaurant.photoUrl, contentDescription = null, modifier = Modifier.fillMaxSize())
        },
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            LunchText(
                text = stringResource(R.string.home_result_eyebrow),
                role = LunchTextRole.Label,
                color = colors.primary,
                modifier = Modifier.weight(1f),
            )
            ConfidenceChip(confidence = Confidence.from(confidence))
        }
        LunchText(
            text = restaurant.name,
            role = LunchTextRole.Title,
            modifier = Modifier.padding(top = TokenSpacing.xs),
        )
        LunchText(
            text = listOfNotNull(restaurant.priceLabel, restaurant.location).joinToString(RestaurantCardDefaults.META_SEPARATOR),
            role = LunchTextRole.Caption,
            color = colors.textSecondary,
        )
        Column(
            modifier = Modifier.padding(vertical = TokenSpacing.md),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs),
        ) {
            reasons.take(RecommendationCardDefaults.MAX_REASONS).forEach { reason ->
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm), verticalAlignment = Alignment.CenterVertically) {
                    LunchIconView(icon = LunchIcon.Check, size = RecommendationCardDefaults.reasonIconSize, tint = colors.success)
                    LunchText(text = reason, role = LunchTextRole.BodySmall)
                }
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            LunchButton(
                text = stringResource(R.string.action_directions),
                onClick = onDirections,
                modifier = Modifier.weight(1f),
                style = LunchButtonStyle.Secondary,
                icon = LunchIcon.Directions,
            )
            LunchButton(
                text = stringResource(R.string.action_log_this_meal),
                onClick = onLogMeal,
                modifier = Modifier.weight(1f),
                style = LunchButtonStyle.Primary,
            )
        }
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = TokenSpacing.xs),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            LunchButton(stringResource(R.string.home_result_why), onWhy, style = LunchButtonStyle.Text)
            LunchButton(stringResource(R.string.home_result_more), onShowMore, style = LunchButtonStyle.Text)
            LunchButton(stringResource(R.string.home_result_reject), onReject, style = LunchButtonStyle.Text)
        }
    }
}

@Composable
private fun ConfidenceChip(confidence: Confidence, modifier: Modifier = Modifier) {
    val colors = LunchTheme.colors
    val tint = when (confidence) {
        Confidence.High -> colors.success
        Confidence.Medium -> colors.warning
        Confidence.Low -> colors.textSecondary
    }
    val text = stringResource(
        when (confidence) {
            Confidence.High -> R.string.home_confidence_high
            Confidence.Medium -> R.string.home_confidence_medium
            Confidence.Low -> R.string.home_confidence_low
        },
    )
    LunchText(
        text = text,
        role = LunchTextRole.Label,
        color = tint,
        modifier = modifier
            .background(tint.copy(alpha = LunchColors.SOFT_TINT_ALPHA), LunchTheme.shapes.chip)
            .padding(horizontal = TokenSpacing.sm, vertical = TokenSpacing.xs),
    )
}

@LunchPreviews
@Composable
private fun RecommendationCardPreview() {
    LunchPreviewSurface {
        RecommendationCard(
            restaurant = PreviewData.greenGardenBowls,
            reasons = PreviewData.reasons,
            confidence = 0.92f,
            onDirections = {},
            onLogMeal = {},
            onWhy = {},
            onShowMore = {},
            onReject = {},
            modifier = Modifier.fillMaxWidth(),
        )
    }
}
