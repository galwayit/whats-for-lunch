import { assertEquals } from "jsr:@std/assert@1";
import {
  decideAiQuota,
  localDay,
  nextLocalMidnightEpochSeconds,
  normaliseTimeZone,
} from "./quota.ts";

// 2026-09-02T03:00:00Z is 13:00 AEST (UTC+10) in Sydney.
const now = new Date("2026-09-02T03:00:00Z");
const sydneyNextMidnight = Date.UTC(2026, 8, 2, 14, 0, 0) / 1000; // 2026-09-03 00:00 AEST

Deno.test("free tier with 0 used is allowed", () => {
  assertEquals(decideAiQuota({ tier: "free", usedToday: 0, now, timeZone: "Australia/Sydney" }), {
    allow: true,
  });
});

Deno.test("free tier with 1 used is denied with resetsAt at next Sydney midnight", () => {
  assertEquals(decideAiQuota({ tier: "free", usedToday: 1, now, timeZone: "Australia/Sydney" }), {
    allow: false,
    code: "AI_DAILY_LIMIT",
    resetsAt: sydneyNextMidnight,
  });
});

Deno.test("pro tier is always allowed", () => {
  assertEquals(decideAiQuota({ tier: "pro", usedToday: 99, now, timeZone: "Australia/Sydney" }), {
    allow: true,
  });
});

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
