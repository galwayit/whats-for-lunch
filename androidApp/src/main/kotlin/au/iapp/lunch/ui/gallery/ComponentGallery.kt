/**
 * @file ComponentGallery.kt
 * @description Every design-system component in every state, for visual review and Maestro
 * screenshots. Mirrors iosApp/LunchApp/Gallery/ComponentGallery.swift: the same section names,
 * an appearance switch, and a text-size stepper. Shown by MainActivity while
 * [au.iapp.lunch.FeatureFlags.showRealApp] is false; a section can be preselected with the
 * `gallerySection` intent extra.
 * @author AI Assistant
 * @date 2026-09-03
 */
@file:OptIn(ExperimentalLayoutApi::class, ExperimentalMaterial3Api::class)

package au.iapp.lunch.ui.gallery

import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Density
import au.iapp.lunch.R
import au.iapp.lunch.ui.components.AILoading
import au.iapp.lunch.ui.components.AvatarStack
import au.iapp.lunch.ui.components.BadgeLabel
import au.iapp.lunch.ui.components.CapacityRing
import au.iapp.lunch.ui.components.CapacityTone
import au.iapp.lunch.ui.components.Chip
import au.iapp.lunch.ui.components.CurrencyField
import au.iapp.lunch.ui.components.EmptyState
import au.iapp.lunch.ui.components.EmptyStateVariant
import au.iapp.lunch.ui.components.GroupCard
import au.iapp.lunch.ui.components.GuestRow
import au.iapp.lunch.ui.components.HeroHungryButton
import au.iapp.lunch.ui.components.HeroState
import au.iapp.lunch.ui.components.InvitationCard
import au.iapp.lunch.ui.components.InviteShareRow
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.LunchCard
import au.iapp.lunch.ui.components.LunchTab
import au.iapp.lunch.ui.components.LunchTabBar
import au.iapp.lunch.ui.components.LunchTextField
import au.iapp.lunch.ui.components.PaywallView
import au.iapp.lunch.ui.components.ProBadge
import au.iapp.lunch.ui.components.ProposalCard
import au.iapp.lunch.ui.components.RatingLabel
import au.iapp.lunch.ui.components.RecommendationCard
import au.iapp.lunch.ui.components.Renewal
import au.iapp.lunch.ui.components.RestaurantCard
import au.iapp.lunch.ui.components.RestaurantPhoto
import au.iapp.lunch.ui.components.SearchField
import au.iapp.lunch.ui.components.SheetAction
import au.iapp.lunch.ui.components.SheetContainer
import au.iapp.lunch.ui.components.SubscriptionRow
import au.iapp.lunch.ui.components.UpsellRow
import au.iapp.lunch.ui.components.WeeklyBudgetStrip
import au.iapp.lunch.ui.components.toneColor
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.preview.PreviewData
import au.iapp.lunch.ui.preview.RsvpStatus
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenMotion
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing
import au.iapp.lunch.ui.theme.TokenType
import kotlinx.coroutines.delay
import java.util.Locale

/**
 * The gallery's sections. [key] doubles as the `gallerySection` intent-extra value and the
 * chip test tag suffix (`gallery_section_<key>`), matching the iOS `GallerySection` raw values.
 */
enum class GallerySection(val key: String, val title: String) {
    All("all", "All"),
    Typography("typography", "Typography"),
    Buttons("buttons", "Buttons"),
    Hero("hero", "Hero"),
    Chips("chips", "Chips"),
    Cards("cards", "Cards"),
    Fields("fields", "Fields"),
    Budget("budget", "Budget"),
    Recommendation("recommendation", "Recommendation"),
    Loading("loading", "Loading and empty"),
    Sheet("sheet", "Sheet"),
    TabBar("tabbar", "Tab bar"),
    Pro("pro", "Pro"),
    Paywall("paywall", "Paywall"),
    Social("social", "Social"),
    Icons("icons", "Icons"),
    ;

    /** Whether this section renders when [All] is selected. Paywall takes the whole screen. */
    val includedInAll: Boolean get() = this != All && this != Paywall

