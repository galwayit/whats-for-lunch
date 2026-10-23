import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { aiDisclosure, loadAiConfig, MAX_PROVIDER_TIMEOUT_MS } from "./ai-config.ts";
import { routeAi } from "./ai-router.ts";

Deno.test("runtime model edits apply on the next request and preserve the in-flight snapshot", async () => {
  const parameters = {
    enabled: true,
    primary: "openai",
    backup: null,
    consentRevision: "1",
    providers: [{
      id: "openai",
      kind: "openai",
      models: { free: "gpt-6-luna", pro: "gpt-6-luna" },
      timeoutMs: 1000,
      maxOutputTokens: 1024,
      dailyRequestLimit: 10,
    }],
  };
  let reads = 0;
  const client = createClient("https://fixture.supabase.co", "fixture-key", {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: {
      fetch: (input) => {
        const url = new URL(String(input));
        assertEquals(url.pathname, "/rest/v1/system_parameters");
        assertEquals(url.searchParams.get("key"), "eq.ai.providers");
        reads++;
        return Promise.resolve(Response.json([{ value: parameters }]));
      },
    },
  });
  const inFlight = await loadAiConfig(client);
  parameters.providers[0].models = { free: "future-free-model", pro: "future-pro-model" };
  const nextRequest = await loadAiConfig(client);
  assertEquals(reads, 2);
  assertEquals(inFlight.providers[0].models.pro, "gpt-6-luna");
  assertEquals(
    (await aiDisclosure(nextRequest)).consentVersion,
    (await aiDisclosure(inFlight)).consentVersion,
  );

  const models: string[] = [];
  const deps = {
    env: () => "fixture-key",
    reserve: () => Promise.resolve(true),
    record: () => Promise.resolve(),
    fetchImpl: ((_url, init) => {
      models.push(JSON.parse(String(init?.body)).model);
      return Promise.resolve(Response.json({
        status: "completed",
        output: [{ type: "message", content: [{ type: "output_text", text: '{"ok":true}' }] }],
      }));
    }) as typeof fetch,
  };
  await routeAi(inFlight, "pro", "fixture", {}, JSON.parse, deps);
  await routeAi(nextRequest, "free", "fixture", {}, JSON.parse, deps);
  await routeAi(nextRequest, "pro", "fixture", {}, JSON.parse, deps);
  assertEquals(models, ["gpt-6-luna", "future-free-model", "future-pro-model"]);
});

Deno.test("provider timeout accepts up to 30 s per attempt and rejects more", async () => {
  const withTimeout = (timeoutMs: number) => ({
    enabled: true,
    primary: "openai",
    backup: null,
    consentRevision: "1",
    providers: [{
      id: "openai",
      kind: "openai",
      models: { free: "gpt-6-luna", pro: "gpt-6-luna" },
      timeoutMs,
      maxOutputTokens: 1024,
      dailyRequestLimit: 10,
    }],
  });
  const clientFor = (value: unknown) =>
    createClient("https://fixture.supabase.co", "fixture-key", {
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
      global: { fetch: () => Promise.resolve(Response.json([{ value }])) },
    });
  assertEquals(MAX_PROVIDER_TIMEOUT_MS, 30_000);
  assertEquals((await loadAiConfig(clientFor(withTimeout(25_000)))).providers[0].timeoutMs, 25_000);
  assertEquals((await loadAiConfig(clientFor(withTimeout(30_000)))).providers[0].timeoutMs, 30_000);
  await assertRejects(() => loadAiConfig(clientFor(withTimeout(30_001))));
  await assertRejects(() => loadAiConfig(clientFor(withTimeout(999))));
});
