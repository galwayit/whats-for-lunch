//
//  LunchAppDelegate.swift
//  LunchApp
//
//  Owns APNs/FCM registration and forwards FCM registration tokens to the shared core.
//

import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

@MainActor
final class LunchAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    var pushRegistrar: PushRegistrar? {
        didSet { submitPendingToken() }
    }

    private var isFirebaseConfigured = false
    private var pendingFCMToken: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        if
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let options = FirebaseOptions(contentsOfFile: path)
        {
            FirebaseApp.configure(options: options)
            Messaging.messaging().delegate = self
            isFirebaseConfigured = true
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard isFirebaseConfigured else { return }
        // FCM maps this APNs token to its own registration token. The backend sends
        // through FCM HTTP v1, so sending the raw APNs token would never work.
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        pendingFCMToken = fcmToken
        submitPendingToken()
    }

    private func submitPendingToken() {
        guard let token = pendingFCMToken, let pushRegistrar else { return }
        Task {
            do {
                try await pushRegistrar.register(token: token, platform: "ios")
                pendingFCMToken = nil
            } catch {
                // Keep the token so a later core assignment or refresh can retry.
            }
        }
    }

    static func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            if granted { UIApplication.shared.registerForRemoteNotifications() }
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