    companion object {
        /** The section for an intent extra, or [All] when absent or unknown. */
        fun fromKey(key: String?): GallerySection = entries.firstOrNull { it.key == key } ?: All
    }
}

/** The appearance override offered by the gallery controls. */
enum class GalleryAppearance(val key: String, val title: String) {
    System("system", "System"),
    Light("light", "Light"),
    Dark("dark", "Dark"),
}

/** Gallery-only constants; the values are review conveniences, not design tokens. */
object ComponentGalleryDefaults {
    const val CONTROLS_TEST_TAG = "gallery_controls"
    const val TEXT_SMALLER_TEST_TAG = "gallery_text_smaller"
    const val TEXT_LARGER_TEST_TAG = "gallery_text_larger"
    fun sectionTestTag(section: GallerySection) = "gallery_section_${section.key}"
    fun appearanceTestTag(appearance: GalleryAppearance) = "gallery_appearance_${appearance.key}"

    /** Absolute font scales the stepper walks through. The last two exercise the theme's clamp. */
    val textScaleSteps: List<Float> = listOf(0.7f, 0.85f, 1f, 1.15f, 1.3f, 1.5f, 1.75f, 2f, 2.3f)
    val defaultTextScaleIndex: Int = textScaleSteps.indexOf(1f)

    /** Ring fill levels reviewed side by side: empty, healthy, caution, over. */
    val ringLevels: List<Float> = listOf(0f, 0.45f, 0.8f, 1f)
    val ringDiameter = TokenSize.heroRingOuter / 2
    const val SAMPLE_CONFIDENCE = 0.85f
    const val SAMPLE_CONFIDENCE_LOW = 0.4f
    const val PICKS_READY = 3

    /** Stand-in for the free-pick reset time in the AI upsell body; matches the iOS gallery. */
    const val AI_RESET_TIME = "midnight"
    const val SAMPLE_RATING = 4.6
}

/**
 * The component gallery. Owns the appearance and text-size overrides and applies [LunchTheme]
 * itself, so it must not be wrapped in another theme.
 *
 * @param initialSection The section to open with; see [GallerySection.fromKey].
 */
@Composable
fun ComponentGallery(
    initialSection: GallerySection = GallerySection.All,
    modifier: Modifier = Modifier,
) {
    var section by rememberSaveable { mutableStateOf(initialSection) }
    var appearance by rememberSaveable { mutableStateOf(GalleryAppearance.System) }
    var textScaleIndex by rememberSaveable { mutableIntStateOf(ComponentGalleryDefaults.defaultTextScaleIndex) }

    val systemDark = isSystemInDarkTheme()
    val darkTheme = when (appearance) {
        GalleryAppearance.System -> systemDark
        GalleryAppearance.Light -> false
        GalleryAppearance.Dark -> true
    }
    // The stepper replaces the font scale outside LunchTheme so the theme's clamp stays visible.
    val requestedScale = ComponentGalleryDefaults.textScaleSteps[textScaleIndex]
    val baseDensity = LocalDensity.current
    val density = remember(baseDensity, requestedScale) { Density(baseDensity.density, requestedScale) }

    CompositionLocalProvider(LocalDensity provides density) {
        LunchTheme(darkTheme = darkTheme) {
            GalleryScreen(
                section = section,
                onSectionSelect = { section = it },
                appearance = appearance,
                onAppearanceSelect = { appearance = it },
                requestedScale = requestedScale,
                canDecreaseText = textScaleIndex > 0,
                canIncreaseText = textScaleIndex < ComponentGalleryDefaults.textScaleSteps.lastIndex,
                onDecreaseText = { textScaleIndex -= 1 },
                onIncreaseText = { textScaleIndex += 1 },
                modifier = modifier,
            )
        }
    }
}

