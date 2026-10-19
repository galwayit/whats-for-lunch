//
//  Copy.swift
//  LunchApp
//
//  Every user-facing string. Keys and wording mirror design/copy.md (Australian English) so both
//  platforms ship identical words. Sections follow the copy deck; verbatim strings that the core
//  engines produce (recommendation reasons, impact messages) live with the engines.
//

import Foundation

nonisolated enum Copy {
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
        static let skip = "Skip"
        static let share = "Share"
        static let close = "Close"
    }

    enum Error {
        static let offlineTitle = "You're offline"
        static let offlineBody = "Check your connection and try again. Your logged meals are safe on this device."
        static let serviceTitle = "Something went wrong on our side"
        static let serviceBody = "We couldn't reach the lunch service. Try again in a moment."
        static let locationDeniedTitle = "Location is off"
        static let locationDeniedBody = "Turn on location for this app in Settings to find places near you."
        static let locationDeniedCta = "Open Settings"
        static let notLinkedTitle = "App setup required"
        static let notLinkedBody = "This build is missing its production service configuration. Add Config/Lunch.plist, then rebuild the app."
    }

    enum Onboarding {
        static let title = "Onboarding"
        static func step(_ index: Int) -> String { "STEP \(index) OF 5" }
        static let step1Eyebrow = "Getting started"
        static let step1Title = "Welcome to What We Have For Lunch"
        static let step1Body = "Discover and plan your daily meals with ease and joy."
        static let step1Cta = "Get Started"
        static let step2Eyebrow = "About you"
        static let step2Title = "What should we call you?"
        static let step2Placeholder = "Your first name"
        static let step3Eyebrow = "Your budget"
        static let step3Title = "Your budget"
        static let step3Body = "Pick a typical price level and how far you'll go."
        static func step3Distance(_ km: String) -> String { "Max distance: \(km) km" }
        static let step3Chains = "Include chain restaurants"
        static let step3ChainsHint = "McDonald's, Subway, KFC and similar"
        static let step4Eyebrow = "Dietary needs"
        static let step4Title = "Any dietary needs?"
        static let step4Body = "We'll only suggest places that work for you."
        static let step5Eyebrow = "Almost there"
        static let step5Title = "Find lunch near you"
        static let step5Body = "We use your location only while you're using the app, to find places within your distance."
        static let step5Cta = "Allow location"
        static let step5Skip = "Not now"
        static let finishCta = "Let's eat"
    }

    /// Dietary options: display label and the stored key, in deck order.
    enum Dietary {
        static let options: [(label: String, key: String)] = [
            ("Vegetarian", "vegetarian"),
            ("Vegan", "vegan"),
            ("Gluten free", "gluten_free"),
            ("Dairy free", "dairy_free"),
            ("Halal", "halal"),
            ("Kosher", "kosher"),
            ("Nut allergy", "nut_allergy"),
            ("Shellfish allergy", "shellfish_allergy"),
        ]
        static let none = (label: "None of these", key: "none")
        /// Keys that are allergens rather than diets.
        static let allergenKeys: Set<String> = ["nut_allergy", "shellfish_allergy"]
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
        static let groupRowTitle = "Lunch together"
        static let groupRowEmpty = "Invite friends and pick a place everyone can eat at."
        static let groupRowPlan = "Plan a group lunch"
        static let cravingPlaceholder = "Craving something? Ask the AI"
        static let whyTitle = "Why this place?"
    }

    enum AI {
        static let title = "AI recommendations"
        static let cravingPlaceholder = "What are you craving?"
        static let ask = "Ask"
        static let thinkingTitle = "Thinking about your lunch…"
        static let thinkingBody = "Matching cravings, budget and distance"
        static let historyTitle = "Earlier picks"
        static let emptyTitle = "Tell us what you feel like"
        static let emptyBody = "Cravings, a cuisine, or how much time you have. We'll pick three places."
        static let unavailableTitle = "AI recommendations unavailable"
        static let unavailableBody = "We couldn’t generate your lunch picks. Please try again later. You can still browse nearby places."
        static let noMatchesTitle = "No matching places nearby"
        static let noMatchesBody = "Try a wider distance or adjust your food preferences, then ask again."
        static let busyTitle = "AI is at capacity"
        static let busyBody = "AI requests have reached the service limit for now. Please try again later."
        static func confidence(_ level: String) -> String { "\(level) confidence" }
    }

    enum AIConsent {
        static let title = "Before we ask the AI"
        static func body(providers: String) -> String { "To pick places for you, Lunch sends your craving, budget, dietary preferences, recent meals, location and nearby places through Supabase to these AI providers: \(providers). If the main provider cannot respond, the backup may receive the same data. Group suggestions also include the group name, time, search area and past places. Do not include sensitive details in cravings or group names. Requests are sent only after you agree. You can withdraw permission in Profile." }
        static let agree = "Agree and continue"
        static let decline = "Not now"
        static let privacy = "How we handle your data"
    }

    enum Discover {
        static let title = "Lunch Explorer"
        static let searchPlaceholder = "Search for bowls, salads, or sushi…"
        static func count(_ n: Int) -> String { "\(n) Restaurants Found" }
        static func sort(_ option: String) -> String { "Sort: \(option)" }
        static let sortTitle = "Sort by"
        static let sortRelevance = "Relevance"
        static let sortPrice = "Price"
        static let sortDistance = "Distance"
        static let sortRating = "Rating"
        static let filterDietary = "Dietary"
        static let filterPrice = "Price"
        static let filterDistance = "Distance"
        static let filterRating = "Rating"
        static let filterDietaryTitle = "Dietary needs"
        static let filterPriceTitle = "Maximum price level"
        static let filterDistanceTitle = "Maximum distance"
        static let filterRatingTitle = "Minimum rating"
        static let filterApply = "Apply"
        static let filterClear = "Clear filters"
        static func chipPrice(_ label: String) -> String { "Price: \(label)" }
        static func chipDistance(_ km: String) -> String { "Distance: \(km) km" }
        static func chipRating(_ rating: String) -> String { "Rating: \(rating)+" }
        static func chipDietary(_ count: Int) -> String { "Dietary: \(count)" }
        static let openNow = "Open now"
        static let closed = "Closed"
        static let emptyTitle = "No restaurants found nearby"
        static let emptyBody = "Try adjusting your filters or search in a different area."
        static let detailReviews = "Reviews"
        static let detailOpenMaps = "Open in Maps"
        static let detailNoReviews = "No reviews yet"
        static let favouriteLimitTitle = "You've saved 10 favourites"
        static let favouriteLimitBody = "Lunch Pro keeps unlimited favourites."
        static let favouriteLimitCta = "See Lunch Pro"
    }

    enum Track {
        static let title = "Meal Tracker"
        static func ringLabel(spent: String, capacity: String) -> String { "\(spent) of \(capacity) this week" }
        static func ringRemaining(_ amount: String) -> String { "\(amount) left" }
        static let ringSetup = "Set weekly budget"
        static let logTitle = "Quick meal log"
        static let logType = "MEAL TYPE"
        static let typeBreakfast = "Breakfast"
        static let typeLunch = "Lunch"
        static let typeDinner = "Dinner"
        static let typeSnack = "Snack"
        static let logDate = "Date"
        static let costPlaceholder = "$0.00"
        static let placePlaceholder = "Where did you eat?"
        static let notesPlaceholder = "Notes (optional)"
        static let logged = "Logged"
        static let recentTitle = "Recent meals"
        static let recentEmptyTitle = "No meals logged yet"
        static let recentEmptyBody = "Start logging to track your dining journey."
        static let filterWeek = "This week"
        static let filterMonth = "This month"
        static let filterAll = "All time"
        static let historyGate = "Older meals are in Lunch Pro"
        static let historyGateBody = "Lunch Pro keeps your full history and insights."
        static let historyGateCta = "See Lunch Pro"
        static let impactLow = "Great choice! This experience fits well within your weekly investment plan."
        static let impactModerate = "Nice balance between enjoyment and your weekly goals."
        static let impactHigh = "A special experience - make sure it aligns with your priorities."
        static let impactVeryHigh = "This is a significant investment in your dining experience."
        static func achievementUnlocked(_ title: String) -> String { "Achievement unlocked: \(title)" }
    }

    enum Budget {
        static let title = "Weekly budget"
        static func step(_ index: Int) -> String { "STEP \(index) OF 3" }
        static let step1Title = "How much do you want to invest in lunch each week?"
        static let step2Title = "What kind of experiences do you enjoy?"
        static let step3Title = "Celebrate milestones?"
        static let step3Body = "We'll cheer when you hit a goal. No pressure, no guilt."
        static let celebrations = "Celebrate milestones"
        static let finish = "Save budget"
        static func perWeek(_ amount: String) -> String { "\(amount) a week" }
    }

    enum Profile {
        static let title = "Profile"
        static let badge = "FOOD EXPLORER"
        static let sectionPreferences = "YOUR PREFERENCES"
        static let sectionPro = "LUNCH PRO"
        static let sectionSettings = "SETTINGS"
        static let sectionAccount = "ACCOUNT"
        static let prefBudget = "Budget level"
        static let prefDistance = "Max distance"
        static let prefChains = "Include chains"
        static let chainsOn = "On"
        static let chainsOff = "Off"
        static let proFreeTitle = "Lunch Pro"
        static let proFreeBody = "Host group lunches, more AI picks, full history and PDF reports."
        static let proFreeCta = "See Lunch Pro"
        static func proActiveTitle(_ plan: String) -> String { "Lunch Pro · \(plan)" }
        static func proActiveRenews(_ date: String) -> String { "Renews \(date)" }
        static func proActiveExpires(_ date: String) -> String { "Ends \(date)" }
        static let proManage = "Manage subscription"
        static let proRestore = "Restore purchases"
        static let planYearly = "Yearly"
        static let planMonthly = "Monthly"
        static let signInTitle = "Sign in"
        static let signInBody = "Needed for AI picks, purchases and group hosting. Your meal journal stays on this device."
        static let signInApple = "Continue with Apple"
        static let signInGoogle = "Continue with Google"
        static let signOut = "Sign out"
        static func signedInAs(_ name: String) -> String { "Signed in as \(name)" }
        static let settingsEdit = "Edit preferences"
        static let settingsNotifications = "Notifications"
        static let settingsPrivacy = "Privacy"
        static let settingsHelp = "Help & support"
        static let exportData = "Export my data"
        static let deleteTitle = "Delete account"
        static let deleteBody = "This removes your account, groups, and invitations from our servers. Meals stay on this device unless you delete the app. Apple subscriptions continue until you cancel them in Manage subscription."
        static let deleteConfirm = "Delete"
    }

    enum Preferences {
        static let title = "Preferences"
        static let sectionBudget = "Budget preferences"
        static let sectionLocation = "Location preferences"
        static let sectionRestaurant = "Restaurant preferences"
        static let sectionDietary = "Dietary needs"
        static let sectionAllergens = "Allergens"
        static func weekly(_ amount: String) -> String { "Weekly budget: \(amount)" }
        static func distance(_ km: String) -> String { "Max travel distance: \(km) km" }
        static let saved = "Preferences saved"
    }

    enum Paywall {
        static let title = "Lunch Pro"
        static let subtitle = "Make lunch plans together and get more from your meal journal."
        static let planYearly = "Yearly"
        static let planYearlyBadge = "BEST VALUE"
        static let planMonthly = "Monthly"
        static func planMonthlyPrice(_ price: String) -> String { "\(price) a month" }
        static let benefits = [
            "Host group lunches",
            "Up to 10 AI requests a day, including group picks",
            "Full history and insights",
            "Unlimited favourites",
            "PDF export",
        ]
        static let ctaTrial = "Start free trial"
        static let ctaSubscribe = "Subscribe"
        static func priceDetail(_ package: ProPackage) -> String {
            let recurring = "\(package.localizedPrice) per \(package.periodLabel)"
            guard package.hasFreeTrial, let trial = package.trialLabel else { return recurring }
            return "\(trial), then \(recurring)"
        }
        static func legal(store: String, hasTrial: Bool = false) -> String {
            let charge = hasTrial ? "Payment is charged when the free trial ends." : "Payment is charged when you confirm the purchase."
            return "\(charge) Your subscription renews automatically at the displayed price and duration unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your \(store) subscription settings. AI allowances reset at 00:00 UTC."
        }

        static let restore = "Restore purchases"
        static let terms = "Terms of Use"
        static let privacy = "Privacy Policy"
        static let proBadge = "PRO"
        static let successTitle = "You're on Lunch Pro"
        static let successBody = "Group hosting, more AI picks, full history and PDF reports are unlocked."
        static let restoreNothing = "No purchases to restore"
        static let purchaseErrorTitle = "Subscription not updated"
        static let purchaseErrorBody = "The store couldn’t complete your request. Please try again. If you already completed a purchase, use Restore purchases."
        static let activationTitle = "Purchase needs attention"
        static let activationBody = "Your purchase completed, but Lunch Pro hasn’t been activated. Try Restore purchases. If it stays locked, contact support before purchasing again."
        static let paymentPendingTitle = "Payment pending"
        static let paymentPendingBody = "Your payment is awaiting approval. Lunch Pro will unlock once the store confirms it. You don’t need to purchase again."
        static let offlineBody = "Couldn’t reach the store. Check your connection and try again."
        static let signInRequiredBody = "Sign in before subscribing or restoring purchases."
        static let purchaseNotAllowedBody = "Purchases aren’t allowed on this device or account. Check your store and Screen Time settings."
        static let productUnavailableBody = "This plan is no longer available. Close and reopen Lunch Pro to refresh the plans."
        static let storeName = "App Store"
    }

    enum Gate {
        static let aiTitle = "You've used today's free AI pick"
        static func aiBody(resetTime: String) -> String {
            "Subscribe to Lunch Pro for 10 AI requests a day, shared with group suggestions. Your free request resets at \(resetTime)."
        }
        static let aiCta = "See Lunch Pro"
        static let hostTitle = "Hosting is a Lunch Pro feature"
        static let hostBody = "Create the group, pick the place, and invite friends for free."
        static let hostCta = "See Lunch Pro"
        static let guestOfferTitle = "Enjoyed the lunch?"
        static let guestOfferBody = "Lunch Pro lets you host the next one."
    }

    enum Push {
        /// push.reminder in design/copy.md: "%s is in an hour at %s".
        static func reminder(group: String, place: String) -> String { "\(group) is in an hour at \(place)" }
    }

    enum Info {
        static let privacyBody = "We store your meals and preferences on this device. Signing in copies them to your account so you can restore them on a new phone. We never sell your data. The full policy lives at lunch.iapp.au/privacy."
        static let helpBody = "Tap I AM HUNGRY for a pick near you, log what you ate in Track, and set a weekly budget so the ring can guide you. Questions? Email hello@iapp.au."
    }

    enum Group {
        static let createTitle = "New group lunch"
        static let namePlaceholder = "Group name"
        static let when = "When"
        static let whereLabel = "Around"
        static let radius = "Radius"
        static func radiusChip(_ km: Int) -> String { "\(km) km" }
        static let propose = "Propose places"
        static let proposalsTitle = "Pick a place"
        static let proposalsChoose = "Choose"
        static let detailInvite = "Invite friends"
        static let detailShare = "Share invite"
        static let detailQR = "Show QR code" // group.detail.qr
        static let qrTitle = "Scan to join" // group.qr.title
        static let qrBody = "Point the other phone's camera at this code to open the invitation." // group.qr.body
        static let detailGuests = "Guests"
        static let detailReminder = "Remind everyone an hour before"
        static let detailCancel = "Cancel lunch"
        static let detailAccepted = "Accepted"
        static let detailDeclined = "Declined"
        static let detailPending = "Pending"
        static let currentLocation = "Current location"
        static let locatingArea = "Finding your area…"
        static func inviteTitle(host: String) -> String { "\(host) invited you to lunch" }
        static func inviteAttending(_ count: Int) -> String { "\(count) going" }
        static let inviteAccept = "Accept"
        static let inviteDecline = "Decline"
        static let inviteAcceptedTitle = "You're in"
        static let inviteDeclinedTitle = "Maybe next time"
        static let inviteNamePrompt = "What's your name?"
        static let inviteGetApp = "Get the app"
        static let invitationTitle = "Invitation"
        static let invitationMissing = "This invitation isn't available"
        static let invitationMissingBody = "The link may have expired or the lunch was cancelled."
        static let choosingPlace = "Choosing a place"
        static let noProposals = "No places match this group yet"
        static let noProposalsBody = "Try a larger radius or adjust your restaurant preferences."
        static let locationReady = "Current location ready"
        static let locationRequired = "A location is needed to suggest nearby places."
        static let calendarAdded = "Added to Calendar"
        static let reminderSet = "Reminder set"
        static let groupCancelled = "Lunch cancelled"
        static let cancelTitle = "Cancel this lunch?"
        static let cancelBody = "The invitation will stop working for everyone."
    }

    enum Split {
        static let title = "Split the bill"
        static let open = "Split bill"
        static let groupOpen = "Split the bill"
        static let billLabel = "BILL TOTAL"
        static let billPlaceholder = "$0.00"
        static let surchargeLabel = "SURCHARGE %"
        static let surchargePlaceholder = "0"
        static let surchargeHelp = "Public holiday or card fee, if any"
        static let peopleLabel = "PEOPLE"
        static let personYou = "You"
        static func personN(_ n: Int) -> String { "Person \(n)" }
        static let personAdjusted = "Adjusted"
        static let personReset = "Reset"
        static func total(_ amount: String) -> String { "Total \(amount)" }
        static func totalSurcharge(_ amount: String, _ surcharge: String) -> String { "Total \(amount) incl. \(surcharge) surcharge" }
        static let payidLabel = "PAY ME AT"
        static let payidPlaceholder = "PayID, BSB and account, or cash"
        static let payidNote = "Kept on this phone only"
        static let share = "Share"
        static let useShare = "Use my share"
        static let errorNoBill = "Enter the bill total"
        static let errorNoPeople = "Add at least one person"
        static let errorTooMany = "Up to 50 people"
        static let errorSurcharge = "Surcharge must be 50% or less"
        static func errorOver(_ amount: String) -> String { "Adjusted amounts are \(amount) over the bill" }
        static func errorUnder(_ amount: String) -> String { "\(amount) of the bill isn't covered yet" }
        static let messagePlaceFallback = "Lunch"
        static func messageHeader(place: String, total: String, people: Int) -> String { "\(place): bill \(total) split \(people) ways" }
        static func messageLine(name: String, amount: String) -> String { "\(name): \(amount)" }
        static func messagePay(_ payId: String) -> String { "Pay me at: \(payId)" }
        static let messageFooter = "Split with What We Have For Lunch"
        static func note(people: Int, bill: String) -> String { "Split \(people) ways, bill \(bill)" }
    }
}
