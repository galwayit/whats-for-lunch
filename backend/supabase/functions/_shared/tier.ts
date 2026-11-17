/**
 * @file tier.ts
 * @description Entitlement lookup: `pro` when the row says is_pro and has not
 *   expired, otherwise `free`. Mirrors the SQL `current_tier()` function.
 *   RevenueCat is asked only when the stored row cannot be trusted as it is.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { ApiError, ErrorCode } from "./errors.ts";
import { reconcileBilling } from "./billing.ts";
import type { EntitlementRow, Tier } from "./types.ts";

export function tierFromRow(
  row: Pick<EntitlementRow, "is_pro" | "expires_at"> | null,
  nowMs: number,
): Tier {
  if (!row || !row.is_pro) return "free";
  if (
    row.expires_at === null || !Number.isFinite(Date.parse(row.expires_at)) ||
    Date.parse(row.expires_at) <= nowMs
  ) return "free";
  return "pro";
}

/** How long a verified Pro row is trusted before RevenueCat is asked again. */
export const ENTITLEMENT_FRESH_MS = 5 * 60 * 1000;

async function storedEntitlement(
  client: SupabaseClient,
  appUserId: string,
): Promise<Pick<EntitlementRow, "is_pro" | "expires_at" | "reconciled_at"> | null> {
  const { data, error } = await client.from("entitlements")
    .select("is_pro, expires_at, reconciled_at").eq("app_user_id", appUserId).maybeSingle();
  if (error) throw new Error("Unable to read verified entitlement");
  return data;
}

export async function tierFor(
  client: SupabaseClient,
  appUserId: string,
  reconcile: typeof reconcileBilling = reconcileBilling,
): Promise<Tier> {
  const stored = await storedEntitlement(client, appUserId);
  const storedPro = tierFromRow(stored, Date.now()) === "pro";
  // The webhook rewrites this row on refund or expiry, so a recent Pro row needs no provider call.
  if (storedPro && Date.now() - Date.parse(stored?.reconciled_at ?? "") < ENTITLEMENT_FRESH_MS) {
    return "pro";
  }
  // A row that is not Pro is always verified: this closes the purchase-to-webhook delay.
  try {
    await reconcile(client, [appUserId]);
  } catch (error) {
    // A provider outage never fabricates or extends Pro. A stale Pro row gets a retryable
    // error; any other account is served as free, which can only under-grant.
    // Configuration and database faults are not outages and stay visible.
    const outage = error instanceof ApiError && error.code === ErrorCode.UPSTREAM_ERROR;
    if (storedPro || !outage) throw error;
    console.error("RevenueCat unavailable; serving the unverified account as free");
    return "free";
  }
  // Read the accepted snapshot: a concurrent newer webhook may have superseded ours.
  return tierFromRow(await storedEntitlement(client, appUserId), Date.now());
}

/** 403 HOST_REQUIRES_PRO unless the id is Pro. */
export async function requirePro(client: SupabaseClient, appUserId: string): Promise<void> {
  if ((await tierFor(client, appUserId)) !== "pro") {
    throw new ApiError(ErrorCode.HOST_REQUIRES_PRO, "Hosting a group needs Lunch Pro");
  }
}