@Composable
private fun GalleryScreen(
    section: GallerySection,
    onSectionSelect: (GallerySection) -> Unit,
    appearance: GalleryAppearance,
    onAppearanceSelect: (GalleryAppearance) -> Unit,
    requestedScale: Float,
    canDecreaseText: Boolean,
    canIncreaseText: Boolean,
    onDecreaseText: () -> Unit,
    onIncreaseText: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LunchTheme.colors
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(colors.ground)
            .windowInsetsPadding(WindowInsets.safeDrawing),
    ) {
        SectionChipRow(selected = section, onSelect = onSectionSelect)
        if (section == GallerySection.Paywall) {
            PaywallSection(modifier = Modifier.fillMaxSize())
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(TokenSpacing.page),
                verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg),
            ) {
                ControlsCard(
                    appearance = appearance,
                    onAppearanceSelect = onAppearanceSelect,
                    requestedScale = requestedScale,
                    canDecreaseText = canDecreaseText,
                    canIncreaseText = canIncreaseText,
                    onDecreaseText = onDecreaseText,
                    onIncreaseText = onIncreaseText,
                )
                val visible = if (section == GallerySection.All) {
                    GallerySection.entries.filter { it.includedInAll }
                } else {
                    listOf(section)
                }
                visible.forEach { SectionBlock(section = it) }
            }
        }
    }
}

@Composable
private fun SectionChipRow(selected: GallerySection, onSelect: (GallerySection) -> Unit, modifier: Modifier = Modifier) {
    val listState = rememberLazyListState()
    // Keep the selected chip in view, including when a section is preselected at launch.
    LaunchedEffect(selected) { listState.animateScrollToItem(selected.ordinal) }
    LazyRow(
        state = listState,
        modifier = modifier
            .fillMaxWidth()
            .background(LunchTheme.colors.surfaceRaised),
        contentPadding = PaddingValues(horizontal = TokenSpacing.page, vertical = TokenSpacing.sm),
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
    ) {
        items(GallerySection.entries) { section ->
            Chip(
                text = section.title,
                selected = section == selected,
                onClick = { onSelect(section) },
                modifier = Modifier.testTag(ComponentGalleryDefaults.sectionTestTag(section)),
            )
        }
    }
}

@Composable
private fun ControlsCard(
    appearance: GalleryAppearance,
    onAppearanceSelect: (GalleryAppearance) -> Unit,
    requestedScale: Float,
    canDecreaseText: Boolean,
    canIncreaseText: Boolean,
    onDecreaseText: () -> Unit,
    onIncreaseText: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = LunchTheme.colors
    val typography = LunchTheme.typography
    val effectiveScale = LocalDensity.current.fontScale
    LunchCard(modifier = modifier.fillMaxWidth().testTag(ComponentGalleryDefaults.CONTROLS_TEST_TAG)) {
        LunchText(text = "Gallery controls", role = LunchTextRole.Label, color = colors.textSecondary)
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            GalleryAppearance.entries.forEach { option ->
                Chip(
                    text = option.title,
                    selected = option == appearance,
                    onClick = { onAppearanceSelect(option) },
                    modifier = Modifier.testTag(ComponentGalleryDefaults.appearanceTestTag(option)),
                )
            }
        }
        Row(
            horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            LunchButton(
                text = "A-",
                onClick = onDecreaseText,
                modifier = Modifier.testTag(ComponentGalleryDefaults.TEXT_SMALLER_TEST_TAG),
                style = LunchButtonStyle.Secondary,
                enabled = canDecreaseText,
            )
            LunchText(
                text = textScaleSummary(requestedScale, effectiveScale),
                role = LunchTextRole.BodySmall,
                modifier = Modifier.weight(1f),
                color = colors.textSecondary,
            )
            LunchButton(
                text = "A+",
                onClick = onIncreaseText,
                modifier = Modifier.testTag(ComponentGalleryDefaults.TEXT_LARGER_TEST_TAG),
                style = LunchButtonStyle.Secondary,
                enabled = canIncreaseText,
            )
        }
        val fontStatus = if (typography.isCustomFontAvailable) {
            "${TokenType.FAMILY} loaded from res/font"
        } else {
            "${TokenType.FAMILY} missing; using the system font (see res/README.md)"
        }
        LunchText(text = fontStatus, role = LunchTextRole.Caption, color = colors.textSecondary)
    }
}

