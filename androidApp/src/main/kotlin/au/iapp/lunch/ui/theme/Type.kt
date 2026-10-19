/**
 * @file Type.kt
 * @description Typography built from TokenType: Bricolage Grotesque (res/font, see
 * res/README.md) for the display roles and the system default family for every other role;
 * one TextStyle per role; the LunchText composable that also applies the uppercase rule; and
 * the text-scale clamp.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.theme

import android.annotation.SuppressLint
import android.content.Context
import androidx.compose.material3.Text
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.sp

/** The eight text roles from design/tokens.json `typography.roles`. */
enum class LunchTextRole(val token: TextRole) {
    Display(TokenType.display),
    Title(TokenType.title),
    Heading(TokenType.heading),
    Body(TokenType.body),
    BodySmall(TokenType.bodySmall),
    Caption(TokenType.caption),
    Label(TokenType.label),
    Button(TokenType.button),
}

/**
 * One [TextStyle] per role. Roles flagged `display` in the tokens use [displayFamily]; the rest
 * use [FontFamily.Default] so running text keeps the platform's own face.
 */
@Immutable
data class LunchTypography(
    val displayFamily: FontFamily,
    /** True when the Bricolage Grotesque resources were found; false means the system stand-in. */
    val isCustomFontAvailable: Boolean,
) {
    val display = style(LunchTextRole.Display)
    val title = style(LunchTextRole.Title)
    val heading = style(LunchTextRole.Heading)
    val body = style(LunchTextRole.Body)
    val bodySmall = style(LunchTextRole.BodySmall)
    val caption = style(LunchTextRole.Caption)
    val label = style(LunchTextRole.Label)
    val button = style(LunchTextRole.Button)

    fun style(role: LunchTextRole): TextStyle = role.token.let { token ->
        TextStyle(
            fontFamily = if (token.display) displayFamily else FontFamily.Default,
            fontWeight = FontWeight(token.weight),
            fontSize = token.size.sp,
            lineHeight = token.lineHeight.sp,
            letterSpacing = token.tracking.sp,
            platformStyle = PlatformTextStyle(includeFontPadding = false),
            lineHeightStyle = LineHeightStyle(
                alignment = LineHeightStyle.Alignment.Center,
                trim = LineHeightStyle.Trim.None,
            ),
        )
    }

    /** Material roles for stock components (sheets, dialogs, date pickers). */
    fun toMaterialTypography(): Typography = Typography(
        displaySmall = display,
        headlineLarge = display,
        headlineMedium = title,
        headlineSmall = title,
        titleLarge = title,
        titleMedium = heading,
        titleSmall = heading,
        bodyLarge = body,
        bodyMedium = bodySmall,
        bodySmall = caption,
        labelLarge = button,
        labelMedium = caption,
        labelSmall = label,
    )
}

val LocalLunchTypography = staticCompositionLocalOf { LunchTypography(FontFamily.Default, isCustomFontAvailable = false) }

/**
 * Resource names expected under res/font, one per weight the display roles use. When every file
 * is present the family is built from them; otherwise [FontFamily.Default] carries the same
 * weights so layout metrics stay comparable.
 */
object LunchFont {
    const val RESOURCE_PREFIX = "bricolage_grotesque"

    val weights: Map<FontWeight, String> = mapOf(
        FontWeight.Bold to "${RESOURCE_PREFIX}_bold",
        FontWeight.ExtraBold to "${RESOURCE_PREFIX}_extrabold",
    )

    /**
     * Resolves the family from resources by name, because `R.font` members only exist once the
     * files are added. Returns null when any weight is missing so a partial drop-in is obvious.
     */
    @SuppressLint("DiscouragedApi")
    fun resolve(context: Context): FontFamily? {
        val fonts = weights.map { (weight, name) ->
            val id = context.resources.getIdentifier(name, "font", context.packageName)
            if (id == 0) return null
            Font(resId = id, weight = weight)
        }
        return FontFamily(fonts)
    }
}

/** Builds the typography once per context; previews resolve the same way. */
@Composable
fun rememberLunchTypography(): LunchTypography {
    val context = LocalContext.current
    return remember(context) {
        val custom = LunchFont.resolve(context)
        LunchTypography(custom ?: FontFamily.Default, isCustomFontAvailable = custom != null)
    }
}

/**
 * Text in a design-system role. Applies the role's style and, for roles flagged `uppercase` in
 * the tokens (label), the uppercase transform.
 *
 * @param color Defaults to the palette `text` colour.
 */
@Composable
fun LunchText(
    text: String,
    role: LunchTextRole,
    modifier: Modifier = Modifier,
    color: Color = LunchTheme.colors.text,
    textAlign: TextAlign? = null,
    maxLines: Int = Int.MAX_VALUE,
    overflow: TextOverflow = TextOverflow.Clip,
) {
    Text(
        text = if (role.token.uppercase) text.uppercase() else text,
        modifier = modifier,
        color = color,
        style = LunchTheme.typography.style(role),
        textAlign = textAlign,
        maxLines = maxLines,
        overflow = overflow,
    )
}

/**
 * Clamps the system font scale to `TokenType.TEXT_SCALE_MIN..MAX` for [content], so layouts
 * never render outside the tested range. [LunchTheme] applies this by default.
 */
@Composable
fun ClampedTextScale(content: @Composable () -> Unit) {
    val density = LocalDensity.current
    val clamped = remember(density) {
        Density(
            density = density.density,
            fontScale = density.fontScale.coerceIn(TokenType.TEXT_SCALE_MIN, TokenType.TEXT_SCALE_MAX),
        )
    }
    CompositionLocalProvider(LocalDensity provides clamped, content = content)
}
