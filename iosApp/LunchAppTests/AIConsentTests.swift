//
//  AIConsentTests.swift
//  LunchAppTests
//
//  @file AIConsentTests.swift
//  @description App Review 5.1.2(i): nothing reaches the third-party AI until the user agrees,
//  agreement is remembered, and "Not now" sends nothing.
//  @author AI Assistant
//  @date 2026-09-23
//

import Foundation
import Testing
@testable import LunchApp

@MainActor
private func freshConsent(granted: Bool = false) -> AIDataConsent {
    let suite = "AIConsentTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let consent = AIDataConsent(defaults: defaults)
    if granted { consent.grant(version: "preview-ai-v2") }
    return consent
}

@MainActor
struct AIConsentTests {
    @Test func preview_consent_does_not_replace_live_provider_consent() {
        let live = AIDataConsent(preview: false)
        let preview = AIDataConsent(preview: true)
        let originalLiveVersion = live.version
        let originalPreviewVersion = preview.version
        defer {
            if let originalPreviewVersion { preview.grant(version: originalPreviewVersion) }
            else { preview.revoke() }
        }

        let version = "preview-isolation-\(UUID().uuidString)"
        preview.grant(version: version)

        #expect(preview.isGranted(for: version))
        #expect(live.version == originalLiveVersion)
    }

    @Test func should_ask_for_consent_and_send_nothing_when_consent_is_missing() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil, consent: freshConsent())

        await model.ask()

        #expect(model.needsConsent)
        #expect(model.state.value == nil)
        #expect(!model.state.isLoading)
    }

    @Test func should_send_the_request_when_user_agrees() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil, consent: freshConsent())
        await model.ask()

        await model.grantConsent()

        #expect(!model.needsConsent)
        #expect(model.state.value != nil)
    }

    @Test func should_send_nothing_when_user_declines() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil, consent: freshConsent())
        await model.ask()

        model.declineConsent()

        #expect(!model.needsConsent)
        #expect(model.state.value == nil)
    }

    @Test func should_not_ask_again_when_consent_was_already_given() async {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil, consent: freshConsent(granted: true))

        await model.ask()

        #expect(!model.needsConsent)
        #expect(model.state.value != nil)
    }

    @Test func should_remember_consent_when_read_back_from_the_same_defaults() {
        let suite = "AIConsentTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let first = AIDataConsent(defaults: defaults)

        first.grant(version: "preview-ai-v2")

        #expect(AIDataConsent(defaults: defaults).isGranted)
    }

    @Test func changed_provider_requires_new_permission_before_another_recommendation() async throws {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        let consent = freshConsent(granted: true)
        let model = AIRecommendationsViewModel(core: core, pickPlaceId: nil, consent: consent)
        let service = try #require(core.ai as? PreviewAiService)
        service.aiConfiguration = AiConfiguration(consentVersion: "new-provider", providers: [AiProviderDisclosure(name: "Another provider", privacyUrl: "https://example.com/privacy")])
        await model.ask()
        #expect(model.needsConsent)
        #expect(model.state.value == nil)
        #expect(model.aiConfiguration?.providers.first?.name == "Another provider")
        #expect(!consent.isGranted(for: "new-provider"))
        await model.grantConsent()
        #expect(consent.isGranted(for: "new-provider"))
        #expect(model.state.value != nil)
    }

    @Test func old_boolean_permission_does_not_authorise_current_providers() {
        let defaults = UserDefaults(suiteName: "AIConsentTests.\(UUID().uuidString)")!
        defaults.set(true, forKey: "aiDataSharingConsent20261001")
        let consent = AIDataConsent(defaults: defaults)
        #expect(!consent.isGranted(for: "preview-ai-v2"))
        consent.grant(version: "provider-a")
        #expect(!consent.isGranted(for: "provider-b"))
        consent.revoke()
        #expect(!consent.isGranted)
    }

    @Test func group_provider_change_requires_new_permission() async throws {
        let core = PreviewLunchCore(options: PreviewCoreOptions(isPro: true, isSignedIn: true))
        let model = GroupProposalsViewModel(core: core, groupId: PreviewData.group.id, consent: freshConsent(granted: true))
        let service = try #require(core.ai as? PreviewAiService)
        service.aiConfiguration = AiConfiguration(consentVersion: "new-provider", providers: [AiProviderDisclosure(name: "Another provider", privacyUrl: "https://example.com/privacy")])
        await model.load()
        #expect(model.needsConsent)
        #expect(model.proposals.isEmpty)
        await model.grantConsent()
        #expect(!model.needsConsent)
        #expect(!model.proposals.isEmpty)
    }
}
