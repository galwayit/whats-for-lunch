import { assertEquals } from "jsr:@std/assert@1";
import { localDay, nextLocalMidnightEpochSeconds, normaliseTimeZone } from "./quota.ts";

const now = new Date("2026-09-02T03:00:00Z");

Deno.test("nextLocalMidnight handles UTC and a DST transition", () => {
  assertEquals(nextLocalMidnightEpochSeconds(now, "UTC"), Date.UTC(2026, 8, 3) / 1000);
  // Sydney DST starts 2026-10-04 02:00 AEST. The day before, midnight is still +10.
  assertEquals(
    nextLocalMidnightEpochSeconds(new Date("2026-10-03T05:00:00Z"), "Australia/Sydney"),
    Date.UTC(2026, 9, 3, 14) / 1000,
  );
  // After the switch, midnight is +11.
  assertEquals(
    nextLocalMidnightEpochSeconds(new Date("2026-10-04T05:00:00Z"), "Australia/Sydney"),
    Date.UTC(2026, 9, 4, 13) / 1000,
  );
});

Deno.test("localDay buckets by the caller's zone", () => {
  // 2026-09-02T15:00Z is already 2026-09-03 in Sydney but still 09-02 in Los Angeles.
  const late = new Date("2026-09-02T15:00:00Z");
  assertEquals(localDay(late, "Australia/Sydney"), "2026-09-03");
  assertEquals(localDay(late, "America/Los_Angeles"), "2026-09-02");
  assertEquals(localDay(late, "UTC"), "2026-09-02");
});

Deno.test("normaliseTimeZone falls back to UTC for garbage", () => {
  assertEquals(normaliseTimeZone("Australia/Sydney"), "Australia/Sydney");
  assertEquals(normaliseTimeZone("Mars/Olympus"), "UTC");
  assertEquals(normaliseTimeZone(null), "UTC");
  assertEquals(normaliseTimeZone(""), "UTC");
});
