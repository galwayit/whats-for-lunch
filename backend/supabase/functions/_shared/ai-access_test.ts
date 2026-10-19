import { assertEquals, assertRejects, assertThrows } from "jsr:@std/assert@1";
import { requireAiConsent, reserveAi } from "./ai-access.ts";
import { ApiError } from "./errors.ts";

Deno.test("both AI endpoints reject absent, revoked and obsolete consent", () => {
  for (const body of [{}, { aiConsentVersion: false }, { aiConsentVersion: "old" }]) {
    assertThrows(() => requireAiConsent(body, "ai-v2-current"), ApiError);
  }
  requireAiConsent({ aiConsentVersion: "ai-v2-current" }, "ai-v2-current");
});

Deno.test("free access reserves one request and receives the daily gate on the next", async () => {
  let calls = 0;
  const client = {
    rpc: (_name: string, args: Record<string, unknown>) => {
      assertEquals(args.p_limit, 1);
      return Promise.resolve({ data: calls++ === 0, error: null });
    },
  } as unknown as Parameters<typeof reserveAi>[0];
  const id = await reserveAi(client, "fictional-user", "free");
  assertEquals(typeof id, "string");
  const error = await assertRejects(() => reserveAi(client, "fictional-user", "free"), ApiError);
  assertEquals(error.code, "AI_DAILY_LIMIT");
  assertEquals(error.status, 402);
  assertEquals(calls, 2);
});

Deno.test("subscribed AI retains the ten-request atomic daily allowance", async () => {
  let request: Record<string, unknown> = {};
  const client = {
    rpc: (name: string, args: Record<string, unknown>) => {
      assertEquals(name, "reserve_ai_request");
      request = args;
      return Promise.resolve({ data: true, error: null });
    },
  } as unknown as Parameters<typeof reserveAi>[0];
  const id = await reserveAi(client, "fictional-user", "pro");
  assertEquals(request.p_app_user_id, "fictional-user");
  assertEquals(request.p_limit, 10);
  assertEquals(request.p_request_id, id);
});

Deno.test("an exhausted subscriber receives quota feedback rather than an upgrade gate", async () => {
  const client = {
    rpc: () => Promise.resolve({ data: false, error: null }),
  } as unknown as Parameters<typeof reserveAi>[0];
  const error = await assertRejects(() => reserveAi(client, "fictional-user", "pro"), ApiError);
  assertEquals(error.code, "AI_DAILY_LIMIT");
  assertEquals(error.status, 402);
});
