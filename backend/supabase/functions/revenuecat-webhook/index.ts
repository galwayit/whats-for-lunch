import { bearerToken } from "../_shared/auth.ts";
import { reconcileBilling } from "../_shared/billing.ts";
import {
  ApiError,
  badRequest,
  ErrorCode,
  handle,
  json,
  readJsonObject,
} from "../_shared/errors.ts";
import {
  affectedAccountIds,
  type RevenueCatEnvelope,
  secretsMatch,
} from "../_shared/revenuecat.ts";
import { requireEnv, serviceClient } from "../_shared/supabase.ts";

Deno.serve(handle(["POST"], async (req) => {
  if (!secretsMatch(bearerToken(req) ?? "", requireEnv("REVENUECAT_WEBHOOK_SECRET"))) {
    throw new ApiError(ErrorCode.UNAUTHORIZED, "Invalid webhook secret");
  }
  const body = await readJsonObject(req);
  if (typeof body.event !== "object" || body.event === null) throw badRequest("event is required");
  const { event } = body as unknown as RevenueCatEnvelope;
  if (typeof event.type !== "string" || typeof event.id !== "string" || event.id.length > 200) {
    throw badRequest("event id and type are required");
  }
  if (event.type === "TEST") return json({ ok: true, updated: 0 });
  const client = serviceClient();
  const { data, error } = await client.from("revenuecat_events").select("event_id")
    .eq("event_id", event.id).maybeSingle();
  if (error) throw new Error(`database: ${error.message}`);
  if (data) return json({ ok: true, duplicate: true });
  // Reconcile both sides of a transfer. Never copy a source row or infer permanent access.
  const ids = affectedAccountIds(event);
  if (ids.length > 20) throw badRequest("Too many customer aliases");
  await reconcileBilling(client, ids, event.id);
  return json({ ok: true, updated: ids.length });
}));
