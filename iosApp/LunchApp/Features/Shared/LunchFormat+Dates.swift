//
//  LunchFormat+Dates.swift
//  LunchApp
//
//  Date formatting shared by Home, Track, groups, and invitations.
//

import Foundation

extension LunchFormat {
    /// "Thu 4 Sep, 12:30 pm"
    static func dayTime(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
    }

    /// "12:30 pm"
    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    /// "Today", "Yesterday", or "26 Aug".
    static func relativeDay(_ date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) { return "Yesterday" }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }

    /// "4 Sep 2026"
    static func day(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    /// "5 km" or "0.8 km"
    static func kilometres(_ km: Double) -> String {
        km == km.rounded() ? String(Int(km)) : km.fixed1
    }
}
