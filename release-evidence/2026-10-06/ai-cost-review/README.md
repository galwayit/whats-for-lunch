# AI cost and product value assessment — 6 October 2026

My recommendation is to keep GPT-6 Luna as the primary model, use AI for interpreting requests and explaining meaningful compromises, and spend the next development effort on better preference data and group planning. Ordinary restaurant filtering, budget arithmetic and invitation management should remain deterministic. Increasing model size or calling AI more often will not, by itself, make Lunch Pro worth paying for.

This is a forecast based on the current code, a read-only check of deployed Supabase settings, official prices and locally constructed fictional prompts. No new model requests were made. No production settings or app code were changed. Amounts are **USD**, before taxes and currency conversion.

**What the app currently spends AI on**

There are two model-calling backend handlers, with three distinct user actions. Each successful action normally makes one model request, returning up to three choices where applicable. The router can make a second request to the backup; it does not call a model once per restaurant or guest.

| User action | Current implementation | AI needed to work well? | Planning model cost per 1,000 actions |
|---|---|---|---:|
| Tap “Ask AI”, or submit a craving from Home | Rank up to 20 candidates and explain up to three picks | Useful for natural language and soft preferences; ordinary price/distance sorting needs no model | $1.00 |
| Tap “Why this?” on a Home pick | Calls the same AI endpoint with one cached candidate, if available | Basic budget, distance, rating and opening-status reasons should be generated locally; reserve AI for a follow-up question | $0.44 |
| Host opens group place suggestions, after consent | Fetch fresh nearby restaurants, then generate three proposals | Useful for group compromise, but the current prompt only includes host preferences, group name/time and the host’s past places | $0.78 |
| Reopen group suggestions or press retry | Can generate again; loading guards only stop overlapping requests | Reuse the existing result until inputs change or the host explicitly requests alternatives | Another billable action if a model is called |
| Browse Home/Discover, sort/filter, favourites | Places lookups and local recommendation rules | No model needed | $0 AI |
| Create invitations, RSVP, propose another place/time, accept a guest suggestion | Database, permissions and deterministic workflow | No model needed | $0 AI |
| Log meals, show spending/budgets, split bills, export PDF, authentication and subscription checks | Local calculations and ordinary service integrations | No model needed | $0 AI |
| Read saved AI history or submit feedback | Local reads/writes; history may need restaurant detail refreshes | No new generation needed | $0 AI |

“$0 AI” does not mean the operation has no backend, Places, storage or payment cost. “Why this?” and a prefilled craving can trigger generation on entering the screen, after consent. Merely opening the general AI screen without a pick or craving reads history instead.

**How the estimate was calculated**

