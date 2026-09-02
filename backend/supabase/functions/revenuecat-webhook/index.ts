/**
 * @file revenuecat-webhook/index.ts
 * @description POST /revenuecat-webhook: verifies the bearer secret and upserts
 *   `entitlements` rows computed by `_shared/revenuecat.ts`.
 */

import { bearerToken } from "../_shared/auth.ts";
import {
  ApiError,
  badRequest,
  ErrorCode,
  handle,
  json,
  readJsonObject,
} from "../_shared/errors.ts";
import {
  entitlementRowsFromEvent,
  type RevenueCatEnvelope,
  secretsMatch,
} from "../_shared/revenuecat.ts";
import { requireEnv, serviceClient } from "../_shared/supabase.ts";

Deno.serve(handle(["POST"], async (req) => {
  const provided = bearerToken(req) ?? "";
  if (!secretsMatch(provided, requireEnv("REVENUECAT_WEBHOOK_SECRET"))) {
    throw new ApiError(ErrorCode.UNAUTHORIZED, "Invalid webhook secret");
  }
  const body = await readJsonObject(req);
  if (typeof body.event !== "object" || body.event === null) throw badRequest("event is required");
  const envelope = body as unknown as RevenueCatEnvelope;

  const client = serviceClient();
  let existingFrom = null;
  const from = envelope.event.transferred_from?.[0];
  if (envelope.event.type === "TRANSFER" && typeof from === "string") {
    const { data } = await client.from("entitlements").select("product_id, expires_at").eq(
      "app_user_id",
      from,
    ).maybeSingle();
    existingFrom = data;
  }

  const rows = entitlementRowsFromEvent(envelope, Date.now(), existingFrom);
  if (rows.length > 0) {
    const stamped = rows.map((r) => ({ ...r, updated_at: new Date().toISOString() }));
    const { error } = await client.from("entitlements").upsert(stamped, {
      onConflict: "app_user_id",
    });
    if (error) throw new Error(`database: ${error.message}`);
  }
  return json({ ok: true, updated: rows.length, type: envelope.event.type });
}));
