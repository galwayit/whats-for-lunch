//
//  GroupCalendar.swift
//  LunchApp
//
//  @file GroupCalendar.swift
//  @description Writes an accepted group lunch into the system calendar with EventKit write-only access.
//  @author AI Assistant
//  @date 2026-09-03
//

import EventKit
import Foundation

enum GroupCalendar {
    static func add(_ invitation: Invitation) async throws {
        let store = EKEventStore()
        let granted = try await store.requestWriteOnlyAccessToEvents()
        guard granted else { throw CoreError.service(code: "CALENDAR_DENIED", message: "Calendar access is disabled") }

        let event = EKEvent(eventStore: store)
        event.title = invitation.group.name
        event.startDate = invitation.group.scheduledAt
        event.endDate = invitation.group.scheduledAt.addingTimeInterval(3_600)
        event.location = invitation.group.placeAddress ?? invitation.group.placeName
        event.notes = invitation.inviteUrl
        event.calendar = store.defaultCalendarForNewEvents
        try store.save(event, span: .thisEvent)
    }
}
