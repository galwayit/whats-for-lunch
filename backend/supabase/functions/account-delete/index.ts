/**
 * @file account-delete/index.ts
 * @description POST /account-delete (auth): removes the user's groups (rsvps
 *   cascade), own rsvps, device tokens, entitlements, usage and AI logs, then
 *   deletes the auth user through the admin API.
 */

import { requireUser } from "../_shared/auth.ts";
import { appleConfig, revokeAppleAuthorization } from "../_shared/apple.ts";
import { handle, json, readJsonObject } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { requireString } from "../_shared/validate.ts";

Deno.serve(handle(["POST"], async (req) => {
  const user = await requireUser(req);
  const client = serviceClient();
  const id = user.id;

  if (user.appleSubject) {
    const { data: receipt, error } = await client.from("account_deletions").select("user_id").eq(
      "user_id",
      id,
    ).maybeSingle();
    if (error) throw new Error("Unable to check deletion progress");
    if (!receipt) {
      const body = await readJsonObject(req);
      const code = requireString(body, "appleAuthorizationCode", 4096);
      await revokeAppleAuthorization(code, user.appleSubject, appleConfig());
      // Retain only completion, so retries do not reuse Apple's one-time code.
      const { error } = await client.from("account_deletions").upsert({ user_id: id });
      if (error) throw new Error("Unable to save deletion progress");
    }
  }

  // Sequential on purpose: groups cascade to rsvps, and each step must succeed
  // before the auth user disappears.
  const deletions = [
    () => client.from("rsvps").delete().eq("guest_user_id", id),
    () => client.from("groups").delete().eq("host_id", id),
    () => client.from("device_tokens").delete().or(`user_id.eq.${id},app_user_id.eq.${id}`),
    () => client.from("entitlements").delete().eq("app_user_id", id),
    () => client.from("usage").delete().eq("app_user_id", id),
    () => client.from("ai_requests").delete().eq("app_user_id", id),
  ];
  for (const run of deletions) {
    const { error } = await run();
    if (error) throw new Error(`database: ${error.message}`);
  }

  const { error } = await client.auth.admin.deleteUser(id);
  if (error) throw new Error(`auth: ${error.message}`);
  return json({ deleted: true });
}));
