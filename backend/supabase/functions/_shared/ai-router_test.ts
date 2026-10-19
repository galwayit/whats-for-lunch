import { assertEquals, assertRejects, assertThrows } from "jsr:@std/assert@1";
import {
  activeProviders,
  type AiConfig,
  aiDisclosure,
  parseAiConfig,
  providerKey,
} from "./ai-config.ts";
import { callAiProvider, ProviderFailure } from "./ai-providers.ts";
import { type AiAttempt, routeAi } from "./ai-router.ts";
import { ApiError } from "./errors.ts";
import { requireAiConsent } from "./ai-access.ts";
const profile = (id: string, kind = id) => ({
  id,
  kind,
  models: { free: "model-free", pro: "model-pro" },
  timeoutMs: 1000,
  maxOutputTokens: 1024,
  dailyRequestLimit: 10,
});
function config(backup: string | null = "openai"): AiConfig {
  return parseAiConfig({
    enabled: true,
    primary: "google",
    backup,
    consentRevision: "1",
    providers: [profile("google"), profile("openai"), profile("claude", "anthropic")],
  });
}
const schema = {
  type: "object",
  properties: { ok: { type: "boolean" } },
  required: ["ok"],
  additionalProperties: false,
};
const body = '{"ok":true}';
const google = (text = body) =>
  Response.json({
    candidates: [{ finishReason: "STOP", content: { parts: [{ text }] } }],
    usageMetadata: { totalTokenCount: 9 },
  });
const openai = () =>
  Response.json({
    status: "completed",
    output: [{ type: "message", content: [{ type: "output_text", text: body }] }],
    usage: { total_tokens: 8 },
  });
