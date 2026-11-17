import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { bearerToken, getUser } from "./auth.ts";
import { ApiError, ErrorCode } from "./errors.ts";

function dailyLimit(configured: string | undefined, fallback: number): number {
  const limit = configured ? Number(configured) : fallback;
  if (!Number.isInteger(limit) || limit < 1 || limit > 1_000_000) {
    throw new Error("Invalid upstream budget configuration");
  }
  return limit;
}

/** Global upstream caps cannot be bypassed with a forged installation ID or IP.
 * Set provider-side quotas too; these are request ceilings, not dollar budgets.
 */
export async function reserveUpstream(
  client: SupabaseClient,
  provider: "places" | "photos" | "gemini",
): Promise<void> {
  const defaults = { places: 1000, photos: 3000, gemini: 500 };
  const limit = dailyLimit(
    Deno.env.get(`${provider.toUpperCase()}_DAILY_REQUEST_LIMIT`),
    defaults[provider],
  );
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

/** The caller address reported by the Supabase gateway, or null when there is no usable one.
 * Cloudflare overwrites cf-connecting-ip, whereas a caller can put anything in front of
 * x-forwarded-for, so that header is only the fallback. An IPv6 address is cut to its /64,
 * because one subscriber controls that whole range.
 */
export function clientNetwork(req: Request): string | null {
  const reported = req.headers.get("cf-connecting-ip") ||
    req.headers.get("x-forwarded-for")?.split(",")[0];
  const ip = (reported ?? "").trim().toLowerCase().replace(/^::ffff:(?=\d+\.)/, "");
  if (/^(\d{1,3}\.){3}\d{1,3}$/.test(ip)) return ip;
  if (!/^[0-9a-f]{0,4}(:[0-9a-f]{0,4}){2,7}$/.test(ip)) return null;
  const [head, tail] = ip.split("::");
  const left = head ? head.split(":") : [];
  const right = tail ? tail.split(":") : [];
  const zeros = tail === undefined
    ? []
    : Array(Math.max(8 - left.length - right.length, 0)).fill("0");
  return [...left, ...zeros, ...right].slice(0, 4).map((group) => group.replace(/^0+(?=.)/, ""))
    .join(":");
}

/** Per-caller ceilings for the public Places functions. Call this before the global
 * reservation: one account or address is then refused without spending the budget that
 * every other user shares. Limits count upstream requests, like the global caps.
 * Only a salted hash of the caller is stored.
 */
export async function reserveCaller(
  client: SupabaseClient,
  req: Request,
  provider: "places" | "photos",
  requests = 1,
  env: (name: string) => string | undefined = (name) => Deno.env.get(name),
): Promise<void> {
  // Signed-out clients send the public key as the bearer; it needs no Auth round trip.
  const user = bearerToken(req) === env("SUPABASE_ANON_KEY") ? null : await getUser(req, client);
  const network = clientNetwork(req);
  // Without an address the request did not come through the gateway; the global cap still applies.
  if (!user && !network) return;
  const salt = env("SUPABASE_SERVICE_ROLE_KEY");
  if (!salt) throw new Error("Missing environment variable SUPABASE_SERVICE_ROLE_KEY");
  const defaults = { places: 200, photos: 1000 };
  const limit = dailyLimit(
    env(`${provider.toUpperCase()}_CALLER_DAILY_REQUEST_LIMIT`),
    defaults[provider],
  );
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`${salt}:${user ? `user:${user.id}` : `network:${network}`}`),
  );
  const { data, error } = await client.rpc("reserve_caller_request", {
    p_provider: provider,
    p_caller_hash: Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0"))
      .join(""),
    p_limit: limit,
    p_requests: requests,
  });
  if (error) throw new Error("Unable to reserve caller budget");
  if (data !== true) {
    throw new ApiError(
      ErrorCode.RATE_LIMITED,
      "You have reached today's limit for this service. Please try again after 00:00 UTC.",
    );
  }
}
