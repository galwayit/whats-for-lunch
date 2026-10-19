# RevenueCat v2 subscription verification

The backend uses RevenueCat REST API **v2**. Mobile SDK configuration and the existing
webhook payload format do not change. Webhooks trigger a fresh read; their event names
never grant Pro access by themselves. Deploy the v2 reader with the pending billing
database migration and affected functions, as described in [README.md](README.md).

## Server configuration

Store these values in Supabase project `lunch` (`cswdcbmywzzisovsgwac`) → Edge Functions
→ Secrets. Keep the secret key out of mobile apps, Git, screenshots and chat.

| Name | Value |
| --- | --- |
| `REVENUECAT_SECRET_API_KEY` | A RevenueCat **V2** secret key for What's for lunch |
| `REVENUECAT_PROJECT_ID` | `proj66f64377` (the API v2 ID shown in RevenueCat Project settings, including the `proj` prefix) |
| `REVENUECAT_PRO_PRODUCT_IDS` | Comma-separated App Store identifiers of the approved monthly/yearly subscriptions |
| `REVENUECAT_ALLOW_APPLE_SANDBOX` | `true` for controlled Apple sandbox/TestFlight acceptance; otherwise `false` |
| `REVENUECAT_WEBHOOK_SECRET` | Existing shared bearer secret; unchanged by the API migration |

The product allowlist still contains **store identifiers**, such as
`au.iapp.lunch.pro.monthly`, not RevenueCat's internal `prod…` IDs. Use the products
actually configured in App Store Connect and attached to the `pro` entitlement.
An absent or empty allowlist approves no products: successful RevenueCat verification
still permits the free tier, while all paid access is denied. RevenueCat authentication
and upstream failures remain retryable errors and never overwrite the last verified snapshot.

## Minimum key permissions

In RevenueCat → What's for lunch → API keys → New secret API key:

1. Name: **Lunch Supabase backend - v2**. API version: **V2**.
2. Customer information permissions → **Subscriptions: Read only**
   (`customer_information:subscriptions:read`).
3. Project configuration permissions → **Products: Read only**
   (`project_configuration:products:read`).
4. Leave all other resources at **No access**, and all actions disabled. No customer
   profile, purchase, chart, API-key administration, refund, entitlement-grant or write
   permission is required.

These scopes permit only the reads used by the adapter:

| Endpoint under `/v2/projects/{project_id}` | Scope |
| --- | --- |
| `/customers/{customer_id}/subscriptions` | Subscriptions read |
| `/subscriptions/{subscription_id}/entitlements` (pagination if necessary) | Subscriptions read |
| `/products/{product_id}` | Products read |

## Access decisions and failure behaviour

- Require RevenueCat's `gives_access: true`, Apple `app_store`, a recognised environment,
  an active entitlement with lookup key exactly `pro` in this project, and a matching
  recurring product from the store-ID allowlist. Test Store and promotional access
  never qualify, even when Apple sandbox is enabled.
- Refunds/revocations are reflected in `gives_access`; an upcoming expiry or renewal
  cannot override a denied access decision. Cancellation of auto-renewal alone does
  not remove current paid access.
- Normal access ends at `current_period_ends_at`. Future `pending_changes` and the
  later `ends_at` do not extend the current product into an upcoming, different plan.
- RevenueCat v2 reports grace access without a separate grace-end timestamp. A valid
  `in_grace_period` subscription receives a **60-second verification lease**, never
  permanent access. Every protected request verifies again. This lease is not a
  claimed Apple billing-period end date; live grace-period acceptance remains required.
- Read every subscription and relevant entitlement page, with a limit of 10 pages per
  list and 10 seconds for the whole reconciliation. Partial reads, malformed responses,
  invalid pagination, 401/403, 429, network failures and provider errors throw before
  any entitlement snapshot is written. No fallback to API v1 or broad credentials.
- Requests are GET-only; redirects are refused. Pagination is pinned to the original
  RevenueCat project/resource path, with cursor-only reconstruction and the original
  environment filter. Product reads are deduplicated within a reconciliation.
- The existing monotonic database snapshot and webhook-idempotency transaction remains
  unchanged. Both sides of transfers are queried; old owners do not inherit access.

## Acceptance

Run `make check test` in `backend/`. Fixtures exercise v2 contracts and failures without
network requests or real customer data. This is not proof of live credential access.

After saving the v2 key and configuration, verify a controlled customer's v2 subscription
read and product read, then purchase/restore, renewal, expiry, refund, grace period and
transfer on the deployed backend. A valid empty subscription response verifies only the
subscription-read request, not product permission or paid access. The currently installed
Debug build uses a RevenueCat Test Store key; Apple sandbox testing needs the real Apple
`appl_…` SDK key and App Store product/key configuration before rebuilding that app.

Official contracts checked on 6 October 2026:
[API v2](https://www.revenuecat.com/docs/api-v2),
[customer subscription reads](https://www.revenuecat.com/docs/api-v2/customer/resources),
[subscription model](https://www.revenuecat.com/docs/api-v2/subscription-data-model),
[subscription entitlements](https://www.revenuecat.com/docs/api-v2/subscription),
[products](https://www.revenuecat.com/docs/api-v2/product).