/** "Text 1.15x" or, when the theme clamped the request, "Text 2.3x (clamped to 2.0x)". */
private fun textScaleSummary(requested: Float, effective: Float): String {
    val base = "Text ${formatScale(requested)}x"
    return if (requested == effective) base else "$base (clamped to ${formatScale(effective)}x)"
}

private fun formatScale(scale: Float): String = String.format(Locale.ROOT, "%.2f", scale).trimEnd('0').trimEnd('.')

@Composable
private fun SectionBlock(section: GallerySection, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
        LunchText(text = section.title, role = LunchTextRole.Title)
        when (section) {
            GallerySection.Typography -> TypographySection()
            GallerySection.Buttons -> ButtonsSection()
            GallerySection.Hero -> HeroSection()
            GallerySection.Chips -> ChipsSection()
            GallerySection.Cards -> CardsSection()
            GallerySection.Fields -> FieldsSection()
            GallerySection.Budget -> BudgetSection()
            GallerySection.Recommendation -> RecommendationSection()
            GallerySection.Loading -> LoadingSection()
            GallerySection.Sheet -> SheetSection()
            GallerySection.TabBar -> TabBarSection()
            GallerySection.Pro -> ProSection()
            GallerySection.Social -> SocialSection()
            GallerySection.Icons -> IconsSection()
            GallerySection.All, GallerySection.Paywall -> Unit
        }
    }
}

/** A caption above a group of variants, e.g. "Primary" over its button states. */
@Composable
private fun VariantLabel(text: String, modifier: Modifier = Modifier) {
    LunchText(text = text, role = LunchTextRole.Caption, modifier = modifier, color = LunchTheme.colors.textSecondary)
}

@Composable
private fun ColumnScope.TypographySection() {
    LunchTextRole.entries.forEach { role ->
        val token = role.token
        LunchText(text = "${role.name} ${token.size}/${token.lineHeight} w${token.weight}", role = role)
    }
}

@Composable
private fun ColumnScope.ButtonsSection() {
    LunchButtonStyle.entries.forEach { style ->
        VariantLabel(style.name)
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
        ) {
            LunchButton(text = stringResource(R.string.action_continue), onClick = {}, style = style)
            LunchButton(text = stringResource(R.string.action_directions), onClick = {}, style = style, icon = LunchIcon.Directions)
            LunchButton(text = stringResource(R.string.action_save), onClick = {}, style = style, loading = true)
            LunchButton(text = stringResource(R.string.action_save), onClick = {}, style = style, enabled = false)
        }
    }
}

@Composable
private fun ColumnScope.HeroSection() {
    var state by remember { mutableStateOf(HeroState.Idle) }
    LaunchedEffect(state) {
        if (state == HeroState.Searching) {
            delay(TokenMotion.heroPulseDurationMs.toLong())
            state = HeroState.Idle
        }
    }
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
    ) {
        BadgeLabel(text = stringResource(R.string.home_picks_badge, ComponentGalleryDefaults.PICKS_READY))
        HeroHungryButton(state = state, onClick = { state = HeroState.Searching })
        VariantLabel("Tap to see the searching state")
    }
}

@Composable
private fun ColumnScope.ChipsSection() {
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
    ) {
        Chip(text = stringResource(R.string.discover_filter_price), selected = true, onClick = {}, leadingIcon = LunchIcon.Payments, trailingChevron = true)
        Chip(text = stringResource(R.string.discover_filter_distance), selected = false, onClick = {}, leadingIcon = LunchIcon.NearMe, trailingChevron = true)
        Chip(text = stringResource(R.string.discover_filter_rating), selected = false, onClick = {}, trailingChevron = true)
        Chip(text = stringResource(R.string.discover_filter_dietary), selected = false, onClick = {})
        Chip(text = stringResource(R.string.discover_filter_dietary), selected = false, onClick = {}, enabled = false)
        Chip(text = stringResource(R.string.discover_filter_price), selected = true, onClick = {}, enabled = false)
    }
}

