/**
 * @file supabase.ts
 * @description Supabase JS clients for edge functions. The service-role client
 *   bypasses RLS and is the only writer of every table; the user client
 *   forwards the caller's Authorization header so RLS applies.
 */

import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";

/** Reads a required environment variable; throws with the name only. */
export function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing environment variable ${name}`);
  return value;
}

/** Base URL of the deployed functions, used to build photo proxy URLs. */
export function functionsBaseUrl(): string {
  return `${requireEnv("SUPABASE_URL")}/functions/v1`;
}

let service: SupabaseClient | null = null;

/** Service-role client (cached per isolate). */
export function serviceClient(): SupabaseClient {
  if (!service) {
    service = createClient(requireEnv("SUPABASE_URL"), requireEnv("SUPABASE_SERVICE_ROLE_KEY"), {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return service;
}

/** Anon client carrying the request's Authorization header (RLS applies). */
export function userClient(req: Request): SupabaseClient {
  const authorization = req.headers.get("Authorization") ?? "";
  return createClient(requireEnv("SUPABASE_URL"), requireEnv("SUPABASE_ANON_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: authorization } },
  });
}

/** Throws with a stable message when a PostgREST call fails. */
export function unwrap<T>(result: { data: T | null; error: { message: string } | null }): T {
  if (result.error) throw new Error(`database: ${result.error.message}`);
  if (result.data === null) throw new Error("database: empty result");
  return result.data;
}
