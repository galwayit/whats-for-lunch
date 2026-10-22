//
//  GroupReminder.swift
//  LunchApp
//
//  @file GroupReminder.swift
//  @description Local notification one hour before a group lunch (UserNotifications). The reminder is device-local because the core exposes no reminder contract yet.
//  @author AI Assistant
//  @date 2026-09-03
//

import Foundation
import UserNotifications

enum GroupReminder {
    static func schedule(_ group: LunchGroup) async throws {
        let fireDate = group.scheduledAt.addingTimeInterval(-3_600)
        guard fireDate > Date() else {
            throw CoreError.service(code: "REMINDER_IN_PAST", message: "Reminder time has passed")
        }
        let centre = UNUserNotificationCenter.current()
        let granted = try await centre.requestAuthorization(options: [.alert, .sound])
        guard granted else { throw CoreError.service(code: "NOTIFICATION_DENIED", message: "Notifications are disabled") }

        let content = UNMutableNotificationContent()
        content.title = group.name
        content.body = Copy.Push.reminder(group: group.name, place: group.placeName ?? Copy.Group.choosingPlace)
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let request = UNNotificationRequest(
            identifier: identifier(group.id),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        try await centre.add(request)
    }

    /// True when a reminder for this group is still pending on this device.
    static func isScheduled(groupId: String) async -> Bool {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.contains { $0.identifier == identifier(groupId) }
    }

    static func cancel(groupId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(groupId)])
    }

    private static func identifier(_ groupId: String) -> String { "group-reminder-\(groupId)" }
}
