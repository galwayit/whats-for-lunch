import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import {
  activeProviders,
  type AiConfig,
  type AiProvider,
  aiUnavailable,
  providerKey,
  type ReadEnv,
  requireConfiguredRoute,
} from "./ai-config.ts";
import { callAiProvider, type JsonSchema, ProviderFailure } from "./ai-providers.ts";
import { ApiError, ErrorCode } from "./errors.ts";
import type { Tier } from "./types.ts";
export interface AiAttempt {
  provider: string;
  model: string;
  attempt: number;
  route_role: "primary" | "backup";
  tokens: number;
  latency_ms: number;
  ok: boolean;
  error: string | null;
}
export interface RouterDependencies {
  env: ReadEnv;
  reserve: (provider: AiProvider) => Promise<boolean>;
  record: (attempt: AiAttempt) => Promise<void>;
  fetchImpl?: typeof fetch;
}
/** One snapshot, at most two attempts. parse() is part of success, not post-processing. */
export async function routeAi<T>(
  config: AiConfig,
  tier: Tier,
  prompt: string,
  schema: JsonSchema,
  parse: (text: string) => T,
  deps: RouterDependencies,
): Promise<T> {
  requireConfiguredRoute(config, deps.env);
  const providers = activeProviders(config);
  let capacityOnly = true;
  for (let index = 0; index < providers.length; index++) {
    const provider = providers[index];
    const started = performance.now();
    const attempt: AiAttempt = {
      provider: provider.id,
      model: provider.models[tier],
      attempt: index + 1,
      route_role: index === 0 ? "primary" : "backup",
      tokens: 0,
      latency_ms: 0,
      ok: false,
      error: null,
    };
    const controller = new AbortController();
    let timer: ReturnType<typeof setTimeout> | undefined;
    let result: T | undefined;
    let fallback = true;
    try {
      const key = providerKey(provider, deps.env);
      if (!key) throw new ProviderFailure("not_configured");
      if (!await deps.reserve(provider)) throw new ProviderFailure("capacity");
      timer = setTimeout(() => controller.abort(), provider.timeoutMs);
      const response = await callAiProvider(
        provider,
        tier,
        key,
        prompt,
        schema,
        controller.signal,
        deps.fetchImpl,
      );
      attempt.tokens = response.tokens;
      try {
        result = parse(response.text);
      } catch {
        throw new ProviderFailure("invalid_output");
      }
      attempt.ok = true;
    } catch (error) {
      // Database/programming failures are not provider outages; fail closed.
      if (!(error instanceof ProviderFailure)) throw error;
      attempt.error = error.reason;
      fallback = error.canFallback;
      if (error.reason !== "capacity") capacityOnly = false;
    } finally {
      if (timer !== undefined) clearTimeout(timer);
      attempt.latency_ms = Math.round(performance.now() - started);
      try {
        await deps.record(attempt);
      } catch {
        console.error("AI attempt audit could not be saved");
      }
    }
    if (attempt.ok) return result!;
    if (!fallback) break;
  }
  if (capacityOnly) {
    throw new ApiError(
      ErrorCode.RATE_LIMITED,
      "AI requests have reached the service limit. Please try again later.",
    );
  }
  throw aiUnavailable();
}
export function serverRouterDependencies(
  client: SupabaseClient,
  userId: string,
  requestId: string,
): RouterDependencies {
  return {
    env: (key) => Deno.env.get(key),
    reserve: async (provider) => {
      const limit = Number(Deno.env.get("AI_DAILY_REQUEST_LIMIT") ?? "500");
      if (!Number.isInteger(limit) || limit < 1 || limit > 10000) {
        throw new Error("Invalid AI capacity limit");
      }
      const { data, error } = await client.rpc("reserve_ai_provider_request", {
        p_provider: provider.id,
        p_provider_limit: provider.dailyRequestLimit,
        p_total_limit: limit,
      });
      if (error) throw new Error("Unable to reserve AI provider capacity");
      return data === true;
    },
    record: async (attempt) => {
      const { error } = await client.from("ai_requests").insert({
        ...attempt,
        app_user_id: userId,
        request_id: requestId,
      });
      if (error) throw new Error("Unable to save AI attempt audit");
    },
  };
}
