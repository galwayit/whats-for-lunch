/**
 * @file push-register/index.ts
 * @description POST /push-register: upsert a device token keyed by the app
 *   user id (and user id when signed in).
 */

import { getUser, requireAppUserId } from "../_shared/auth.ts";
import { handle, json, readJsonObject } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { requireEnum, requireString } from "../_shared/validate.ts";

const PLATFORMS = ["ios", "android"] as const;

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const token = requireString(body, "token", 4096);
  const platform = requireEnum(body, "platform", PLATFORMS);

  const user = await getUser(req);
  const appUserId = requireAppUserId(req, user);
  if (body.action === "unregister") {
    const { error } = await serviceClient().from("device_tokens").delete().eq("token", token).eq(
      "user_id",
      appUserId,
    );
    if (error) throw new Error(`database: ${error.message}`);
    return json({ ok: true });
  }
  const { error } = await serviceClient().from("device_tokens").upsert(
    {
      token,
      app_user_id: appUserId,
      user_id: user?.id ?? null,
      platform,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "token" },
  );
  if (error) throw new Error(`database: ${error.message}`);
  return json({ ok: true });
}));
