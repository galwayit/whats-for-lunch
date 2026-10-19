//
//  LunchConfigTests.swift
//  LunchAppTests
//
//  @file LunchConfigTests.swift
//  @description The runtime half of the "no RevenueCat Test Store key in Release" guard. The build
//  script `iosApp/scripts/copy_runtime_config.sh` is the first line of defence; this checks that a
//  Release binary would still refuse a `test_` key that slipped through.
//  @author AI Assistant
//  @date 2026-09-23
//

import Foundation
import Testing
@testable import LunchApp

struct LunchConfigTests {
    @Test func should_drop_test_store_key_when_test_store_is_not_allowed() {
        #expect(LunchConfig.revenueCatKey("test_abc123", allowingTestStore: false) == nil)
    }

    @Test func should_keep_test_store_key_when_test_store_is_allowed() {
        #expect(LunchConfig.revenueCatKey("test_abc123", allowingTestStore: true) == "test_abc123")
    }

    @Test func should_keep_production_key_when_test_store_is_not_allowed() {
        #expect(LunchConfig.revenueCatKey("appl_abc123", allowingTestStore: false) == "appl_abc123")
    }

    @Test func should_return_nil_when_key_is_missing() {
        #expect(LunchConfig.revenueCatKey(nil, allowingTestStore: false) == nil)
    }

    @Test func should_leave_release_config_incomplete_when_only_a_test_store_key_is_present() {
        let config = LunchConfig(
            supabaseUrl: "https://example.supabase.co",
            supabaseAnonKey: "anon",
            backendBaseUrl: "https://example.supabase.co/functions/v1",
            revenueCatApiKey: LunchConfig.revenueCatKey("test_abc123", allowingTestStore: false)
        )

        #expect(!config.isComplete(allowingMissingPurchases: false))
    }

    @Test func should_allow_test_store_key_in_the_debug_configuration_tests_run() {
        #expect(LunchConfig.allowsTestStoreKey, "tests run the Debug configuration")
    }
}
