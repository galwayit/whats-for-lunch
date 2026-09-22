/**
 * @file LaunchArgumentsTest.kt
 * @description Parsing of the launch extras that select the preview core and seed its state.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LaunchArgumentsTest {

    @Test
    fun should_use_real_core_defaults_when_no_extras() {
        val args = LaunchArguments.from(emptyMap())
        assertFalse(args.usesPreviewCore)
        assertFalse(args.showsGallery)
        assertFalse(args.isPro)
        assertTrue(args.isOnboarded)
        assertNull(args.inviteCode)
    }

    @Test
    fun should_read_boolean_extras_when_passed_with_ez() {
        val args = LaunchArguments.from(
            mapOf(
                LaunchArguments.PREVIEW_CORE to true,
                LaunchArguments.IS_PRO to true,
                LaunchArguments.SIGNED_IN to true,
                LaunchArguments.OFFLINE to true,
                LaunchArguments.AI_USED_TODAY to true,
                LaunchArguments.ONBOARDED to false,
            ),
        )
        assertTrue(args.usesPreviewCore)
        val options = args.previewOptions
        assertTrue(options.isPro)
        assertTrue(options.isSignedIn)
        assertTrue(options.isOffline)
        assertTrue(options.aiUsedToday)
        assertFalse(options.isOnboarded)
    }

    @Test
    fun should_accept_string_booleans_when_passed_with_es() {
        val args = LaunchArguments.from(mapOf(LaunchArguments.PREVIEW_CORE to "1", LaunchArguments.IS_PRO to "false", LaunchArguments.ONBOARDED to "no"))
        assertTrue(args.usesPreviewCore)
        assertFalse(args.isPro)
        assertFalse(args.isOnboarded)
    }

    @Test
    fun should_trim_string_extras_when_reading_invite_and_routes() {
        val args = LaunchArguments.from(
            mapOf(
                LaunchArguments.OPEN_INVITE to " K7P2QX ",
                LaunchArguments.GALLERY to true,
                LaunchArguments.GALLERY_SECTION to "buttons",
                LaunchArguments.OPEN_ROUTE to "   ",
            ),
        )
        assertEquals("K7P2QX", args.inviteCode)
        assertTrue(args.showsGallery)
        assertEquals("buttons", args.gallerySection)
        assertNull(args.openRoute)
    }
}
