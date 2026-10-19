/** Non-secret, service-managed system parameters. Read once per logical request. */
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { ApiError, ErrorCode } from "./errors.ts";
import type { Tier } from "./types.ts";

export type AiProviderKind = "google" | "openai" | "anthropic" | "openai-compatible";
export type ReadEnv = (name: string) => string | undefined;
export interface AiProvider {
  id: string;
  kind: AiProviderKind;
  name: string;
  privacyUrl: string;
  secretEnv: string;
  models: Record<Tier, string>;
  endpoint?: string;
  timeoutMs: number;
  maxOutputTokens: number;
  dailyRequestLimit: number;
}
export interface AiConfig {
  enabled: boolean;
  primary: string;
  backup: string | null;
  consentRevision: string;
  providers: AiProvider[];
}
export interface AiDisclosure {
  consentVersion: string;
  providers: { name: string; privacyUrl: string }[];
}
const BUILT_INS = {
  google: {
    name: "Google Gemini",
    privacyUrl: "https://policies.google.com/privacy",
    secretEnv: "GEMINI_API_KEY",
  },
  openai: {
    name: "OpenAI",
    privacyUrl: "https://openai.com/policies/privacy-policy/",
    secretEnv: "OPENAI_API_KEY",
  },
  anthropic: {
    name: "Anthropic Claude",
    privacyUrl: "https://www.anthropic.com/legal/privacy",
    secretEnv: "ANTHROPIC_API_KEY",
  },
} as const;
export function aiUnavailable(): ApiError {
  return new ApiError(
    ErrorCode.AI_UNAVAILABLE,
    "AI recommendations are unavailable. Please try again later.",
  );
}
function invalid(): never {
  throw new Error("Invalid AI system parameters");
}
function object(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) invalid();
  return value as Record<string, unknown>;
}
function text(value: unknown, pattern: RegExp, max = 128): string {
  if (typeof value !== "string" || value.length > max || !pattern.test(value)) invalid();
  return value;
}
function integer(value: unknown, min: number, max: number): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max) {
    invalid();
  }
  return value;
}
function onlyKeys(value: Record<string, unknown>, allowed: string[]) {
  if (Object.keys(value).some((key) => !allowed.includes(key))) invalid();
}
function httpsUrl(value: unknown): string {
  const raw = text(value, /^https:\/\//, 512);
  const url = new URL(raw);
  if (
    url.protocol !== "https:" || url.username || url.password || url.hash || url.search ||
    !/^[a-z][a-z0-9.-]+\.[a-z]{2,}$/i.test(url.hostname) || url.hostname.endsWith(".localhost")
  ) invalid();
  return url.href;
}
export function parseAiConfig(raw: unknown): AiConfig {
  const row = object(raw);
  onlyKeys(row, ["enabled", "primary", "backup", "consentRevision", "providers"]);
  if (
    typeof row.enabled !== "boolean" || !Array.isArray(row.providers) || row.providers.length < 1 ||
    row.providers.length > 10
  ) invalid();
  const providers = row.providers.map((raw): AiProvider => {
    const p = object(raw);
    onlyKeys(p, [
      "id",
      "kind",
      "name",
      "privacyUrl",
      "secretEnv",
      "models",
      "endpoint",
      "timeoutMs",
      "maxOutputTokens",
      "dailyRequestLimit",
    ]);
    const id = text(p.id, /^[a-z][a-z0-9_-]*$/, 32);
    const kind = text(p.kind, /^(google|openai|anthropic|openai-compatible)$/) as AiProviderKind;
    const models = object(p.models);
    onlyKeys(models, ["free", "pro"]);
    const base = {
      id,
      kind,
      models: {
        free: text(models.free, /^[a-zA-Z0-9][a-zA-Z0-9._:/-]*$/),
        pro: text(models.pro, /^[a-zA-Z0-9][a-zA-Z0-9._:/-]*$/),
      },
      timeoutMs: integer(p.timeoutMs, 1000, 10000),
      maxOutputTokens: integer(p.maxOutputTokens, 256, 4096),
      dailyRequestLimit: integer(p.dailyRequestLimit, 1, 10000),
    };
    if (kind !== "openai-compatible") {
      // Built-in identities, keys and endpoints cannot be redirected by a config typo.
      if (p.endpoint || p.secretEnv || p.name || p.privacyUrl) invalid();
      return { ...base, ...BUILT_INS[kind] };
    }
    return {
      ...base,
      name: text(p.name, /^[\p{L}\p{N}][\p{L}\p{N} .()_-]*$/u, 80),
      privacyUrl: httpsUrl(p.privacyUrl),
      secretEnv: text(p.secretEnv, /^AI_COMPAT_[A-Z0-9_]+_API_KEY$/),
      endpoint: httpsUrl(p.endpoint),
    };
  });
  if (new Set(providers.map((p) => p.id)).size !== providers.length) invalid();
  const primary = text(row.primary, /^[a-z][a-z0-9_-]*$/, 32);
  const backup = row.backup === null ? null : text(row.backup, /^[a-z][a-z0-9_-]*$/, 32);
  if (
    !providers.some((p) => p.id === primary) ||
    (backup !== null && (!providers.some((p) => p.id === backup) || backup === primary))
  ) invalid();
  return {
    enabled: row.enabled,
    primary,
    backup,
    providers,
    consentRevision: text(row.consentRevision, /^[a-zA-Z0-9._-]+$/, 64),
  };
}
export function activeProviders(config: AiConfig): AiProvider[] {
  return [config.primary, config.backup].filter((id): id is string => id !== null).map((id) =>
    config.providers.find((p) => p.id === id)!
  );
}
export async function aiDisclosure(config: AiConfig): Promise<AiDisclosure> {
  // Same recipients in a different priority/model order need no new permission.
  // A changed recipient, endpoint, privacy notice or explicit policy revision does.
  const recipients = [
    ...new Set(
      activeProviders(config).map((p) =>
        JSON.stringify({
          kind: p.kind,
          name: p.name,
          privacyUrl: p.privacyUrl,
          endpoint: p.endpoint ?? "",
        })
      ),
    ),
  ].sort();
  const bytes = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(JSON.stringify([config.consentRevision, recipients])),
  );
  const hash = Array.from(new Uint8Array(bytes), (byte) => byte.toString(16).padStart(2, "0")).join(
    "",
  );
  return {
    consentVersion: `ai-v2-${hash}`,
    providers: recipients.map((r) => {
      const p = JSON.parse(r);
      return { name: p.name, privacyUrl: p.privacyUrl };
    }),
  };
}
export async function loadAiConfig(client: SupabaseClient): Promise<AiConfig> {
  const { data, error } = await client.from("system_parameters").select("value").eq(
    "key",
    "ai.providers",
  ).maybeSingle();
  try {
    if (error || !data) throw new Error("Missing AI system parameters");
    const config = parseAiConfig(data.value);
    if (!config.enabled) throw new Error("AI disabled");
    return config;
  } catch {
    console.error("AI system parameters are missing, disabled or invalid");
    throw aiUnavailable();
  }
}
export function providerKey(provider: AiProvider, env: ReadEnv): string | undefined {
  if (provider.kind === "openai-compatible") {
    const approved = (env("AI_ALLOWED_COMPATIBLE_ENDPOINTS") ?? "").split(",").map((s) => s.trim());
    if (!approved.includes(provider.endpoint!)) return undefined;
  }
  return env(provider.secretEnv)?.trim() || undefined;
}
export function requireConfiguredRoute(config: AiConfig, env: ReadEnv): void {
  if (!config.enabled || !activeProviders(config).some((p) => providerKey(p, env))) {
    throw aiUnavailable();
  }
}
