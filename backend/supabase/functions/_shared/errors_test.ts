import { assertEquals } from "jsr:@std/assert@1";
import { ApiError, badRequest, ErrorCode, handle, readJsonObject } from "./errors.ts";

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
