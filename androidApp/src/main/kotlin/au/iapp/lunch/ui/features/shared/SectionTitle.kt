/**
 * @file SectionTitle.kt
 * @description Uppercase label heading above a group of rows or cards.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme

@Composable
fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    LunchText(text = text, role = LunchTextRole.Label, color = LunchTheme.colors.textSecondary, modifier = modifier)
}
