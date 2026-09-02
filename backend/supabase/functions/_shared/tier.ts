/**
 * @file tier.ts
 * @description Entitlement lookup: `pro` when the row says is_pro and has not
 *   expired, otherwise `free`. Mirrors the SQL `current_tier()` function.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { ApiError, ErrorCode } from "./errors.ts";
import type { EntitlementRow, Tier } from "./types.ts";

export function tierFromRow(
  row: Pick<EntitlementRow, "is_pro" | "expires_at"> | null,
  nowMs: number,
): Tier {
  if (!row || !row.is_pro) return "free";
  if (row.expires_at !== null && new Date(row.expires_at).getTime() <= nowMs) return "free";
  return "pro";
}

export async function tierFor(client: SupabaseClient, appUserId: string): Promise<Tier> {
  const { data, error } = await client
    .from("entitlements")
    .select("is_pro, expires_at")
    .eq("app_user_id", appUserId)
    .maybeSingle();
  if (error) throw new Error(`database: ${error.message}`);
  return tierFromRow(data, Date.now());
}

/** 403 HOST_REQUIRES_PRO unless the id is Pro. */
export async function requirePro(client: SupabaseClient, appUserId: string): Promise<void> {
  if ((await tierFor(client, appUserId)) !== "pro") {
    throw new ApiError(ErrorCode.HOST_REQUIRES_PRO, "Hosting a group needs Lunch Pro");
  }
}
