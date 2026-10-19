import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { ApiError, badRequest, ErrorCode } from "./errors.ts";

/** Conservative first-pass filter, supplemented by reports and human moderation.
 * Never send private invitations to an AI provider just to moderate them. */
export function checkSharedText(...values: (string | null | undefined)[]): void {
  const text = values.filter(Boolean).join(" ").normalize("NFKC").toLowerCase()
    .replace(/[\u200B-\u200D\uFEFF]/g, "");
  if (
    /\b(?:fuck(?:ing|er|ers)?|cunt(?:s)?|nigger(?:s)?|faggot(?:s)?|kill yourself|rape you)\b/u.test(
      text,
    )
  ) {
    throw badRequest("Please remove abusive or offensive language before sharing.");
  }
}

export function newGuestToken(): string {
  return Array.from(
    crypto.getRandomValues(new Uint8Array(32)),
    (b) => b.toString(16).padStart(2, "0"),
  ).join("");
}

export async function safetyContext(
  client: SupabaseClient,
  groupId: string,
  userId: string | null,
  token: string | null,
  includeCancelled = false,
): Promise<Set<string>> {
  const { data, error } = await client.rpc("group_safety_context", {
    p_group_id: groupId,
    p_user_id: userId,
    p_guest_token: token,
    p_include_cancelled: includeCancelled,
  });
  if (error) throw new Error("Unable to check group safety");
  if (!data || data.allowed !== true) {
    throw new ApiError(ErrorCode.NOT_FOUND, "This invitation is unavailable or blocked");
  }
  return new Set(Array.isArray(data.hiddenRsvpIds) ? data.hiddenRsvpIds : []);
}
