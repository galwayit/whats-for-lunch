//
//  InviteQRCode.swift
//  LunchApp
//
//  On-device QR generation for the Group detail QR sheet (design/screens.md screen 10, id
//  invite_qr_image): CoreImage only, no third-party library, no network call. Colours are passed
//  in by the caller so this stays free of SwiftUI/the design tokens and is cheap to unit test
//  (see InviteQRCodeTests). Everything here is `nonisolated`: CIContext/CIFilter work is meant to
//  run off the main thread, and HANDOFF.md #3 documents the crash that happens the moment a
//  colour-resolving closure is treated as main-actor work by this target's
//  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` default.
//

import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

nonisolated enum InviteQRCode {
    /// Matches design/screens.md's QR sheet contract.
    private static let correctionLevel = "M"

    /// Modules of light quiet zone required around the code on every side.
    static let quietZoneModules = 4

    /// Integer up-scale applied to CoreImage's 1-pixel-per-module output. An integer factor maps
    /// every source pixel onto an exact block of destination pixels, so combined with
    /// `.interpolation(.none)` where the image is displayed, module edges never blur.
    static let renderScale = 10

    /// Builds the QR code for `message`: `foreground` modules on a `background` field, with a
    /// `quietZoneModules`-module `background` border on every side. Returns `nil` if the message
    /// can't be encoded or CoreImage fails to render it.
    static func makeCGImage(message: String, foreground: CGColor, background: CGColor) -> CGImage? {
        guard let data = message.data(using: .utf8) else { return nil }

        let qrFilter = CIFilter.qrCodeGenerator()
        qrFilter.message = data
        qrFilter.correctionLevel = correctionLevel
        guard let rawCode = qrFilter.outputImage else { return nil }

        // CIQRCodeGenerator's output is an opaque black/white bitmap; CIFalseColor remaps the
        // black modules to `foreground` and the white field to `background` so the same symbol
        // can be forced to a fixed colour pair regardless of the app's current colour scheme.
        let colourFilter = CIFilter.falseColor()
        colourFilter.inputImage = rawCode
        colourFilter.color0 = CIColor(cgColor: foreground)
        colourFilter.color1 = CIColor(cgColor: background)
        guard let recoloured = colourFilter.outputImage else { return nil }

        // The raw generator output is exactly 1 pixel per module before scaling, so insetting by
        // `quietZoneModules` pixels here is exactly that many modules, whatever the symbol's
        // module count turns out to be.
        let zone = CGFloat(quietZoneModules)
        let paddedExtent = recoloured.extent.insetBy(dx: -zone, dy: -zone)
        let backgroundField = CIImage(color: CIColor(cgColor: background)).cropped(to: paddedExtent)
        let padded = recoloured.composited(over: backgroundField)

        let scaled = padded.transformed(by: CGAffineTransform(scaleX: CGFloat(renderScale), y: CGFloat(renderScale)))

        // A fixed format and colour space keep the pixel layout deterministic (RGBA8, one byte
        // per channel in that order), which InviteQRCodeTests relies on for its quiet-zone check.
        let context = CIContext()
        return context.createCGImage(scaled, from: scaled.extent, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
    }

    /// Runs `makeCGImage` off the main thread. The closure is explicit `@Sendable` in this
    /// `nonisolated` function so it is never inferred as main-actor work (HANDOFF.md #3).
    static func makeCGImageAsync(message: String, foreground: CGColor, background: CGColor) async -> CGImage? {
        await Task.detached(priority: .userInitiated) { @Sendable in
            makeCGImage(message: message, foreground: foreground, background: background)
        }.value
    }

    /// Resolves `color` (typically a `Tokens.Palette` dynamic colour) to its light-appearance
    /// `CGColor` regardless of the device's current interface style. Used to pick a fixed
    /// dark-on-light pair for the QR code so it scans in both themes, without introducing a
    /// literal colour: the value still comes entirely from the token's own light-mode definition.
    static func lightCGColor(_ color: Color) -> CGColor {
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).cgColor
    }
}
