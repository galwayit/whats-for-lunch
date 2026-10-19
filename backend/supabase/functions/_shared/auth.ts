/**
 * @file auth.ts
 * @description Resolves the caller: Supabase user id from the JWT (when the
 *   bearer token is a user session rather than the anon key) and the
 *   billing identity from that verified user. Client identifiers are never credentials.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { ApiError, badRequest, ErrorCode } from "./errors.ts";
import { serviceClient } from "./supabase.ts";

export interface AuthUser {
  id: string;
  email: string | null;
  /** Best display name from the provider metadata, else the email local part. */
  displayName: string;
  appleSubject?: string;
}

const APP_USER_ID_PATTERN = /^[A-Za-z0-9._:$@-]{1,128}$/;

export function bearerToken(req: Request): string | null {
  const header = req.headers.get("Authorization") ?? "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : null;
}

/**
 * Returns the signed-in user, or null when the bearer token is absent or is
 * the anon key (which has no `sub`, so getUser rejects it).
 */
export async function getUser(
  req: Request,
  client: SupabaseClient = serviceClient(),
): Promise<AuthUser | null> {
  const token = bearerToken(req);
  if (!token) return null;
  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user) return null;
  const meta = data.user.user_metadata ?? {};
  const email = data.user.email ?? null;
  const name = [meta.full_name, meta.name, meta.display_name, email?.split("@")[0]]
    .find((v) => typeof v === "string" && v.trim().length > 0);
  const appleIdentity = data.user.identities?.find((identity) => identity.provider === "apple");
  if (appleIdentity && typeof appleIdentity.identity_data?.sub !== "string") {
    throw new Error("Apple identity is missing its subject");
  }
  return {
    id: data.user.id,
    email,
    displayName: typeof name === "string" ? name.trim() : "Host",
    appleSubject: data.user.identities?.find((identity) => identity.provider === "apple")
      ?.identity_data?.sub,
  };
}

/** 401 SIGN_IN_REQUIRED when there is no user session. */
export async function requireUser(req: Request): Promise<AuthUser> {
  const user = await getUser(req);
  if (!user) throw new ApiError(ErrorCode.SIGN_IN_REQUIRED, "Sign in to continue");
  return user;
}

export function getAppUserId(req: Request): string | null {
  const raw = req.headers.get("x-app-user-id")?.trim();
  if (!raw) return null;
  if (!APP_USER_ID_PATTERN.test(raw)) throw badRequest("x-app-user-id is malformed");
  return raw;
}

/** Billing and quotas always belong to the verified Supabase account.
 * Guest browsing and invitation responses remain available without an account.
 * The legacy x-app-user-id header is deliberately ignored, including after a
 * failed RevenueCat identity switch; it can never select someone else's Pro tier.
 */
export function requireAppUserId(_req: Request, user: AuthUser | null): string {
  if (!user) throw new ApiError(ErrorCode.SIGN_IN_REQUIRED, "Sign in to use this feature");
  return user.id;
}

export function guestToken(req: Request): string | null {
  const raw = req.headers.get("x-guest-token")?.trim();
  return raw && /^[a-f0-9]{64}$/.test(raw) ? raw : null;
}
