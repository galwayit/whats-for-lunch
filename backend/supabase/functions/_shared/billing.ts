import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import {
  approvedProductIds,
  entitlementFromSubscriptions,
  type EntitlementUpsert,
} from "./revenuecat.ts";
import { revenueCatReader } from "./revenuecat-v2.ts";
import { requireEnv } from "./supabase.ts";

/** Fetch the current state, then persist with monotonic snapshot ordering in one transaction. */
export async function reconcileBilling(
  client: SupabaseClient,
  ids: string[],
  eventId: string | null = null,
): Promise<EntitlementUpsert[]> {
  const observedAt = new Date().toISOString(); // Before fetch: an older in-flight read cannot overwrite a newer one.
  const policy = {
    productIds: approvedProductIds(Deno.env.get("REVENUECAT_PRO_PRODUCT_IDS")),
    allowSandbox: Deno.env.get("REVENUECAT_ALLOW_APPLE_SANDBOX") === "true",
  };
  const readCustomer = revenueCatReader({
    apiKey: requireEnv("REVENUECAT_SECRET_API_KEY"),
    projectId: requireEnv("REVENUECAT_PROJECT_ID"),
    allowSandbox: policy.allowSandbox,
  });
  const rows = await Promise.all(ids.map(async (id) =>
    entitlementFromSubscriptions(
      id,
      await readCustomer(id),
      Date.now(),
      policy,
    )
  ));
  const { error } = await client.rpc("apply_revenuecat_snapshot", {
    p_rows: rows,
    p_observed_at: observedAt,
    p_event_id: eventId,
  });
  if (error) throw new Error(`database: ${error.message}`);
  return rows;
}
