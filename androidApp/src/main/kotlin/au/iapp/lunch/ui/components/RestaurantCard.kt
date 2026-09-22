/**
 * @file RestaurantCard.kt
 * @description Discover-list card: photo with favourite button, name and rating, cuisine tags,
 * price and distance, and an optional badge. Test tags follow design/screens.md.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.preview.PreviewData
import au.iapp.lunch.ui.preview.Restaurant
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing
import au.iapp.lunch.ui.theme.pressable

object RestaurantCardDefaults {
    val ratingIconSize: Dp = TokenSize.iconDefault - TokenSpacing.sm
    const val META_SEPARATOR = " · "

    fun testTag(index: Int) = "restaurant_card_$index"
    fun favouriteTag(index: Int, selected: Boolean) =
        if (selected) "favourite_button_${index}_selected" else "favourite_button_$index"
}

/**
 * @param index Position in the list; drives the `restaurant_card_{i}` and
 * `favourite_button_{i}` test tags.
 * @param badge Optional label such as "TODAY'S PICK" drawn over the photo.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun RestaurantCard(
    restaurant: Restaurant,
    index: Int,
    isFavourite: Boolean,
    onClick: () -> Unit,
    onFavouriteClick: () -> Unit,
    modifier: Modifier = Modifier,
    badge: String? = null,
) {
    val colors = LunchTheme.colors
    LunchCard(
        modifier = modifier.testTag(RestaurantCardDefaults.testTag(index)),
        onClick = onClick,
        header = {
            RestaurantPhoto(url = restaurant.photoUrl, contentDescription = null, modifier = Modifier.fillMaxSize())
            if (badge != null) {
                BadgeLabel(
                    text = badge,
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(TokenSpacing.sm),
                )
            }
            FavouriteButton(
                selected = isFavourite,
                index = index,
                onClick = onFavouriteClick,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(TokenSpacing.sm),
            )
        },
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            LunchText(
                text = restaurant.name,
                role = LunchTextRole.Heading,
                modifier = Modifier.weight(1f),
                maxLines = 1,
            )
            restaurant.rating?.let { RatingLabel(rating = it) }
        }
        if (restaurant.cuisineTypes.isNotEmpty()) {
            FlowRow(
                modifier = Modifier.padding(top = TokenSpacing.sm),
                horizontalArrangement = Arrangement.spacedBy(TokenSpacing.xs),
                verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs),
            ) {
                restaurant.cuisineTypes.forEach { cuisine ->
                    LunchText(
                        text = cuisine,
                        role = LunchTextRole.Caption,
                        color = colors.textSecondary,
                        modifier = Modifier
                            .background(colors.surfaceRaised, LunchTheme.shapes.chip)
                            .padding(horizontal = TokenSpacing.sm, vertical = TokenSpacing.xs),
                    )
                }
            }
        }
        LunchText(
            text = restaurantMeta(restaurant),
            role = LunchTextRole.Caption,
            color = colors.textSecondary,
            modifier = Modifier.padding(top = TokenSpacing.sm),
            maxLines = 1,
        )
    }
}

/** "$$ · 0.8 km · Open now", skipping whatever is unknown. */
@Composable
fun restaurantMeta(restaurant: Restaurant): String = listOfNotNull(
    restaurant.priceLabel,
    restaurant.distanceFromUser?.let { stringResource(R.string.a11y_distance_km, formatOneDecimal(it)) },
    stringResource(if (restaurant.isOpenNow) R.string.discover_detail_open_now else R.string.discover_detail_closed),
).joinToString(RestaurantCardDefaults.META_SEPARATOR)

internal fun formatOneDecimal(value: Double): String = dartOneDecimal(value)

/** Filled star and a one-decimal rating in `primary`. */
@Composable
fun RatingLabel(rating: Double, modifier: Modifier = Modifier) {
    val colors = LunchTheme.colors
    val formatted = formatOneDecimal(rating)
    val a11y = stringResource(R.string.a11y_rated_out_of_five, formatted)
    Row(
        modifier = modifier.semantics(mergeDescendants = true) { contentDescription = a11y },
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        LunchIconView(icon = LunchIcon.Star, size = RestaurantCardDefaults.ratingIconSize, filled = true, tint = colors.primary)
        LunchText(text = formatted, role = LunchTextRole.Heading, color = colors.primary)
    }
}

/** Uppercase label in a `primarySoft` capsule. */
@Composable
fun BadgeLabel(text: String, modifier: Modifier = Modifier) {
    val colors = LunchTheme.colors
    LunchText(
        text = text,
        role = LunchTextRole.Label,
        color = colors.primary,
        modifier = modifier
            .background(colors.primarySoft, LunchTheme.shapes.chip)
            .padding(horizontal = TokenSpacing.sm + TokenSpacing.xs, vertical = TokenSpacing.sm),
    )
}

@Composable
private fun FavouriteButton(selected: Boolean, index: Int, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val colors = LunchTheme.colors
    val interactionSource = remember { MutableInteractionSource() }
    val label = stringResource(if (selected) R.string.a11y_remove_favourite else R.string.a11y_add_favourite)
    Box(
        modifier = modifier
            .pressable(interactionSource)
            .size(TokenSize.touchTarget)
            .background(colors.surface.copy(alpha = ComponentDefaults.FAVOURITE_DISC_ALPHA), LunchTheme.shapes.chip)
            .clickable(
                interactionSource = interactionSource,
                indication = ripple(bounded = false, radius = TokenSize.touchTarget / 2),
                role = Role.Button,
                onClickLabel = label,
                onClick = onClick,
            )
            .testTag(RestaurantCardDefaults.favouriteTag(index, selected)),
        contentAlignment = Alignment.Center,
    ) {
        LunchIconView(
            icon = LunchIcon.Favorite,
            filled = selected,
            tint = if (selected) colors.primary else colors.textSecondary,
            contentDescription = label,
        )
    }
}

@LunchPreviews
@Composable
private fun RestaurantCardPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            RestaurantCard(
                restaurant = PreviewData.greenGardenBowls,
                index = 0,
                isFavourite = true,
                onClick = {},
                onFavouriteClick = {},
                modifier = Modifier.fillMaxWidth(),
                badge = stringResource(R.string.home_result_eyebrow),
            )
            RestaurantCard(
                restaurant = PreviewData.sakuraSushi,
                index = 1,
                isFavourite = false,
                onClick = {},
                onFavouriteClick = {},
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}
