/**
 * @file RestaurantDetailSheet.kt
 * @description Content of the restaurant detail bottom sheet: photo, meta, open state, actions
 * and reviews. Mirrors iosApp/.../Discover/RestaurantDetailSheet.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.discover

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import au.iapp.lunch.R
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.RestaurantReview
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.RatingLabel
import au.iapp.lunch.ui.components.RestaurantPhoto
import au.iapp.lunch.ui.components.RestaurantCardDefaults
import au.iapp.lunch.ui.components.dartOneDecimal
import au.iapp.lunch.ui.features.shared.HeaderIconButton
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.SectionTitle
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun RestaurantDetailSheet(
    restaurant: Restaurant,
    reviews: LoadState<List<RestaurantReview>>,
    isFavourite: Boolean,
    onFavourite: () -> Unit,
    onDirections: () -> Unit,
    onOpenMaps: () -> Unit,
    onLogMeal: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LunchTheme.colors
    Column(
        modifier = modifier
            .verticalScroll(rememberScrollState())
            .padding(horizontal = TokenSpacing.page)
            .navigationBarsPadding()
            .padding(bottom = TokenSpacing.lg),
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
    ) {
        RestaurantPhoto(
            url = restaurant.photoUrl,
            contentDescription = restaurant.name,
            modifier = Modifier
                .fillMaxWidth()
                .height(TokenSize.heroButton * 0.8f)
                .clip(LunchTheme.shapes.container),
        )
        Row(verticalAlignment = Alignment.Top) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
                LunchText(text = restaurant.name, role = LunchTextRole.Title)
                // The open state has its own coloured line below, so it is left out of the meta here.
                LunchText(text = detailMeta(restaurant), role = LunchTextRole.BodySmall, color = colors.textSecondary)
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm), verticalAlignment = Alignment.CenterVertically) {
                    restaurant.rating?.let { RatingLabel(rating = it) }
                    LunchText(
                        text = stringResource(if (restaurant.isOpenNow) R.string.discover_detail_open_now else R.string.discover_detail_closed),
                        role = LunchTextRole.Caption,
                        color = if (restaurant.isOpenNow) colors.success else colors.danger,
                    )
                }
                restaurant.address?.let { LunchText(text = it, role = LunchTextRole.Caption, color = colors.textSecondary) }
            }
            HeaderIconButton(
                icon = LunchIcon.Favorite,
                contentDescription = stringResource(if (isFavourite) R.string.a11y_remove_favourite else R.string.a11y_add_favourite),
                onClick = onFavourite,
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            LunchButton(text = stringResource(R.string.action_directions), onClick = onDirections, icon = LunchIcon.Directions, style = LunchButtonStyle.Secondary, modifier = Modifier.weight(1f))
            LunchButton(text = stringResource(R.string.discover_detail_open_maps), onClick = onOpenMaps, icon = LunchIcon.Map, style = LunchButtonStyle.Secondary, modifier = Modifier.weight(1f))
        }
        LunchButton(text = stringResource(R.string.action_log_this_meal), onClick = onLogMeal, icon = LunchIcon.Restaurant, modifier = Modifier.fillMaxWidth())
        SectionTitle(text = stringResource(R.string.discover_detail_reviews))
        when (reviews) {
            LoadState.Idle, LoadState.Loading -> LunchText(text = stringResource(R.string.a11y_loading), role = LunchTextRole.BodySmall, color = colors.textSecondary)
            is LoadState.Failed -> LunchText(text = stringResource(R.string.discover_detail_no_reviews), role = LunchTextRole.BodySmall, color = colors.textSecondary)
            is LoadState.Loaded -> if (reviews.value.isEmpty()) {
                LunchText(text = stringResource(R.string.discover_detail_no_reviews), role = LunchTextRole.BodySmall, color = colors.textSecondary)
            } else {
                reviews.value.forEach { review -> ReviewRow(review) }
            }
        }
    }
}

/** "$$ - 0.2 km - Salads", without the open state. */
@Composable
private fun detailMeta(restaurant: Restaurant): String = listOfNotNull(
    restaurant.priceLevel?.let { level -> "\u0024".repeat(level.coerceIn(1, 4)) },
    restaurant.distanceFromUser?.let { stringResource(R.string.a11y_distance_km, dartOneDecimal(it)) },
    restaurant.cuisineType,
).joinToString(RestaurantCardDefaults.META_SEPARATOR)

@Composable
private fun ReviewRow(review: RestaurantReview) {
    val colors = LunchTheme.colors
    Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm), verticalAlignment = Alignment.CenterVertically) {
            LunchText(text = review.authorName, role = LunchTextRole.Heading, modifier = Modifier.weight(1f))
            RatingLabel(rating = review.rating.toDouble())
        }
        review.text?.let { LunchText(text = it, role = LunchTextRole.BodySmall, color = colors.textSecondary) }
        LunchText(text = review.relativeTimeDescription, role = LunchTextRole.Caption, color = colors.textSecondary)
    }
}
