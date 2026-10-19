import { assertEquals } from "jsr:@std/assert@1";
import { tierFromRow } from "./tier.ts";

const nowMs = Date.parse("2026-09-02T03:00:00Z");

Deno.test("tierFromRow honours is_pro and expires_at", () => {
  assertEquals(tierFromRow(null, nowMs), "free");
  assertEquals(tierFromRow({ is_pro: false, expires_at: null }, nowMs), "free");
  assertEquals(tierFromRow({ is_pro: true, expires_at: null }, nowMs), "free");
  assertEquals(tierFromRow({ is_pro: true, expires_at: "2026-10-01T00:00:00Z" }, nowMs), "pro");
  assertEquals(tierFromRow({ is_pro: true, expires_at: "2026-09-01T00:00:00Z" }, nowMs), "free");
});
