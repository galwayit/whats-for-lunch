/**
 * @file ComponentDefaults.kt
 * @description Values shared by several components that design/tokens.json expresses in prose
 * rather than as tokens (disabled opacity, hairline width, tint levels).
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.ui.unit.dp

internal object ComponentDefaults {
    /** Opacity applied to a whole control when it is disabled. */
    const val DISABLED_ALPHA = 0.4f

    /** Alpha of the `primary` outline on secondary buttons and the avatar border. */
    const val OUTLINE_TINT_ALPHA = 0.4f

    /** Alpha of the `primary` border on an [InitialAvatar]. */
    const val AVATAR_BORDER_ALPHA = 0.2f

    /** Opacity of the surface disc behind the favourite heart on a [RestaurantCard]. */
    const val FAVOURITE_DISC_ALPHA = 0.85f

    /** Width of every 1px-style border (hairlines, chip outlines, secondary buttons). */
    val hairlineWidth = 1.dp
}
