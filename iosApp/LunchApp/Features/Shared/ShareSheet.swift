/**
 * @file ShareSheet.swift
 * @description System share sheet (UIActivityViewController) for invite links and data exports.
 * @author AI Assistant
 * @date 2026-09-03
 */

import SwiftUI
import UIKit

/// Wraps `UIActivityViewController` so it can be presented with `.sheet`.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// `Identifiable` payload for `.sheet(item:)`.
struct ShareItem: Identifiable {
    let url: URL
    var id: URL { url }
}
