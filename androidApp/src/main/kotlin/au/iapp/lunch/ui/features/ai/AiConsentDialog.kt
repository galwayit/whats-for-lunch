package au.iapp.lunch.ui.features.ai

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import au.iapp.lunch.core.model.AiProviderDisclosure
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable

@Composable
fun AiConsentDialog(providers: List<AiProviderDisclosure>, onAllow: () -> Unit, onDecline: () -> Unit) {
    val uriHandler = LocalUriHandler.current
    AlertDialog(
        onDismissRequest = onDecline,
        title = { Text("Share data for AI recommendations?") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                Text("To make recommendations, Lunch sends your cravings, dietary preferences, budget, recent meals, location and nearby places through Supabase to: ${providers.joinToString { it.name }}. If the main provider cannot respond, the backup may receive the same data. Group suggestions also include the group name, time, search area and past places. Do not include sensitive details in cravings or group names. Agree only if you allow this sharing for this screen. You can use restaurant search without AI.")
                providers.forEach { provider ->
                    TextButton(onClick = { uriHandler.openUri(provider.privacyUrl) }) { Text("${provider.name} privacy policy") }
                }
            }
        },
        confirmButton = { TextButton(onClick = onAllow) { Text("Agree and continue") } },
        dismissButton = { TextButton(onClick = onDecline) { Text("Not now") } },
    )
}
