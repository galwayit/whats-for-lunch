import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import {
  AI_BODY_LIMIT,
  ApiError,
  badRequest,
  DEFAULT_BODY_LIMIT,
  ErrorCode,
  handle,
  readJsonObject,
} from "./errors.ts";

Deno.test("handle answers preflight, rejects wrong methods and maps ApiError", async () => {
  const fn = handle(["POST"], (_req) => {
    throw new ApiError(ErrorCode.AI_DAILY_LIMIT, "Daily AI limit reached", { resetsAt: 1 });
  });
  const preflight = await fn(new Request("https://x/fn", { method: "OPTIONS" }));
  assertEquals(preflight.status, 204);
  assertEquals(preflight.headers.get("Access-Control-Allow-Origin"), "*");

  const wrong = await fn(new Request("https://x/fn", { method: "GET" }));
  assertEquals(wrong.status, 405);

  const denied = await fn(new Request("https://x/fn", { method: "POST" }));
  assertEquals(denied.status, 402);
  assertEquals(await denied.json(), {
    error: { code: "AI_DAILY_LIMIT", message: "Daily AI limit reached", resetsAt: 1 },
  });
});

Deno.test("handle hides unexpected errors behind a generic 500", async () => {
  const fn = handle(["POST"], (_req) => {
    throw new Error("secret detail");
  });
  const res = await fn(new Request("https://x/fn", { method: "POST" }));
  assertEquals(res.status, 500);
  assertEquals((await res.json()).error.message, "Something went wrong");
});

Deno.test("readJsonObject rejects non-objects with 400", async () => {
  const bad = new Request("https://x/fn", { method: "POST", body: "[1]" });
  try {
    await readJsonObject(bad);
    throw new Error("expected throw");
  } catch (err) {
    assertEquals(err instanceof ApiError && err.status === 400, true);
  }
  assertEquals(badRequest("x").code, "BAD_REQUEST");
});

Deno.test("readJsonObject accepts an AI candidate body over the default limit only with the AI limit", async () => {
  // 20 full candidates from the app measured about 105 KB on 23 October 2026.
  const body = JSON.stringify({ candidates: "x".repeat(100 * 1024) });
  const make = () =>
    new Request("https://x/fn", {
      method: "POST",
      body,
      headers: { "content-type": "application/json" },
    });
  assertEquals(body.length > DEFAULT_BODY_LIMIT && body.length < AI_BODY_LIMIT, true);
  await assertRejects(() => readJsonObject(make()), ApiError, "too large");
  const parsed = await readJsonObject(make(), AI_BODY_LIMIT);
  assertEquals(typeof parsed.candidates, "string");
  await assertRejects(
    () =>
      readJsonObject(
        new Request("https://x/fn", {
          method: "POST",
          body: JSON.stringify({ c: "x".repeat(AI_BODY_LIMIT) }),
        }),
        AI_BODY_LIMIT,
      ),
    ApiError,
    "too large",
  );
});

Deno.test("readJsonObject bounds streamed bodies without Content-Length", async () => {
  let cancelled = false;
  const stream = new ReadableStream<Uint8Array>({
    pull(controller) {
      controller.enqueue(new Uint8Array(40 * 1024));
    },
    cancel() {
      cancelled = true;
    },
  });
  const request = new Request("https://x/fn", { method: "POST", body: stream });
  await assertRejects(() => readJsonObject(request), ApiError, "too large");
  assertEquals(cancelled, true);
});
