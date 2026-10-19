import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { ApiError, ErrorCode } from "./errors.ts";
import { nextLocalMidnightEpochSeconds } from "./quota.ts";
import type { Tier } from "./types.ts";

export const AI_DAILY_LIMITS = { free: 1, pro: 10 } as const;

export function requireAiConsent(body: Record<string, unknown>, consentVersion: string): void {
  if (body.aiConsentVersion !== consentVersion) {
    throw new ApiError(
      ErrorCode.AI_CONSENT_REQUIRED,
      "Review the current AI providers and allow data sharing before continuing",
    );
  }
}
export async function reserveAi(
  client: SupabaseClient,
  userId: string,
  tier: Tier,
): Promise<string> {
  const requestId = crypto.randomUUID();
  const { data, error } = await client.rpc("reserve_ai_request", {
    p_app_user_id: userId,
    p_request_id: requestId,
    p_limit: AI_DAILY_LIMITS[tier],
  });
  if (error) throw new Error(`database: ${error.message}`);
  if (data !== true) {
    throw new ApiError(ErrorCode.AI_DAILY_LIMIT, "Daily AI limit reached", {
      resetsAt: nextLocalMidnightEpochSeconds(new Date(), "UTC"),
    });
  }
  return requestId;
}
export async function refundAi(
  client: SupabaseClient,
  userId: string,
  requestId: string,
): Promise<void> {
  const { error } = await client.rpc("refund_ai_request", {
    p_app_user_id: userId,
    p_request_id: requestId,
  });
  if (error) {
    console.error("AI quota refund failed; reservation can be retried by request ID", requestId);
  }
}
