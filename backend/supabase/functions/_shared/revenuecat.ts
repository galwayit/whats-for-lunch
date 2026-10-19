/** Current v2 subscription reconciliation. A webhook is a notification, never proof of access. */

export interface RevenueCatEvent {
  id?: string;
  type: string;
  app_user_id?: string;
  original_app_user_id?: string;
  aliases?: string[];
  transferred_from?: string[] | null;
  transferred_to?: string[] | null;
  environment?: string;
}
export interface RevenueCatEnvelope {
  api_version?: string;
  event: RevenueCatEvent;
}
export interface EntitlementUpsert {
  app_user_id: string;
  is_pro: boolean;
  product_id: string | null;
  expires_at: string | null;
  environment: "PRODUCTION" | "SANDBOX" | null;
  source: "revenuecat";
}
export interface RevenueCatPage<T> {
  object: "list";
  items: T[];
  next_page?: string | null;
}
export interface RevenueCatEntitlement {
  object: "entitlement";
  id: string;
  project_id: string;
  lookup_key: string;
  state: string;
}
export interface RevenueCatSubscription {
  object: "subscription";
  id: string;
  customer_id: string;
  product_id: string | null;
  current_period_ends_at: number | null;
  ends_at: number | null;
  gives_access: boolean;
  status: string;
  environment: string;
  store: string;
  entitlements: RevenueCatPage<RevenueCatEntitlement>;
}
export interface RevenueCatProduct {
  object: "product";
  id: string;
  store_identifier: string;
  type: string;
}
export interface RevenueCatSnapshot {
  projectId: string;
  subscriptions: RevenueCatSubscription[];
  products: RevenueCatProduct[];
}
export interface BillingPolicy {
  productIds: string[];
  allowSandbox: boolean;
}

/** An unconfigured product catalogue grants no paid access; it must not break free requests. */
export function approvedProductIds(value: string | undefined): string[] {
  return [...new Set((value ?? "").split(",").map((id) => id.trim()).filter(Boolean))];
}

/** Only authenticated account IDs are mirrored. Anonymous aliases never identify a backend user. */
export function affectedAccountIds(event: RevenueCatEvent): string[] {
  const ids = [
    event.app_user_id,
    event.original_app_user_id,
    ...(Array.isArray(event.aliases) ? event.aliases : []),
    ...(Array.isArray(event.transferred_from) ? event.transferred_from : []),
    ...(Array.isArray(event.transferred_to) ? event.transferred_to : []),
  ];
  return [
    ...new Set(ids.filter((id): id is string =>
      typeof id === "string" &&
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(id)
    )),
  ];
}

// v2 exposes the current access decision, but no separate grace-period end timestamp.
// A confirmed grace period receives a short lease, reverified on every protected request.
export const GRACE_VERIFICATION_TTL_MS = 60_000;

/** Only the exact Pro entitlement on an approved, access-granting Apple subscription qualifies. */
export function entitlementFromSubscriptions(
  appUserId: string,
  snapshot: RevenueCatSnapshot,
  nowMs: number,
  policy: BillingPolicy,
): EntitlementUpsert {
  const row: EntitlementUpsert = {
    app_user_id: appUserId,
    is_pro: false,
    product_id: null,
    expires_at: null,
    environment: null,
    source: "revenuecat",
  };
  let bestExpiry = 0;
  for (const subscription of snapshot.subscriptions) {
    if (
      subscription.gives_access !== true || subscription.store !== "app_store" ||
      !["production", "sandbox"].includes(subscription.environment) ||
      (subscription.environment === "sandbox" && !policy.allowSandbox) ||
      !subscription.entitlements.items.some((entitlement) =>
        entitlement.lookup_key === "pro" && entitlement.state === "active" &&
        entitlement.project_id === snapshot.projectId
      )
    ) continue;
    const product = snapshot.products.find((p) => p.id === subscription.product_id);
    if (
      !product || product.type !== "subscription" ||
      !policy.productIds.includes(product.store_identifier)
    ) continue;
    // Never infer access from status or auto-renewal alone: refunds/revocations set gives_access=false.
    // Do not use pending_changes (a future product) to extend the current product's entitlement.
    const end = subscription.current_period_ends_at;
    if (typeof end !== "number" || !Number.isSafeInteger(end) || end <= 0 || end > 8.64e15) {
      continue;
    }
    const until = subscription.status === "in_grace_period"
      ? Math.min(nowMs + GRACE_VERIFICATION_TTL_MS, end > nowMs ? end : Infinity)
      : end;
    if (until <= nowMs) continue;
    // Prefer a real production subscription when the same account also has sandbox purchases.
    if (row.environment === "PRODUCTION" && subscription.environment === "sandbox") continue;
    if (
      row.environment !== "SANDBOX" || subscription.environment !== "production"
    ) {
      if (until <= bestExpiry) continue;
    }
    bestExpiry = until;
    row.environment = subscription.environment === "sandbox" ? "SANDBOX" : "PRODUCTION";
    row.product_id = product.store_identifier;
    row.expires_at = new Date(until).toISOString();
    row.is_pro = true;
  }
  return row;
}

export function secretsMatch(provided: string, expected: string): boolean {
  if (provided.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < provided.length; i++) diff |= provided.charCodeAt(i) ^ expected.charCodeAt(i);
  return diff === 0;
}
