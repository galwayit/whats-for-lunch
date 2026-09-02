/**
 * @file account-delete/index.ts
 * @description POST /account-delete (auth): removes the user's groups (rsvps
 *   cascade), own rsvps, device tokens, entitlements, usage and AI logs, then
 *   deletes the auth user through the admin API.
 */

import { requireUser } from "../_shared/auth.ts";
import { handle, json } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";

Deno.serve(handle(["POST"], async (req) => {
  const user = await requireUser(req);
  const client = serviceClient();
  const id = user.id;

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
