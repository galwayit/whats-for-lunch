import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { ApiError, ErrorCode } from "./errors.ts";

/** Global upstream caps cannot be bypassed with a forged installation ID or IP.
 * Set provider-side quotas too; these are request ceilings, not dollar budgets.
 */
export async function reserveUpstream(
  client: SupabaseClient,
  provider: "places" | "photos" | "gemini",
): Promise<void> {
  const defaults = { places: 1000, photos: 3000, gemini: 500 };
  const configured = Deno.env.get(`${provider.toUpperCase()}_DAILY_REQUEST_LIMIT`);
  const limit = configured ? Number(configured) : defaults[provider];
  if (!Number.isInteger(limit) || limit < 1 || limit > 1_000_000) {
    throw new Error("Invalid upstream budget configuration");
  }
  const { data, error } = await client.rpc("reserve_upstream_request", {
    p_provider: provider,
    p_limit: limit,
  });
  if (error) throw new Error("Unable to reserve upstream budget");
  if (data !== true) {
    throw new ApiError(
      ErrorCode.RATE_LIMITED,
      "This service has reached its daily capacity. Please try again after 00:00 UTC.",
    );
  }
}
