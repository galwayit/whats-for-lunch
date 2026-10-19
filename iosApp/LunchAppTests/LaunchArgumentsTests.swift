//
//  LaunchArgumentsTests.swift
//  LunchAppTests
//
//  @file LaunchArgumentsTests.swift
//  @description Parsing of the launch arguments used by Maestro and screenshot runs, including
//  the preview-only `-openRoute` names.
//  @author AI Assistant
//  @date 2026-09-03
//

import Testing
@testable import LunchApp

struct LaunchArgumentsTests {
    @Test func should_default_everything_off_when_no_arguments_given() {
        let args = LaunchArguments(["LunchApp"])
        #expect(args.usesPreviewCore == false)
        #expect(args.isPro == false)
        #expect(args.isSignedIn == false)
        #expect(args.isOffline == false)
        #expect(args.aiUsedToday == false)
        #expect(args.isOnboarded == true)
        #expect(args.inviteCode == nil)
        #expect(args.openRoute == nil)
    }

    @Test func should_treat_bare_flag_and_one_as_true_when_parsing_flags() {
        let args = LaunchArguments(["LunchApp", "-previewCore", "-isPro", "1", "-signedIn"])
        #expect(args.usesPreviewCore)
        #expect(args.isPro)
        #expect(args.isSignedIn)
    }

    @Test func should_treat_zero_false_and_no_as_false_when_parsing_flags() {
        #expect(LaunchArguments(["-onboarded", "0"]).isOnboarded == false)
        #expect(LaunchArguments(["-onboarded", "false"]).isOnboarded == false)
        #expect(LaunchArguments(["-onboarded", "NO"]).isOnboarded == false)
    }

    @Test func should_return_value_when_flag_has_a_token() {
        #expect(LaunchArguments(["-openInvite", "K7P2QX"]).inviteCode == "K7P2QX")
        #expect(LaunchArguments(["-gallerySection", "cards"]).gallerySection == "cards")
    }

    @Test func should_return_nil_when_value_flag_is_followed_by_another_flag() {
        #expect(LaunchArguments(["-openInvite", "-isPro"]).inviteCode == nil)
        #expect(LaunchArguments(["-openInvite"]).inviteCode == nil)
    }

    @Test func should_parse_open_route_when_preview_core_is_on() {
        #expect(LaunchArguments(["-previewCore", "-openRoute", "paywall"]).openRoute == .paywall)
        #expect(LaunchArguments(["-previewCore", "-openRoute", "groupDetail:grp_1"]).openRoute == .groupDetail(groupId: "grp_1"))
        #expect(LaunchArguments(["-previewCore", "-openRoute", "invitation:K7P2QX"]).openRoute == .invitation(code: "K7P2QX"))
        #expect(LaunchArguments(["-previewCore", "-openRoute", "tab:track"]).openRoute == .tab(.track))
        #expect(LaunchArguments(["-previewCore", "-openRoute", "ai"]).openRoute == .aiRecommendations(pickPlaceId: nil))
        #expect(LaunchArguments(["-previewCore", "-openRoute", "splitBill"]).openRoute == .splitBillDemo)
    }

    @Test func should_ignore_open_route_when_preview_core_is_off() {
        #expect(LaunchArguments(["-openRoute", "paywall"]).openRoute == nil)
    }

    @Test func should_return_nil_when_route_name_is_unknown() {
        #expect(AppRoute(launchName: "nope") == nil)
        #expect(AppRoute(launchName: "tab:nope") == nil)
        #expect(AppRoute(launchName: "paywall:extra") == nil)
        #expect(AppRoute(launchName: "groupDetail") == nil)
    }
}