The deployed primary is `gpt-6-luna` for both Free and Pro. Standard prices are $0.10 per million uncached input tokens, $0.01 for cached input, $0.125 for cache writes and $0.50 for output. Cache writes replace the ordinary input charge for those tokens; they are not an additional charge. The forecast conservatively uses the cache-write rate for all input, with no cache-read savings. [OpenAI API pricing](https://developers.openai.com/api/docs/pricing), [prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching).

The local script invokes the actual prompt builders with fictional data. It measured these character counts, including the JSON response schema:

| Operation | Prompt + schema characters | Rough input token range | Input/output tokens used in forecast |
|---|---:|---:|---:|
| Why this, one candidate | 3,392 | 848–1,131 | 1,500 / 500 |
| Ask AI, 20 candidates | 9,022 | 2,256–3,008 | 4,000 / 1,000 |
| Group suggestions, 20 candidates | 6,764 | 1,691–2,255 | 3,000 / 800 |

The token ranges use characters divided by 4 to characters divided by 3; they are **not exact tokenisation**. Forecast input budgets add headroom for framing, longer names and context. Output budgets are assumptions, including hidden reasoning, rather than observed averages. The $1 per 1,000 full requests follows `(4,000 × $0.125 + 1,000 × $0.50) / 1,000,000 × 1,000`.

All deployed profiles have a 2,048 output-token limit. With 4,000 input tokens and the entire output allowance used, GPT-6 Luna costs about **$1.52 per 1,000 requests**. This is a scenario, not a hard maximum: larger inputs and backup attempts increase cost. The request body is bounded at 64 KiB, but some nested context strings and candidate fields lack tighter application-specific limits.

The adapter does not set OpenAI reasoning effort, so Luna uses its documented default, `medium`. Reasoning consumes output budget and is billed. A response that exhausts that allowance may still cost money even when the user receives no usable answer. Evaluate `low` or `none` for this bounded ranking task before changing the default; test quality and latency together. [Luna model documentation](https://developers.openai.com/api/docs/models/gpt-6-luna), [reasoning token billing and limits](https://developers.openai.com/api/docs/guides/reasoning).

**Cost by usage and provider**

For a 30-day month using the full “Ask AI” planning allowance:

| Usage | Calls/month | Primary AI forecast |
|---|---:|---:|
| One call each day | 30 | $0.03/user |
| Three calls each day | 90 | $0.09/user |
| Ten calls each day, the Pro ceiling | 300 | $0.30/user |
| 1,000 users each making one call/day | 30,000 | $30 total |

These are usage scenarios, not a prediction of customer activity, and exclude backup calls and all non-model costs. The 30,000-call scenario requires higher capacity than the current OpenAI daily limit.

At the same 4,000 input / 1,000 output assumption:

| Provider/model | Status in Lunch | Cost per 1,000 requests |
|---|---|---:|
| OpenAI GPT-6 Luna | Enabled primary | $0.90 at base input rate; $1.00 using conservative cache-write pricing |
| Google Gemini 3.8 Flash | Configured backup | $6.75 through 31 December 2026 |
| Google Gemini 3.8 Flash | Same model after announced price change | $13.50 from 1 January 2027 |
| Claude Haiku 4.5 | Inactive profile, not selected for routing | $9.00 at ordinary input/output rates |

Sources: [Google introductory and scheduled prices](https://ai.google.dev/gemini-api/docs/generate-content/latest-model), [Claude Haiku 4.5 pricing](https://platform.claude.com/docs/en/models/haiku-4-5/overview). Equal token counts make this a price comparison, not a claim about equal quality or actual provider tokenisation.

If every logical request incurs the assumed primary cost and 5% also incur a full Google backup request, the forecast rises from $1.00 to **$1.34 per 1,000 actions**. Timeouts can still be billed by the original provider. Refunding the user’s daily allowance does not refund the provider charge.

The latest saved live probe, at 10:31 Melbourne time on 6 October, showed OpenAI responding and Google returning HTTP 402. The Google backup therefore needs a successful billing/configuration retest before it can be counted on. That probe used only 354 total OpenAI tokens and is too small to represent the normal 20-candidate workflow.

**Places is the larger variable expense**

The app requests ratings, price level and opening hours, selecting Google’s Nearby Search Enterprise SKU. Place details include reviews, selecting Enterprise + Atmosphere. The current backend performs a fresh search for each group generation. A normal full Ask AI can also fetch nearby places; the iOS request without supplied candidates explicitly does so. [Field-based SKU rules](https://developers.google.com/maps/billing-and-pricing/sku-details).

At the first paid global tier, after the relevant monthly free allowance:

| External operation | Cost per 1,000 events |
|---|---:|
| Nearby Search Enterprise | $35 |
| Place Details Enterprise + Atmosphere | $25 |
| Place photo fetch | $7 |
| Full Ask AI planning allowance | $1 |

The three Places SKUs each have 1,000 free monthly events at the billing-account level; paid volume tiers and account contracts can change the total. [Google Maps Platform pricing](https://developers.google.com/maps/billing-and-pricing/pricing).

For scale: 300 actions with a new nearby search each time create about **$10.50 marginal Places cost plus $0.30 AI cost**, excluding photos/details. This is not a standalone user’s bill: the free allowance is shared across the account. At 30,000 nearby calls/month, the simple first-tier account example is `(30,000 − 1,000) × $0.035 = $1,015`, versus $30 in the primary AI forecast. A low subscription price can therefore be undermined by unnecessary restaurant searches even when model spend is tiny.

Deduplicate repeated loads, reuse the already displayed candidate set where suitable, and fetch details/photos only when needed. Do not remove useful rating/price data solely to reduce token usage; the quality of the underlying restaurant data matters more than prompt length here.

**Where AI can make Pro valuable**

1. **Interpret a specific meal request.** Turn “somewhere quiet, vegetarian, under my budget and a short walk away” into structured preferences, retrieve matching current data, then explain the best few choices. Deterministic checks should enforce known budget/distance/availability constraints; the model handles language and softer trade-offs.
2. **Help a host reach a workable group decision.** Incorporate consenting guests’ needs, the actual group budget, location/time constraints and past choices. Compute hard conflicts first, then let AI explain the best compromise. The current implementation omits guest preferences and the invitation’s budget/payment fields from its prompt. Payment allocation itself remains deterministic.
3. **Personalise using meaningful feedback.** Use selected/rejected places, cuisine preferences, ratings and repeated meals. Current solo context mostly provides stated preferences and meal-type/cost/time summaries; saving feedback alone does not make the next request learn taste. A larger model cannot recover data it was never given.
4. **Consider a weekly plan or spending explanation later.** Calculate spending and remaining budget in code, then generate a short plan on demand from those verified numbers. Validate demand before building a general chatbot or photo feature. The archived Flutter photo-analysis code is not a current native model-calling feature.

The current Places mapping supplies no verified dietary/allergen data and no actual average meal prices. AI should describe missing information, not infer that a restaurant is allergy-safe or promise an exact meal price. Precise nutrition, payments, booking availability and budget totals require suitable data or deterministic integrations.

I would replace “investment opportunity” language and uncalibrated confidence percentages with short, specific explanations of why a place meets the request. The strongest paid proposition is **fewer disappointing picks and less group coordination**, rather than access to a bigger model or a larger quota.

**Priorities before scaling**

1. **Measure cost per operation.** Save input, output, cached-input, cache-write and reasoning tokens, model/provider, feature, attempt, latency, outcome and the applicable price version. Today the backend keeps only total tokens, so exact dollar cost cannot be reconstructed. Incomplete provider responses throw before usage extraction and may be logged as zero despite billable work. Mark unknown usage explicitly and reconcile against provider billing; avoid logging personal prompts.
2. **Stop accidental regeneration.** Preserve proposals until their inputs change; make regeneration explicit. Keep basic “Why this?” local. Use request IDs to deduplicate repeated submissions. Failed user requests may consume paid upstream work even when the daily user allowance is restored.
3. **Make reasoning and cost policies configurable.** Provider/model/output cap are already server parameters. Add supported reasoning settings, feature-specific token budgets, dollar alerts and a hard service spend limit. User quotas are currently constants in code.
4. **Repair backup reliability and plan capacity.** Live settings allow 200 OpenAI attempts/day, 400 Google attempts/day, and 500 total provider attempts/day. The global override is absent, so the code default applies. Free users have one successful request/day; Pro has ten, shared with group suggestions, resetting at UTC midnight. Twenty Pro users using all ten requests consume the primary provider’s entire allowance. Raise capacity only alongside monitoring and validated backup service.
5. **Evaluate outcomes, not model labels.** Compare the local ranking baseline, Luna at low/none reasoning, and the backup on fixed meal/group scenarios. Measure valid results, constraint compliance, user selections, latency and total cost including Places. Keep a manual/deterministic place-selection route available when AI is down.

**Evidence and reproducibility**

The live read retained only four older failed Gemini requests over 30 days, with zero recorded tokens; no representative successful current-model cohort remained after test fixture cleanup. Consequently this report does not claim actual monthly spending or production success rates.

- [Read-only live snapshot](/Users/rayding/galway/what_we_have_for_lunch/release-evidence/2026-10-06/ai-cost-review/live-snapshot.json)
- [Reproducible local calculation](/Users/rayding/galway/what_we_have_for_lunch/release-evidence/2026-10-06/ai-cost-review/estimate.ts) and [calculated results](/Users/rayding/galway/what_we_have_for_lunch/release-evidence/2026-10-06/ai-cost-review/cost-estimates.json)
- [Why this and Ask AI triggers](/Users/rayding/galway/what_we_have_for_lunch/iosApp/LunchApp/Features/AI/AIRecommendationsViewModel.swift:46)
- [Group generation inputs and Places call](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/groups-propose/index.ts:44)
- [Local scoring/filtering](/Users/rayding/galway/what_we_have_for_lunch/shared/src/commonMain/kotlin/au/iapp/lunch/core/engine/RecommendationEngineImpl.kt:24) and [current personalisation context](/Users/rayding/galway/what_we_have_for_lunch/shared/src/commonMain/kotlin/au/iapp/lunch/core/service/AiContextBuilder.kt:46)
- [Provider usage handling](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/_shared/ai-providers.ts:148), [request quotas](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/_shared/ai-access.ts:6) and [global cap](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/_shared/ai-router.ts:114)
- [Places field masks and missing dietary data](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/_shared/places.ts:15)

Re-run from the repository root with `deno run --no-config release-evidence/2026-10-06/ai-cost-review/estimate.ts`. It calls only pure local prompt builders and prints JSON; it does not contact any provider. Review current prices and actual token measurements before reusing this forecast at a later date.
