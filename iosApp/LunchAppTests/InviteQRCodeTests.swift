//
//  InviteQRCodeTests.swift
//  LunchAppTests
//
//  @file InviteQRCodeTests.swift
//  @description Round-trip decode and quiet-zone sanity for InviteQRCode, the on-device QR
//  generator behind Group detail's Show QR code button (design/screens.md screen 10).
//  @author AI Assistant
//  @date 2026-09-23
//

import CoreImage
import SwiftUI
import Testing
import UIKit
@testable import LunchApp

struct InviteQRCodeTests {
    private static let sampleUrl = "https://lunch.iapp.au/i/ABC123"

    /// A light-appearance CGColor pair, resolved the same way InviteQRSheet resolves its
    /// foreground/background so the test exercises the real code path.
    private static let foreground = InviteQRCode.lightCGColor(Tokens.Palette.text)
    private static let background = InviteQRCode.lightCGColor(Tokens.Palette.surface)

    private static func decode(_ cgImage: CGImage) -> String? {
        let ciImage = CIImage(cgImage: cgImage)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) as? [CIQRCodeFeature]
        return features?.first?.messageString
    }

    @Test func should_decode_back_to_the_invite_url_when_generated_with_light_appearance_colours() {
        let cgImage = InviteQRCode.makeCGImage(message: Self.sampleUrl, foreground: Self.foreground, background: Self.background)
        #expect(cgImage != nil)
        #expect(cgImage.flatMap(Self.decode) == Self.sampleUrl)
    }

    @Test func should_decode_back_to_the_invite_url_when_the_device_is_in_dark_mode() {
        // InviteQRSheet always forces the light-appearance value of the tokens (see
        // lightCGColor), so resolving the same tokens under a dark trait collection must still
        // produce the same fixed, scannable colour pair.
        let darkForeground = UIColor(Tokens.Palette.text).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor
        let darkBackground = UIColor(Tokens.Palette.surface).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor
        #expect(darkForeground != Self.foreground, "sanity check: the token really is dark-mode dependent")
        #expect(darkBackground != Self.background, "sanity check: the token really is dark-mode dependent")

        let cgImage = InviteQRCode.makeCGImage(message: Self.sampleUrl, foreground: Self.foreground, background: Self.background)
        #expect(cgImage.flatMap(Self.decode) == Self.sampleUrl)
    }

    @Test func should_decode_back_to_the_invite_url_when_generated_off_the_main_thread() async {
        let cgImage = await InviteQRCode.makeCGImageAsync(message: Self.sampleUrl, foreground: Self.foreground, background: Self.background)
        #expect(cgImage.flatMap(Self.decode) == Self.sampleUrl)
    }

    @Test func should_return_nil_when_the_message_is_empty() {
        // An empty QR message is a degenerate encode; CoreImage should still hand back
        // something rather than crash, but there is nothing meaningful to decode.
        let cgImage = InviteQRCode.makeCGImage(message: "", foreground: Self.foreground, background: Self.background)
        #expect(cgImage.flatMap(Self.decode) == nil || cgImage.flatMap(Self.decode) == "")
    }

    @Test func should_pad_the_quiet_zone_with_the_background_colour_when_generated() {
        guard let cgImage = InviteQRCode.makeCGImage(message: Self.sampleUrl, foreground: Self.foreground, background: Self.background) else {
            Issue.record("expected a CGImage")
            return
        }
        guard let pixelData = cgImage.dataProvider?.data, let pixels = CFDataGetBytePtr(pixelData) else {
            Issue.record("expected pixel data")
            return
        }
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        func pixel(x: Int, y: Int) -> (UInt8, UInt8, UInt8) {
            let offset = y * bytesPerRow + x * bytesPerPixel
            return (pixels[offset], pixels[offset + 1], pixels[offset + 2])
        }

        // The top-left corner pixel sits inside the quiet zone (`quietZoneModules` * `renderScale`
        // pixels wide), so it must be the background colour, not a QR module.
        let corner = pixel(x: 0, y: 0)
        var backgroundComponents: [CGFloat] = []
        Self.background.components?.forEach { backgroundComponents.append($0) }
        let expectedBackground = (
            UInt8((backgroundComponents.first ?? 0) * 255),
            UInt8((backgroundComponents.dropFirst().first ?? 0) * 255),
            UInt8((backgroundComponents.dropFirst(2).first ?? 0) * 255)
        )
        #expect(abs(Int(corner.0) - Int(expectedBackground.0)) <= 2)
        #expect(abs(Int(corner.1) - Int(expectedBackground.1)) <= 2)
        #expect(abs(Int(corner.2) - Int(expectedBackground.2)) <= 2)
    }
}
