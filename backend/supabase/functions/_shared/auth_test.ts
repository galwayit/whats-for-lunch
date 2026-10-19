import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { requireAppUserId } from "./auth.ts";
import { ApiError } from "./errors.ts";

Deno.test("billing identity cannot be overridden by a client header", () => {
  const req = new Request("https://lunch.test", {
    headers: { "x-app-user-id": "another-paid-user" },
  });
  assertEquals(
    requireAppUserId(req, { id: "verified-user", email: null, displayName: "Host" }),
    "verified-user",
  );
});
Deno.test("an anonymous RevenueCat id is not an authentication credential", () => {
  const req = new Request("https://lunch.test", {
    headers: { "x-app-user-id": "$RCAnonymousID:anything" },
  });
  assertThrows(() => requireAppUserId(req, null), ApiError, "Sign in");
});
