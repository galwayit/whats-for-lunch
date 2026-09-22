/**
 * @file ChipGrid.kt
 * @description A wrapping row of selectable chips, used for dietary, allergen and category
 * choices.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import au.iapp.lunch.ui.components.Chip
import au.iapp.lunch.ui.theme.TokenSpacing

/** @param options label and key pairs; [selected] holds the keys currently on. */
@Composable
fun ChipGrid(
    options: List<Pair<String, String>>,
    selected: Set<String>,
    onToggle: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    FlowRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
    ) {
        options.forEach { (key, label) ->
            Chip(text = label, selected = key in selected, onClick = { onToggle(key) })
        }
    }
}
