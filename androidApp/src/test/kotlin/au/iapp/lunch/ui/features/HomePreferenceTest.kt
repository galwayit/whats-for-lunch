package au.iapp.lunch.ui.features

import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.ui.features.home.HeroUiState
import au.iapp.lunch.ui.features.home.HomeViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class HomePreferenceTest {
    @get:Rule val main = MainDispatcherRule()

    @Test fun saving_preferences_clears_the_previous_pick() = runTest(main.dispatcher) {
        val app = AppEnvironment.preview(PreviewCoreOptions(latencyMs = 0))
        val model = HomeViewModel(app)
        advanceUntilIdle()
        model.search(app.user.value!!.preferences)
        advanceUntilIdle()
        assertTrue(model.state.value.hero is HeroUiState.Result)

        val prefs = app.user.value!!.preferences
        app.core.users.updatePreferences(prefs.copy(includeChains = !prefs.includeChains)).getOrThrow()
        advanceUntilIdle()
        assertEquals(HeroUiState.Idle, model.state.value.hero)
        assertEquals(0, model.state.value.picksCount)
    }

    @Test fun old_search_cannot_restore_a_pick_after_preferences_change() = runTest(main.dispatcher) {
        val app = AppEnvironment.preview(PreviewCoreOptions(latencyMs = 600))
        val model = HomeViewModel(app)
        advanceUntilIdle()
        model.search(app.user.value!!.preferences)
        runCurrent()
        assertEquals(HeroUiState.Searching, model.state.value.hero)

        val prefs = app.user.value!!.preferences
        app.core.users.updatePreferences(prefs.copy(includeChains = !prefs.includeChains)).getOrThrow()
        advanceUntilIdle()
        assertEquals(HeroUiState.Idle, model.state.value.hero)
        assertEquals(0, model.state.value.picksCount)
    }
}