@Composable
private fun ColumnScope.CardsSection() {
    val colors = LunchTheme.colors
    VariantLabel("Plain and header cards")
    LunchCard(modifier = Modifier.fillMaxWidth(), onClick = {}) {
        LunchText(text = "Tappable card", role = LunchTextRole.Heading)
        LunchText(text = "Press feedback scales the whole card.", role = LunchTextRole.BodySmall, color = colors.textSecondary)
    }
    LunchCard(
        modifier = Modifier.fillMaxWidth(),
        header = { RestaurantPhoto(url = null, contentDescription = null, modifier = Modifier.fillMaxWidth()) },
    ) {
        LunchText(text = "Card with photo header", role = LunchTextRole.Heading)
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm), verticalAlignment = Alignment.CenterVertically) {
            RatingLabel(rating = ComponentGalleryDefaults.SAMPLE_RATING)
            BadgeLabel(text = stringResource(R.string.discover_detail_open_now))
        }
    }
    VariantLabel("Restaurant cards")
    PreviewData.restaurants.forEachIndexed { index, restaurant ->
        RestaurantCard(
            restaurant = restaurant,
            index = index,
            isFavourite = index == 0,
            onClick = {},
            onFavouriteClick = {},
            modifier = Modifier.fillMaxWidth(),
            badge = if (index == 1) stringResource(R.string.discover_detail_open_now) else null,
        )
    }
}

@Composable
private fun ColumnScope.FieldsSection() {
    var name by rememberSaveable { mutableStateOf("") }
    var place by rememberSaveable { mutableStateOf("Green Garden Bowls") }
    var cost by rememberSaveable { mutableStateOf("") }
    var search by rememberSaveable { mutableStateOf("") }
    LunchTextField(
        value = name,
        onValueChange = { name = it },
        modifier = Modifier.fillMaxWidth().testTag("onboarding_name_field"),
        placeholder = stringResource(R.string.onboarding_step2_placeholder),
        label = "Name",
    )
    LunchTextField(
        value = place,
        onValueChange = { place = it },
        modifier = Modifier.fillMaxWidth().testTag("meal_place_field"),
        placeholder = stringResource(R.string.track_log_place_placeholder),
        leadingIcon = LunchIcon.Restaurant,
    )
    LunchTextField(
        value = "",
        onValueChange = {},
        modifier = Modifier.fillMaxWidth(),
        placeholder = "Error state",
        isError = true,
        supportingText = "Something is not right here.",
    )
    LunchTextField(
        value = "Disabled",
        onValueChange = {},
        modifier = Modifier.fillMaxWidth(),
        enabled = false,
    )
    CurrencyField(
        value = cost,
        onValueChange = { cost = it },
        modifier = Modifier.fillMaxWidth().testTag("meal_cost_field"),
        label = "Cost",
    )
    SearchField(value = search, onValueChange = { search = it }, modifier = Modifier.fillMaxWidth())
}

@Composable
private fun ColumnScope.BudgetSection() {
    val colors = LunchTheme.colors
    VariantLabel("Capacity ring at 0, 45, 80 and 100 percent")
    ComponentGalleryDefaults.ringLevels.chunked(2).forEach { pair ->
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
            pair.forEach { level ->
                CapacityRing(progress = level, diameter = ComponentGalleryDefaults.ringDiameter) {
                    val capacity = PreviewData.weeklyBudget.weeklyCapacity
                    LunchText(
                        text = PreviewData.currency(capacity * level),
                        role = LunchTextRole.Heading,
                        color = colors.toneColor(CapacityTone.from(level)),
                    )
                    LunchText(
                        text = stringResource(R.string.track_ring_remaining, PreviewData.currency(capacity * (1 - level))),
                        role = LunchTextRole.Label,
                        color = colors.textSecondary,
                    )
                }
            }
        }
    }
    VariantLabel("Weekly budget strip: on track and over")
    WeeklyBudgetStrip(budget = PreviewData.weeklyBudget, modifier = Modifier.fillMaxWidth(), onClick = {})
    WeeklyBudgetStrip(budget = PreviewData.weeklyBudgetOver, modifier = Modifier.fillMaxWidth())
}

