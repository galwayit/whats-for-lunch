/**
 * @file revenuecat.ts
 * @description Pure mapping from a RevenueCat webhook event to the
 *   `entitlements` rows to upsert. The handler only does auth + persistence.
 *
 *   Rules (API.md): INITIAL_PURCHASE/RENEWAL/etc. mark the user Pro until
 *   `expiration_at_ms`; CANCELLATION, EXPIRATION and BILLING_ISSUE keep the
 *   user Pro while `expires_at` is still in the future; TRANSFER moves the
 *   entitlement from the old app user ids to the new ones.
 */

export interface RevenueCatEvent {
  type: string;
  app_user_id?: string;
  original_app_user_id?: string;
  entitlement_ids?: string[] | null;
  product_id?: string | null;
  expiration_at_ms?: number | null;
  transferred_from?: string[] | null;
  transferred_to?: string[] | null;
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
  source: "revenuecat";
}

/** Event types that grant or refresh access. */
const GRANTING = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "NON_RENEWING_PURCHASE",
  "UNCANCELLATION",
  "PRODUCT_CHANGE",
  "SUBSCRIPTION_EXTENDED",
  "TEMPORARY_ENTITLEMENT_GRANT",
]);

/** Event types after which access continues only until `expires_at`. */
const WINDING_DOWN = new Set([
  "CANCELLATION",
  "EXPIRATION",
  "BILLING_ISSUE",
  "SUBSCRIPTION_PAUSED",
]);

function expiresAtIso(event: RevenueCatEvent): string | null {
  const ms = event.expiration_at_ms;
  return typeof ms === "number" && Number.isFinite(ms) ? new Date(ms).toISOString() : null;
}

function stillActive(expiresAt: string | null, nowMs: number): boolean {
  return expiresAt === null || new Date(expiresAt).getTime() > nowMs;
}

/**
 * Computes the rows to upsert for one event. Returns an empty array for
 * events that do not change entitlements (TEST, unknown types, missing ids).
 * @param existingFrom the current row of the first `transferred_from` id, so
 *   a TRANSFER can carry `expires_at`/`product_id` across (RevenueCat does not
 *   include them on TRANSFER events).
 */
export function entitlementRowsFromEvent(
  envelope: RevenueCatEnvelope,
  nowMs: number,
  existingFrom: { product_id: string | null; expires_at: string | null } | null = null,
): EntitlementUpsert[] {
  const event = envelope.event;
  if (!event || typeof event.type !== "string") return [];

  if (event.type === "TRANSFER") {
    const from = (event.transferred_from ?? []).filter(isNonEmptyString);
    const to = (event.transferred_to ?? []).filter(isNonEmptyString);
    const carried = existingFrom ?? { product_id: event.product_id ?? null, expires_at: null };
    const rows: EntitlementUpsert[] = from.map((id) => ({
      app_user_id: id,
      is_pro: false,
      product_id: carried.product_id,
      expires_at: carried.expires_at,
      source: "revenuecat",
    }));
    for (const id of to) {
      rows.push({
        app_user_id: id,
        is_pro: stillActive(carried.expires_at, nowMs),
        product_id: carried.product_id,
        expires_at: carried.expires_at,
        source: "revenuecat",
      });
    }
    return rows;
  }

  const appUserId = event.app_user_id;
  if (!isNonEmptyString(appUserId)) return [];
  const expiresAt = expiresAtIso(event);
  const hasEntitlement = (event.entitlement_ids ?? []).length > 0;

  if (GRANTING.has(event.type)) {
    return [{
      app_user_id: appUserId,
      is_pro: hasEntitlement && stillActive(expiresAt, nowMs),
      product_id: event.product_id ?? null,
      expires_at: expiresAt,
      source: "revenuecat",
    }];
  }
  if (WINDING_DOWN.has(event.type)) {
    // Access continues until the paid period ends; `current_tier()` re-checks
    // expires_at at read time so the row stays correct after this instant.
    return [{
      app_user_id: appUserId,
      is_pro: expiresAt !== null && stillActive(expiresAt, nowMs),
      product_id: event.product_id ?? null,
      expires_at: expiresAt,
      source: "revenuecat",
    }];
  }
  return [];
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.length > 0;
}

/** Constant-time comparison for the webhook bearer secret. */
export function secretsMatch(provided: string, expected: string): boolean {
  if (provided.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < provided.length; i++) {
    diff |= provided.charCodeAt(i) ^ expected.charCodeAt(i);
  }
  return diff === 0;
}
