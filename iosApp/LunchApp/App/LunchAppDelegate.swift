//
//  LunchAppDelegate.swift
//  LunchApp
//
//  Owns the notification centre delegate for the device-local group lunch reminders.
//  Remote push (APNs/FCM) is out of 1.0; when it returns, this is where registration goes.
//

import UIKit
import UserNotifications

@MainActor
final class LunchAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// Asks for alert and sound permission for local lunch reminders only. No badge, no remote registration.
    static func requestNotificationPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            // The system owns permission UI; users can retry from Profile or iOS Settings.
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