@Composable
private fun ColumnScope.RecommendationSection() {
    RecommendationCard(
        restaurant = PreviewData.greenGardenBowls,
        reasons = PreviewData.reasons,
        confidence = ComponentGalleryDefaults.SAMPLE_CONFIDENCE,
        onDirections = {},
        onLogMeal = {},
        onWhy = {},
        onShowMore = {},
        onReject = {},
        modifier = Modifier.fillMaxWidth(),
    )
    RecommendationCard(
        restaurant = PreviewData.pastaCorner,
        reasons = PreviewData.pastaReasons,
        confidence = ComponentGalleryDefaults.SAMPLE_CONFIDENCE_LOW,
        onDirections = {},
        onLogMeal = {},
        onWhy = {},
        onShowMore = {},
        onReject = {},
        modifier = Modifier.fillMaxWidth(),
    )
}

@Composable
private fun ColumnScope.LoadingSection() {
    AILoading(
        title = stringResource(R.string.home_searching_title),
        modifier = Modifier.fillMaxWidth(),
        subtitle = stringResource(R.string.home_searching_body),
    )
    EmptyState(
        variant = EmptyStateVariant.NothingHere,
        title = stringResource(R.string.discover_empty_title),
        message = stringResource(R.string.discover_empty_body),
        modifier = Modifier.fillMaxWidth(),
        actionLabel = stringResource(R.string.action_search_again),
    )
    EmptyState(
        variant = EmptyStateVariant.Offline,
        title = stringResource(R.string.error_offline_title),
        message = stringResource(R.string.error_offline_body),
        modifier = Modifier.fillMaxWidth(),
        actionLabel = stringResource(R.string.action_retry),
    )
    EmptyState(
        variant = EmptyStateVariant.ServiceProblem,
        title = stringResource(R.string.error_service_title),
        message = stringResource(R.string.error_service_body),
        modifier = Modifier.fillMaxWidth(),
        actionLabel = stringResource(R.string.action_retry),
    )
}

@Composable
private fun ColumnScope.SheetSection() {
    var open by rememberSaveable { mutableStateOf(false) }
    var price by rememberSaveable { mutableIntStateOf(1) }
    val priceLabels = listOf("$", "$$", "$$$", "$$$$")
    LunchButton(text = "Open filter sheet", onClick = { open = true }, style = LunchButtonStyle.Secondary)
    VariantLabel("Inline preview of the same container")
    FilterSheetContent(price = price, priceLabels = priceLabels, onPrice = { price = it }, onApply = {}, onClear = { price = -1 })
    if (open) {
        ModalBottomSheet(
            onDismissRequest = { open = false },
            containerColor = LunchTheme.colors.surface,
            shape = LunchTheme.shapes.sheet,
            dragHandle = null,
        ) {
            FilterSheetContent(
                price = price,
                priceLabels = priceLabels,
                onPrice = { price = it },
                onApply = { open = false },
                onClear = { price = -1 },
            )
        }
    }
}

@Composable
private fun FilterSheetContent(
    price: Int,
    priceLabels: List<String>,
    onPrice: (Int) -> Unit,
    onApply: () -> Unit,
    onClear: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SheetContainer(
        title = stringResource(R.string.discover_filter_price_title),
        modifier = modifier.fillMaxWidth(),
        primaryAction = SheetAction(label = stringResource(R.string.discover_filter_apply), onClick = onApply),
        secondaryAction = SheetAction(label = stringResource(R.string.discover_filter_clear), onClick = onClear),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            priceLabels.forEachIndexed { index, label ->
                Chip(text = label, selected = index == price, onClick = { onPrice(index) })
            }
        }
    }
}

@Composable
private fun ColumnScope.TabBarSection() {
    var selected by rememberSaveable { mutableStateOf(LunchTab.Home) }
    LunchTabBar(selected = selected, onSelect = { selected = it }, modifier = Modifier.fillMaxWidth())
}

