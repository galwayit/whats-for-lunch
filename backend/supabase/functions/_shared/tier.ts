/**
 * @file tier.ts
 * @description Entitlement lookup: `pro` when the row says is_pro and has not
 *   expired, otherwise `free`. Mirrors the SQL `current_tier()` function.
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

export async function tierFor(client: SupabaseClient, appUserId: string): Promise<Tier> {
  // Verification on protected requests also closes the purchase-to-webhook delay.
  // A provider outage returns a retryable error, never a fabricated entitlement.
  await reconcileBilling(client, [appUserId]);
  // Read the accepted snapshot: a concurrent newer webhook may have superseded ours.
  const { data, error } = await client.from("entitlements").select("is_pro, expires_at").eq(
    "app_user_id",
    appUserId,
  ).maybeSingle();
  if (error) throw new Error("Unable to read verified entitlement");
  return tierFromRow(data, Date.now());
}

/** 403 HOST_REQUIRES_PRO unless the id is Pro. */
export async function requirePro(client: SupabaseClient, appUserId: string): Promise<void> {
  if ((await tierFor(client, appUserId)) !== "pro") {
    throw new ApiError(ErrorCode.HOST_REQUIRES_PRO, "Hosting a group needs Lunch Pro");
  }
}
