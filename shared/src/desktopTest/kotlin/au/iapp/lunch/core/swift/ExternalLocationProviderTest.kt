/**
 * @file ExternalLocationProviderTest.kt
 * @description Contract tests for ExternalLocationProvider: permission gating,
 * fix delivery, first-fix waiting and the negative-accuracy convention.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.core.swift

import au.iapp.lunch.core.model.CoreError
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ExternalLocationProviderTest {

    private fun serviceCode(result: Result<*>): String = assertIs<CoreError.Service>(result.exceptionOrNull()).code

    @Test
    fun should_deny_when_permission_was_never_granted() = runTest {
        val provider = ExternalLocationProvider(firstFixTimeoutMillis = 0)
        provider.update(-33.8688, 151.2093)

        assertFalse(provider.hasPermission())
        assertEquals(ExternalLocationProvider.LOCATION_PERMISSION_DENIED, serviceCode(provider.current()))
    }

    @Test
    fun should_fail_with_NO_LOCATION_when_no_fix_arrives_before_the_timeout() = runTest {
        val provider = ExternalLocationProvider(firstFixTimeoutMillis = 0)
        provider.setPermission(true)

        assertTrue(provider.hasPermission())
        assertEquals(ExternalLocationProvider.NO_LOCATION, serviceCode(provider.current()))
    }

    @Test
    fun should_return_the_latest_fix_when_one_was_updated() = runTest {
        val provider = ExternalLocationProvider()
        provider.setPermission(true)
        provider.update(-33.8688, 151.2093, 12.0)
        provider.update(-37.8136, 144.9631, 5.0)

        val location = provider.current().getOrThrow()
        assertEquals(-37.8136, location.latitude)
        assertEquals(144.9631, location.longitude)
        assertEquals(5.0, location.accuracyMetres)
        assertEquals(location, provider.location.value)
    }

    @Test
    fun should_store_unknown_accuracy_when_the_accuracy_is_negative_or_omitted() = runTest {
        val provider = ExternalLocationProvider()
        provider.setPermission(true)

        provider.update(-33.8688, 151.2093, -1.0)
        assertNull(provider.current().getOrThrow().accuracyMetres)

        provider.update(-33.8688, 151.2093)
        assertNull(provider.current().getOrThrow().accuracyMetres)
    }

    @Test
    fun should_wait_for_the_first_fix_when_permission_is_granted() = runTest {
        val provider = ExternalLocationProvider() // default 10 s window, virtual time
        provider.setPermission(true)
        launch {
            delay(1_000)
            provider.update(-33.8688, 151.2093)
        }

        val location = provider.current().getOrThrow()
        assertEquals(-33.8688, location.latitude)
    }

    @Test
    fun should_forget_the_fix_when_cleared() = runTest {
        val provider = ExternalLocationProvider(firstFixTimeoutMillis = 0)
        provider.setPermission(true)
        provider.update(-33.8688, 151.2093)

        provider.clear()

        assertNull(provider.location.value)
        assertEquals(ExternalLocationProvider.NO_LOCATION, serviceCode(provider.current()))
    }

    @Test
    fun should_drop_the_stale_fix_when_permission_is_revoked_and_regranted() = runTest {
        val provider = ExternalLocationProvider(firstFixTimeoutMillis = 0)
        provider.setPermission(true)
        provider.update(-33.8688, 151.2093)

        provider.setPermission(false)
        assertFalse(provider.permissionGranted.value)
        assertEquals(ExternalLocationProvider.LOCATION_PERMISSION_DENIED, serviceCode(provider.current()))

        provider.setPermission(true)
        assertEquals(ExternalLocationProvider.NO_LOCATION, serviceCode(provider.current()))
    }
}
