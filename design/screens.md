# Screen specifications

The contract both platforms build to. Components come from the design system; strings from
`design/copy.md`; data from the shared core (`shared/src/commonMain/kotlin/au/iapp/lunch/core/api/Contracts.kt`).
Accessibility identifiers (test ids) are used by `maestro/flows` and must exist on both platforms
with exactly these names.

Global rules: every colour from tokens; every screen has light and dark snapshots; text scale
clamped 0.8 to 2.0; reduced motion respected; loading, empty, offline, and service-error states
on every screen that fetches.

## Navigation

Four tabs: Home, Discover, Track, Profile. Onboarding runs first when `users.hasCompletedOnboarding`
is false. Modal stacks from Home: AI recommendations, Group lunch (host), Paywall. From Profile:
Preferences, Sign in, Privacy, Help. From Track: Budget setup. Invitation links open the Invitation
screen from anywhere.

## 1. Onboarding (5 steps)

- Progress bar + "STEP n OF 5" eyebrow + step label (top). Card in the middle. Primary CTA at the bottom.
- Step 1 welcome: icon disc, title, body, image placeholder, CTA `Get Started`.
- Step 2 name: text field id `onboarding_name_field`, CTA disabled until non-empty.
- Step 3 budget: four price chips ($ to $$$$, default $$), distance slider 1..20 km (default 5), chains toggle.
- Step 4 dietary: chip grid from copy.md; "None of these" clears others.
- Step 5 location pre-prompt: explains why, CTA `Allow location` triggers the system prompt, secondary `Not now`.
- Finish: creates the user through `UserRepository.createUser`, lands on Home, and the hero performs the first search automatically.
- Test ids: `onboarding_name_field`.

## 2. Home

- Header: avatar disc (initial), eyebrow `LUNCH PLANNER`, no bell.
- Greeting `Hi, {name}!` + subtitle.
- HeroHungryButton id `hero_hungry_button`. Tap → searching state (spinner ring + copy) → result.
- Result: RecommendationCard id `recommendation_card` with photo, name, rating, three reasons from `RecommendationEngine.reasons`, actions `Directions`, `Log this meal`, `Why this?` (opens AI screen with the pick), `Show me more` (opens AI screen), `Not this one` (adds to rejected set and searches again).
- Picks badge `{n} PICKS READY TODAY` shows the count of candidates above the 0.1 threshold; hidden when zero.
- Lunch together row: active groups (host or guest) as GroupCards, `Plan a group lunch` button → host flow or the host gate.
- Empty state: `home.empty.*` with `Try Discover`. Offline and service-error variants.
- Pro users see a craving field above the hero (id `craving_field_home`) that routes to the AI screen.

## 3. AI recommendations

- Header with back. Craving field id `craving_field`, `Ask` button.
- Results: cards id `ai_result_{i}` with confidence chip, reasoning paragraph, investment summary, actions.
- Free gate: after the daily limit the `Ask` action shows the UpsellRow `gate.ai.*` with reset time; CTA `See Lunch Pro` opens Paywall.
- History section (last 5) for Pro; free shows today's only.

## 4. Discover

- Sticky header: title `Lunch Explorer`, search field (debounced 400 ms), count line, sort chip (sheet with four options).
- Filter bar: Dietary (sheet with chips), Price (sheet, ids `$`..`$$$$`, title `Maximum price level`, `Apply`), Distance (slider sheet), Rating (stepper sheet). Applied filters render as selected chips with the value, e.g. `Price: $$`.
- List: RestaurantCard id `restaurant_card_{i}` with favourite button id `favourite_button_{i}` (selected variant id `favourite_button_{i}_selected`).
- Detail sheet (large detent): photo, name, rating, price, distance, open now, address, `Directions`, `Open in Maps`, `Reviews` section (fetched lazily), `Log this meal`.
- Favourite limit gate at the eleventh favourite (`discover.favourite.limit.*`).
- Empty: `discover.empty.*` with `Search again`.

## 5. Track

- Title `Meal Tracker`. CapacityRing on top (weekly state from `BudgetEngine`), tap → Budget setup.
- Quick meal log card: meal type chips (Breakfast, Lunch, Dinner, Snack; default from `MealDefaults.smartMealType`), place field id `meal_place_field` with suggestions, cost field id `meal_cost_field`, date picker (default now), notes field, CTA `Log this meal`. After logging: toast `Logged`, form resets, ring animates, achievement toast if unlocked.
- Impact line under the cost field from `BudgetEngine.mealImpact` (message verbatim).
- Recent meals list with filter chips (week, month, all). Free tier shows only the last 30 days and a `track.history.gate` UpsellRow at the end.

## 6. Budget setup (3 steps)

- Capacity selector (A$50 to A$500 in 10 steps), experience preference chips, celebrations toggle. Saves `weeklyBudget` and returns.

## 7. Profile

- Header card: initial disc, name, `FOOD EXPLORER` badge.
- Sections: preferences tiles (budget, distance, chains → Preferences), Lunch Pro card (free: title, body, CTA `Try free for 7 days` → Paywall; active: plan and renewal, `Manage subscription`, `Restore purchases`), sign-in row (Apple, Google) when signed out, settings list (Edit preferences, Notifications, Privacy, Help & support), `Export my data`, `Delete account` (confirm dialog, calls `AuthRepository.deleteAccount`).

## 8. Preferences

- One Save affordance (top-right on iOS, bottom bar on Android). Sections: budget (price chips, weekly slider), location (distance slider), restaurant (chains toggle), dietary (chip grid), allergens.

## 9. Paywall

- Two plan cards (yearly preselected with trial line and `BEST VALUE`; monthly), six benefit rows, CTA id `paywall_cta` (`Start free trial` when trial available else `Subscribe`), legal sentence with the store name substituted, `Restore purchases`, `Terms of Use`, `Privacy Policy`. Success state `You're on Lunch Pro` with `Done`.

## 10. Group lunch, host

- Create: name field id `group_name_field`, date and time picker (default next weekday 12:30), area (current location, radius chips 1, 2, 5 km), CTA `Propose places` → calls `GroupRepository.create` then `propose`.
- Proposals: three ProposalCards id `proposal_card_{i}` with `Choose` id `proposal_card_{i}_choose`.
- Group detail: place and time, invite link text id `invite_link_text`, `Share invite` (system share sheet), guest list with RSVP status, reminder toggle, `Cancel lunch`.
- Gate: a free user tapping `Plan a group lunch` sees `gate.host.*` → Paywall; a signed-out Pro user sees the sign-in sheet first.

## 11. Invitation (guest)

- InvitationCard: `{host} invited you to lunch`, place, address, time, `{n} going`, avatars/initials, `Accept` / `Decline`. Signed-out guests are asked for a name (`invite.name_prompt`) before accepting; no account required.
- After accepting: `You're in`, `Add to calendar`, `Directions`. After declining: `Maybe next time`.
- Guests who have accepted two invitations see the soft `gate.guest_offer.*` card once.

## Test ids summary

`onboarding_name_field`, `hero_hungry_button`, `recommendation_card`, `craving_field`, `ai_result_{i}`,
`restaurant_card_{i}`, `favourite_button_{i}`, `favourite_button_{i}_selected`, `meal_place_field`,
`meal_cost_field`, `paywall_cta`, `group_name_field`, `proposal_card_{i}`, `proposal_card_{i}_choose`,
`invite_link_text`.