const parse = (text: string) => {
  const data = JSON.parse(text);
  if (data.ok !== true) throw new Error("invalid");
  return data;
};
const key = () => "test-key";
function harness(
  fetchImpl: typeof fetch,
  env: (name: string) => string | undefined = key,
  reserve = async () => true,
) {
  const attempts: AiAttempt[] = [];
  const reservations: string[] = [];
  return {
    attempts,
    reservations,
    deps: {
      fetchImpl,
      env,
      reserve: async (p: { id: string }) => {
        reservations.push(p.id);
        return await reserve();
      },
      record: async (a: AiAttempt) => {
        attempts.push(a);
      },
    },
  };
}
Deno.test("successful primary makes one bounded call, selects tier model and never sends to backup", async () => {
  const h = harness(async (url, init) => {
    assertEquals(String(url).includes("model-pro"), true);
    assertEquals(init?.redirect, "error");
    assertEquals(new Headers(init?.headers).get("x-goog-api-key"), "test-key");
    assertEquals(JSON.parse(String(init?.body)).generationConfig.responseJsonSchema, schema);
    return google();
  });
  assertEquals(await routeAi(config(), "pro", "fictional lunch", schema, parse, h.deps), {
    ok: true,
  });
  assertEquals(h.reservations, ["google"]);
  assertEquals(h.attempts.map((a) => [a.provider, a.ok, a.tokens]), [["google", true, 9]]);
});
for (const status of [401, 402, 403, 404, 408, 429, 500, 503]) {
  Deno.test(`primary HTTP ${status} falls back once and records both attempts`, async () => {
    let count = 0;
    const h = harness(async () =>
      ++count === 1 ? new Response("sensitive upstream diagnostic", { status }) : openai()
    );
    assertEquals(await routeAi(config(), "free", "fictional lunch", schema, parse, h.deps), {
      ok: true,
    });
    assertEquals(h.reservations, ["google", "openai"]);
    assertEquals(h.attempts.map((a) => [a.route_role, a.error, a.ok]), [[
      "primary",
      `http_${status}`,
      false,
    ], ["backup", null, true]]);
  });
}
Deno.test("missing primary key can use a configured backup without reserving a primary call", async () => {
  const h = harness(
    async () => openai(),
    (name?: string) => name === "OPENAI_API_KEY" ? "test-key" : "",
  );
  await routeAi(config(), "pro", "fictional lunch", schema, parse, h.deps);
  assertEquals(h.reservations, ["openai"]);
  assertEquals(h.attempts[0].error, "not_configured");
});
Deno.test("no credentials makes no upstream calls", async () => {
  const h = harness(async () => {
    throw new Error("must not fetch");
  }, () => "");
  const error = await assertRejects(
    () => routeAi(config(), "pro", "fictional lunch", schema, parse, h.deps),
    ApiError,
  );
  assertEquals(error.code, "AI_UNAVAILABLE");
  assertEquals(h.reservations.length, 0);
});
Deno.test("timeout aborts primary and makes one backup request", async () => {
  const c = config();
  c.providers[0].timeoutMs = 5;
  let count = 0;
  const h = harness(async (_url, init) => {
    if (++count === 2) return openai();
    return await new Promise<Response>((_resolve, reject) =>
      init!.signal!.addEventListener("abort", () => reject(new Error("aborted")), { once: true })
    );
  });
  await routeAi(c, "pro", "fictional lunch", schema, parse, h.deps);
  assertEquals(h.attempts[0].error, "timeout");
});
Deno.test("malformed or semantically invalid output uses backup", async () => {
  for (const text of ["not json", '{"ok":false}']) {
    let count = 0;
    const h = harness(async () => ++count === 1 ? google(text) : openai());
    await routeAi(config(), "pro", "fictional lunch", schema, parse, h.deps);
    assertEquals(h.attempts[0].error, "invalid_output");
  }
});
Deno.test("refusals and bad requests never fail over", async () => {
  for (
    const response of [
      new Response("private", { status: 400 }),
      Response.json({ candidates: [{ finishReason: "SAFETY" }] }),
    ]
  ) {
    const h = harness(async () => response);
    await assertRejects(
      () => routeAi(config(), "pro", "fictional lunch", schema, parse, h.deps),
      ApiError,
    );
    assertEquals(h.reservations, ["google"]);
  }
});
Deno.test("both failures return safe error and never attempt a third provider", async () => {
  const h = harness(async () => new Response("secret=do-not-expose", { status: 503 }));
  const error = await assertRejects(
    () => routeAi(config(), "pro", "fictional lunch", schema, parse, h.deps),
    ApiError,
  );
  assertEquals(error.code, "AI_UNAVAILABLE");
  assertEquals(h.attempts.length, 2);
  assertEquals(JSON.stringify(h.attempts).includes("secret"), false);
});
Deno.test("capacity failure never calls an upstream; database failure does not bypass budget", async () => {
  const h = harness(
    async () => {
      throw new Error("must not fetch");
    },
    key,
    async () => false,
  );
  const error = await assertRejects(
    () => routeAi(config(), "pro", "fictional lunch", schema, parse, h.deps),
    ApiError,
  );
  assertEquals(error.code, "RATE_LIMITED");
  const broken = harness(async () => openai(), key, async () => {
    throw new Error("DB unavailable");
  });
  await assertRejects(
    () => routeAi(config(), "pro", "fictional lunch", schema, parse, broken.deps),
    Error,
    "DB unavailable",
  );
  assertEquals(broken.reservations, ["google"]);
});
Deno.test("configuration rejects duplicated routes, secret values and unsafe compatible endpoints", () => {
  const raw = {
    enabled: true,
    primary: "google",
    backup: "google",
    consentRevision: "1",
    providers: [profile("google")],
  };
  assertThrows(() => parseAiConfig(raw));
  assertThrows(() => parseAiConfig({ ...raw, backup: null, apiKey: "must not store" }));
  for (
    const endpoint of [
      "http://example.com/v1/chat/completions",
      "https://127.0.0.1/",
      "https://user:pass@example.com/",
      "https://example.com/?key=secret",
    ]
  ) {
    assertThrows(() =>
      parseAiConfig({
        ...raw,
        primary: "custom",
        backup: null,
        providers: [{
          ...profile("custom", "openai-compatible"),
          name: "Example AI",
          privacyUrl: "https://example.com/privacy",
          secretEnv: "AI_COMPAT_EXAMPLE_API_KEY",
          endpoint,
        }],
      })
    );
  }
});
Deno.test("provider disclosure invalidates prior consent but model changes and route swaps do not", async () => {
  const c = config();
  const original = await aiDisclosure(c);
  assertEquals(original.providers.map((p) => p.name), ["Google Gemini", "OpenAI"]);
  c.providers[0].models.pro = "new-model";
  c.primary = "openai";
  c.backup = "google";
  assertEquals((await aiDisclosure(c)).consentVersion, original.consentVersion);
  c.backup = "claude";
  const changed = await aiDisclosure(c);
  assertEquals(changed.consentVersion === original.consentVersion, false);
  assertThrows(
    () => requireAiConsent({ aiConsentVersion: original.consentVersion }, changed.consentVersion),
    ApiError,
  );
  requireAiConsent({ aiConsentVersion: changed.consentVersion }, changed.consentVersion);
  assertEquals(JSON.stringify(changed).includes("secretEnv"), false);
});
Deno.test("OpenAI and Claude adapters use their current structured output APIs", async () => {
  for (const p of config().providers.filter((p) => p.kind !== "google")) {
    const response = await callAiProvider(
      p,
      "free",
      "test-key",
      "fictional lunch",
      schema,
      new AbortController().signal,
      async (url, init) => {
        const request = JSON.parse(String(init?.body));
        assertEquals(request.model, "model-free");
        if (p.kind === "openai") {
          assertEquals(String(url), "https://api.openai.com/v1/responses");
          assertEquals(request.store, false);
          assertEquals(request.text.format.schema, schema);
          return openai();
        }
        assertEquals(String(url), "https://api.anthropic.com/v1/messages");
        assertEquals(new Headers(init?.headers).get("anthropic-version"), "2023-06-01");
        assertEquals(request.output_config.format.schema, schema);
        return Response.json({
          stop_reason: "end_turn",
          content: [{ type: "text", text: body }],
          usage: { input_tokens: 4, output_tokens: 3 },
        });
      },
    );
    assertEquals(response.text, body);
  }
});
Deno.test("compatible providers require exact operator allowlist and use their own secret", async () => {
  const c = parseAiConfig({
    enabled: true,
    primary: "example",
    backup: null,
    consentRevision: "1",
    providers: [{
      ...profile("example", "openai-compatible"),
      name: "Example AI",
      privacyUrl: "https://example.com/privacy",
      endpoint: "https://api.example.com/v1/chat/completions",
      secretEnv: "AI_COMPAT_EXAMPLE_API_KEY",
    }],
  });
  const p = activeProviders(c)[0];
  assertEquals(providerKey(p, () => "unapproved"), undefined);
  const env = (name: string) =>
    name === "AI_ALLOWED_COMPATIBLE_ENDPOINTS" ? p.endpoint : "test-key";
  assertEquals(providerKey(p, env), "test-key");
  const h = harness(async (url, init) => {
    assertEquals(String(url), p.endpoint);
    assertEquals(JSON.parse(String(init?.body)).response_format.json_schema.schema, schema);
    return Response.json({ choices: [{ finish_reason: "stop", message: { content: body } }] });
  }, env);
  assertEquals(await routeAi(c, "pro", "fictional lunch", schema, parse, h.deps), { ok: true });
});
Deno.test("truncated and refused structured responses do not pass validation", async () => {
  for (
    const [kind, payload, refusal] of [
      ["openai", { status: "incomplete", output: [] }, false],
      ["openai", {
        status: "completed",
        output: [{ type: "message", content: [{ type: "refusal" }] }],
      }, true],
      ["anthropic", { stop_reason: "refusal" }, true],
      ["anthropic", { stop_reason: "max_tokens", content: [{ type: "text", text: body }] }, false],
    ] as const
  ) {
    const p = config().providers.find((p) => p.kind === kind)!;
    const error = await assertRejects(
      () =>
        callAiProvider(
          p,
          "pro",
          "test-key",
          "fictional lunch",
          schema,
          new AbortController().signal,
          async () => Response.json(payload),
        ),
      ProviderFailure,
    );
    assertEquals(error.canFallback, !refusal);
  }
});

Deno.test("malformed provider content blocks still allow fallback instead of throwing an internal error", async () => {
  for (
    const [kind, payload] of [
      ["google", { candidates: [{ finishReason: "STOP", content: { parts: [null, 42] } }] }],
      ["openai", { status: "completed", output: [null, { type: "message", content: [null, 42] }] }],
      ["anthropic", { stop_reason: "end_turn", content: [null, 42] }],
    ] as const
  ) {
    const provider = config().providers.find((p) => p.kind === kind)!;
    const error = await assertRejects(
      () =>
        callAiProvider(
          provider,
          "pro",
          "test-key",
          "fictional lunch",
          schema,
          new AbortController().signal,
          async () => Response.json(payload),
        ),
      ProviderFailure,
    );
    assertEquals(error.reason, "empty_output");
    assertEquals(error.canFallback, true);
  }
});
