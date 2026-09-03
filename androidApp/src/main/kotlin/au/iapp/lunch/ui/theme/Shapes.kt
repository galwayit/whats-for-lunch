/**
 * @file Shapes.kt
 * @description Corner shapes built from TokenRadius, plus the Material 3 mapping used by stock
 * Material components inside LunchTheme.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.theme

import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.CornerBasedShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf

/** The container shapes from design/tokens.json `radius`. 9999dp radii become [CircleShape]. */
@Immutable
data class LunchShapes(
    val container: CornerBasedShape = RoundedCornerShape(TokenRadius.container),
    val chip: CornerBasedShape = CircleShape,
    val toast: CornerBasedShape = RoundedCornerShape(TokenRadius.toast),
    val sheet: CornerBasedShape = RoundedCornerShape(topStart = TokenRadius.sheet, topEnd = TokenRadius.sheet),
    val hero: CornerBasedShape = CircleShape,
    val input: CornerBasedShape = RoundedCornerShape(TokenRadius.input),
    val button: CornerBasedShape = RoundedCornerShape(TokenRadius.button),
) {
    fun toMaterialShapes(): Shapes = Shapes(
        extraSmall = toast,
        small = toast,
        medium = container,
        large = container,
        extraLarge = RoundedCornerShape(TokenRadius.sheet),
    )
}

val LocalLunchShapes = staticCompositionLocalOf { LunchShapes() }
