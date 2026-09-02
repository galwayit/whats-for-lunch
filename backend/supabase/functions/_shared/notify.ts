/**
 * @file notify.ts
 * @description Sends a data push to every device token of the given users and
 *   prunes tokens FCM reports as unregistered. Failures are logged, never
 *   thrown, because a push is best-effort next to the main write.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { parseServiceAccount, type PushMessage, sendPushToAll } from "./push.ts";

export async function notifyUsers(
  client: SupabaseClient,
  userIds: string[],
  message: PushMessage,
): Promise<number> {
  const ids = [...new Set(userIds)].filter((id) => id.length > 0);
  if (ids.length === 0) return 0;
  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!raw) {
    console.warn("FCM_SERVICE_ACCOUNT_JSON not set; skipping push");
    return 0;
  }
  const { data, error } = await client.from("device_tokens").select("token").in("user_id", ids);
  if (error) {
    console.warn(`device_tokens lookup failed: ${error.message}`);
    return 0;
  }
  const tokens = (data ?? []).map((row) => row.token as string);
  if (tokens.length === 0) return 0;

  const account = parseServiceAccount(raw);
  const { sent, staleTokens } = await sendPushToAll(account, tokens, message);
  if (staleTokens.length > 0) {
    await client.from("device_tokens").delete().in("token", staleTokens);
  }
  return sent;
}
