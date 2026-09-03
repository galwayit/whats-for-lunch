/**
 * @file PaywallView.kt
 * @description The Lunch Pro paywall: crown header, plan cards (yearly preselected with its
 * trial line and BEST VALUE badge), six benefits, the action CTA, legal copy, and the Restore /
 * Terms / Privacy links.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.preview.PreviewData
import au.iapp.lunch.ui.preview.ProPackage
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing
import au.iapp.lunch.ui.theme.pressable

object PaywallDefaults {
    const val CTA_TEST_TAG = "paywall_cta"
    const val YEARLY_PERIOD = "year"
    val headerIconSize: Dp = TokenSize.iconDefault + TokenSpacing.md
    val selectedBorderWidth: Dp = TokenSpacing.xs / 2
    val checkDiscSize: Dp = TokenSize.iconDefault
    val benefitIconSize: Dp = TokenSize.iconDefault - TokenSpacing.xs
    val benefits = listOf(
        R.string.paywall_benefit_1,
        R.string.paywall_benefit_2,
        R.string.paywall_benefit_3,
        R.string.paywall_benefit_4,
        R.string.paywall_benefit_5,
        R.string.paywall_benefit_6,
    )

    fun planTestTag(identifier: String) = "paywall_plan_$identifier"
}

private val ProPackage.isYearly: Boolean get() = periodLabel == PaywallDefaults.YEARLY_PERIOD

/**
 * @param packages Plans in display order; the yearly plan should come first.
 * @param selectedIdentifier The selected plan's [ProPackage.identifier].
 * @param purchasing Puts the CTA in its loading state and disables plan changes.
 * @param scrollable False when embedded in an already-scrolling parent.
 */
@Composable
fun PaywallView(
    packages: List<ProPackage>,
    selectedIdentifier: String,
    onSelect: (ProPackage) -> Unit,
    onSubscribe: () -> Unit,
    onRestore: () -> Unit,
    onTerms: () -> Unit,
    onPrivacy: () -> Unit,
    modifier: Modifier = Modifier,
    purchasing: Boolean = false,
    scrollable: Boolean = true,
) {
    val colors = LunchTheme.colors
    val selected = packages.firstOrNull { it.identifier == selectedIdentifier }
    val storeName = stringResource(R.string.paywall_store_name)

    Column(
        modifier = modifier
            .then(if (scrollable) Modifier.verticalScroll(rememberScrollState()) else Modifier)
            .padding(horizontal = TokenSpacing.pageWide, vertical = TokenSpacing.lg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
    ) {
        LunchIconView(icon = LunchIcon.WorkspacePremium, filled = true, size = PaywallDefaults.headerIconSize, tint = colors.action)
        LunchText(text = stringResource(R.string.paywall_title), role = LunchTextRole.Display, textAlign = TextAlign.Center)
        LunchText(
            text = stringResource(R.string.paywall_subtitle),
            role = LunchTextRole.Body,
            color = colors.textSecondary,
            textAlign = TextAlign.Center,
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = TokenSpacing.sm)
                .selectableGroup(),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
        ) {
            packages.forEach { pkg ->
                PlanCard(
                    pkg = pkg,
                    selected = pkg.identifier == selectedIdentifier,
                    enabled = !purchasing,
                    onClick = { onSelect(pkg) },
                )
            }
        }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = TokenSpacing.sm),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
        ) {
            PaywallDefaults.benefits.forEach { benefit ->
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm), verticalAlignment = Alignment.CenterVertically) {
                    LunchIconView(icon = LunchIcon.Check, size = PaywallDefaults.benefitIconSize, tint = colors.success)
                    LunchText(text = stringResource(benefit), role = LunchTextRole.Body)
                }
            }
        }
        LunchButton(
            text = stringResource(if (selected?.hasFreeTrial == true) R.string.paywall_cta_trial else R.string.paywall_cta_subscribe),
            onClick = onSubscribe,
            modifier = Modifier
                .fillMaxWidth()
                .testTag(PaywallDefaults.CTA_TEST_TAG),
            style = LunchButtonStyle.Action,
            enabled = selected != null,
            loading = purchasing,
        )
        LunchText(
            text = stringResource(R.string.paywall_legal, storeName),
            role = LunchTextRole.Caption,
            color = colors.textSecondary,
            textAlign = TextAlign.Center,
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
        ) {
            LunchButton(stringResource(R.string.paywall_restore), onRestore, style = LunchButtonStyle.Text)
            LunchButton(stringResource(R.string.paywall_terms), onTerms, style = LunchButtonStyle.Text)
            LunchButton(stringResource(R.string.paywall_privacy), onPrivacy, style = LunchButtonStyle.Text)
        }
    }
}

@Composable
private fun PlanCard(pkg: ProPackage, selected: Boolean, enabled: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val colors = LunchTheme.colors
    val shape = LunchTheme.shapes.container
    val interactionSource = remember { MutableInteractionSource() }
    val borderColor by animateColorAsState(
        targetValue = if (selected) colors.primary else colors.hairlineStrong,
        animationSpec = au.iapp.lunch.ui.theme.LunchMotion.state(),
        label = "planBorder",
    )
    val priceLine = if (pkg.hasFreeTrial) {
        stringResource(R.string.paywall_plan_yearly_trial, pkg.localizedPrice)
    } else {
        stringResource(R.string.paywall_plan_monthly_price, pkg.localizedPrice)
    }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .pressable(interactionSource, enabled)
            .clip(shape)
            .background(colors.surface)
            .border(
                width = if (selected) PaywallDefaults.selectedBorderWidth else ComponentDefaults.hairlineWidth,
                color = borderColor,
                shape = shape,
            )
            .selectable(
                selected = selected,
                interactionSource = interactionSource,
                indication = ripple(),
                enabled = enabled,
                role = Role.RadioButton,
                onClick = onClick,
            )
            .testTag(PaywallDefaults.planTestTag(pkg.identifier))
            .padding(TokenSpacing.md),
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm + TokenSpacing.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(PaywallDefaults.checkDiscSize)
                .background(if (selected) colors.primary else colors.surface, LunchTheme.shapes.chip)
                .border(ComponentDefaults.hairlineWidth, if (selected) colors.primary else colors.hairlineStrong, LunchTheme.shapes.chip),
            contentAlignment = Alignment.Center,
        ) {
            if (selected) {
                LunchIconView(icon = LunchIcon.Check, size = PaywallDefaults.benefitIconSize, tint = colors.textOnPrimary)
            }
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
            LunchText(
                text = stringResource(if (pkg.isYearly) R.string.paywall_plan_yearly else R.string.paywall_plan_monthly),
                role = LunchTextRole.Heading,
            )
            LunchText(text = priceLine, role = LunchTextRole.Caption, color = colors.textSecondary)
        }
        if (pkg.isYearly) {
            LunchText(
                text = stringResource(R.string.paywall_plan_yearly_badge),
                role = LunchTextRole.Label,
                color = colors.textOnAction,
                modifier = Modifier
                    .background(colors.action, LunchTheme.shapes.chip)
                    .padding(horizontal = TokenSpacing.sm, vertical = TokenSpacing.xs),
            )
        }
    }
}

@LunchPreviews
@Composable
private fun PaywallViewPreview() {
    LunchPreviewSurface {
        PaywallView(
            packages = listOf(PreviewData.yearlyPackage, PreviewData.monthlyPackage),
            selectedIdentifier = PreviewData.yearlyPackage.identifier,
            onSelect = {},
            onSubscribe = {},
            onRestore = {},
            onTerms = {},
            onPrivacy = {},
            scrollable = false,
        )
    }
}
