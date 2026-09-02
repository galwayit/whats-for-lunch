//
//  Copy.swift
//  LunchApp
//
//  User-facing strings used by the design system and the gallery. Keys and wording mirror
//  design/copy.md (Australian English) so both platforms ship identical words. Only the
//  strings that components need today live here; screens add their own sections later.
//

import Foundation

enum Copy {
    enum App {
        static let name = "What We Have For Lunch"
    }

    enum Tab {
        static let home = "HOME"
        static let discover = "DISCOVER"
        static let track = "TRACK"
        static let profile = "PROFILE"
    }

    enum Action {
        static let `continue` = "Continue"
        static let back = "Back"
        static let done = "Done"
        static let cancel = "Cancel"
        static let save = "Save"
        static let retry = "Try again"
        static let searchAgain = "Search again"
        static let directions = "Directions"
        static let logThisMeal = "Log this meal"
        static let addToCalendar = "Add to calendar"
    }

    enum Error {
        static let offlineTitle = "You're offline"
        static let offlineBody = "Check your connection and try again. Your logged meals are safe on this device."
        static let serviceTitle = "Something went wrong on our side"
        static let serviceBody = "We couldn't reach the lunch service. Try again in a moment."
    }

    enum Home {
        static let eyebrow = "LUNCH PLANNER"
        static func greeting(_ name: String) -> String { "Hi, \(name)!" }
        static let subtitle = "Ready for your next meal?"
        static let hero = "I AM HUNGRY"
        static let searchingTitle = "Finding your perfect meal…"
        static let searchingBody = "Based on your preferences"
        static func picksBadge(_ count: Int) -> String { "\(count) PICKS READY TODAY" }
        static let resultEyebrow = "TODAY'S PICK"
        static let resultWhy = "Why this?"
        static let resultMore = "Show me more"
        static let resultReject = "Not this one"
        static let emptyTitle = "Nothing nearby fits yet"
        static let emptyBody = "Try a wider distance or a different price level, or browse Discover."
        static let emptyDiscover = "Try Discover"
        static let groupRowPlan = "Plan a group lunch"
    }

    enum Discover {
        static let searchPlaceholder = "Search for bowls, salads, or sushi…"
        static let openNow = "Open now"
        static let closed = "Closed"
        static let emptyTitle = "No restaurants found nearby"
        static let emptyBody = "Try adjusting your filters or search in a different area."
        static let filterPriceTitle = "Maximum price level"
        static let filterApply = "Apply"
        static let filterClear = "Clear filters"
    }

    enum Track {
        static func ringLabel(spent: String, capacity: String) -> String { "\(spent) of \(capacity) this week" }
        static func ringRemaining(_ amount: String) -> String { "\(amount) left" }
        static let ringSetup = "Set weekly budget"
        static let costPlaceholder = "$0.00"
        static let placePlaceholder = "Where did you eat?"
        static let historyGate = "Older meals are in Lunch Pro"
    }

    enum Profile {
        static let proFreeTitle = "Lunch Pro"
        static let proFreeBody = "Host group lunches, unlimited AI picks, full history."
        static let proFreeCta = "Try free for 7 days"
        static func proActiveTitle(_ plan: String) -> String { "Lunch Pro · \(plan)" }
        static func proActiveRenews(_ date: String) -> String { "Renews \(date)" }
        static func proActiveExpires(_ date: String) -> String { "Ends \(date)" }
        static let proManage = "Manage subscription"
        static let proRestore = "Restore purchases"
    }

    enum Paywall {
        static let title = "Lunch Pro"
        static let subtitle = "Everything the free tier does, without the limits."
        static let planYearly = "Yearly"
        static func planYearlyTrial(_ price: String) -> String { "7-day free trial, then \(price) a year" }
        static let planYearlyBadge = "BEST VALUE"
        static let planMonthly = "Monthly"
        static func planMonthlyPrice(_ price: String) -> String { "\(price) a month" }
        static let benefits = [
            "Host group lunches",
            "Unlimited AI recommendations",
            "Full history and insights",
            "Backup and sync",
            "Unlimited favourites",
            "PDF export",
        ]
        static let ctaTrial = "Start free trial"
        static let ctaSubscribe = "Subscribe"
        static func legal(store: String) -> String {
            "Payment is charged to your \(store) account when the trial ends. The subscription renews automatically at the same price unless cancelled at least 24 hours before the end of the period. Manage or cancel any time in your \(store) subscription settings."
        }
        static let restore = "Restore purchases"
        static let terms = "Terms of Use"
        static let privacy = "Privacy Policy"
        static let proBadge = "PRO"
    }

    enum Gate {
        static let aiTitle = "You've used today's free AI pick"
        static func aiBody(resetTime: String) -> String {
            "Lunch Pro makes it unlimited, with cravings and insights. Your free pick resets at \(resetTime)."
        }
        static let aiCta = "See Lunch Pro"
        static let hostTitle = "Hosting is a Lunch Pro feature"
        static let hostBody = "Create the group, pick the place, and invite friends for free."
        static let hostCta = "Start free trial"
    }

    enum Group {
        static let proposalsChoose = "Choose"
        static let detailShare = "Share invite"
        static let detailAccepted = "Accepted"
        static let detailDeclined = "Declined"
        static let detailPending = "Pending"
        static func inviteTitle(host: String) -> String { "\(host) invited you to lunch" }
        static func inviteAttending(_ count: Int) -> String { "\(count) going" }
        static let inviteAccept = "Accept"
        static let inviteDecline = "Decline"
    }
}