@Composable
private fun ColumnScope.ProSection() {
    Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm), verticalAlignment = Alignment.CenterVertically) {
        ProBadge()
        LunchText(
            text = stringResource(R.string.profile_pro_active_title, stringResource(R.string.paywall_plan_yearly)),
            role = LunchTextRole.Heading,
        )
    }
    UpsellRow(
        title = stringResource(R.string.gate_ai_title),
        body = stringResource(R.string.gate_ai_body, ComponentGalleryDefaults.AI_RESET_TIME),
        ctaLabel = stringResource(R.string.gate_ai_cta),
        onCta = {},
        modifier = Modifier.fillMaxWidth(),
    )
    UpsellRow(
        title = stringResource(R.string.gate_host_title),
        body = stringResource(R.string.gate_host_body),
        ctaLabel = stringResource(R.string.gate_host_cta),
        onCta = {},
        modifier = Modifier.fillMaxWidth(),
    )
    SubscriptionRow(
        planName = stringResource(R.string.paywall_plan_yearly),
        renewal = Renewal.Renews,
        date = "3 Sep 2027",
        onManage = {},
        modifier = Modifier.fillMaxWidth(),
    )
    SubscriptionRow(
        planName = stringResource(R.string.paywall_plan_monthly),
        renewal = Renewal.Ends,
        date = "3 Oct 2026",
        onManage = {},
        modifier = Modifier.fillMaxWidth(),
    )
}

@Composable
private fun PaywallSection(modifier: Modifier = Modifier) {
    var selected by rememberSaveable { mutableStateOf(PreviewData.yearlyPackage.identifier) }
    var purchasing by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(purchasing) {
        if (purchasing) {
            delay(TokenMotion.heroPulseDurationMs.toLong())
            purchasing = false
        }
    }
    PaywallView(
        packages = listOf(PreviewData.yearlyPackage, PreviewData.monthlyPackage),
        selectedIdentifier = selected,
        onSelect = { selected = it.identifier },
        onSubscribe = { purchasing = true },
        onRestore = {},
        onTerms = {},
        onPrivacy = {},
        modifier = modifier,
        purchasing = purchasing,
    )
}

@Composable
private fun ColumnScope.SocialSection() {
    val going = PreviewData.rsvps.filter { it.status == RsvpStatus.ACCEPTED }
    VariantLabel("Group card")
    GroupCard(group = PreviewData.group, attendingCount = going.size, onClick = {}, modifier = Modifier.fillMaxWidth())
    VariantLabel("Invitation card: idle and responding")
    InvitationCard(group = PreviewData.group, rsvps = PreviewData.rsvps, onAccept = {}, onDecline = {}, modifier = Modifier.fillMaxWidth())
    InvitationCard(group = PreviewData.group, rsvps = PreviewData.rsvps, onAccept = {}, onDecline = {}, modifier = Modifier.fillMaxWidth(), responding = true)
    VariantLabel("Guests per RSVP status")
    LunchCard(modifier = Modifier.fillMaxWidth()) {
        PreviewData.rsvps.forEach { GuestRow(rsvp = it) }
        AvatarStack(names = PreviewData.rsvps.map { it.displayName })
    }
    VariantLabel("Proposal cards: idle and choosing")
    ProposalCard(restaurant = PreviewData.sakuraSushi, index = 0, onChoose = {}, modifier = Modifier.fillMaxWidth())
    ProposalCard(restaurant = PreviewData.pastaCorner, index = 1, onChoose = {}, modifier = Modifier.fillMaxWidth(), choosing = true)
    VariantLabel("Invite share row")
    InviteShareRow(inviteUrl = PreviewData.INVITE_URL, onShare = {}, modifier = Modifier.fillMaxWidth())
}

@Composable
private fun ColumnScope.IconsSection() {
    val colors = LunchTheme.colors
    VariantLabel("${LunchIcon.entries.size} icons, outlined then filled")
    FlowRow(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
    ) {
        LunchIcon.entries.forEach { icon ->
            Column(
                modifier = Modifier.size(width = TokenSize.heroBorder * 10, height = TokenSize.touchTarget + TokenSpacing.lg),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
                    LunchIconView(icon = icon, tint = colors.text)
                    LunchIconView(icon = icon, filled = true, tint = colors.primary)
                }
                LunchText(
                    text = icon.materialName,
                    role = LunchTextRole.Caption,
                    color = colors.textSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

@LunchPreviews
@Composable
private fun ComponentGalleryPreview() {
    Box { ComponentGallery(initialSection = GallerySection.Buttons) }
}
