/**
 * @file quota.ts
 * @description Pure free-tier quota decision for POST /ai-recommend, plus the
 *   time-zone helpers that turn the client's `x-timezone` header into the
 *   "day" bucket of the `usage` table and the `resetsAt` value of a 402.
 */

import { FreeLimits, type Tier } from "./types.ts";

export type QuotaDecision =
  | { allow: true }
  | { allow: false; code: "AI_DAILY_LIMIT"; resetsAt: number };

export interface QuotaInput {
  tier: Tier;
  /** `usage.ai_requests` for the caller's local day. */
  usedToday: number;
  /** The instant the request arrived. */
  now: Date;
  /** IANA zone from the `x-timezone` header, already validated. */
  timeZone: string;
  limit?: number;
}

/**
 * Decides whether an AI request may proceed.
 * Pro is unlimited. Free is allowed while usedToday < limit; otherwise a 402
 * payload with `resetsAt` = next local midnight in the caller's zone.
 */
export function decideAiQuota(input: QuotaInput): QuotaDecision {
  if (input.tier === "pro") return { allow: true };
  const limit = input.limit ?? FreeLimits.AI_REQUESTS_PER_DAY;
  if (input.usedToday < limit) return { allow: true };
  return {
    allow: false,
    code: "AI_DAILY_LIMIT",
    resetsAt: nextLocalMidnightEpochSeconds(input.now, input.timeZone),
  };
}

/** Returns the zone if Intl knows it, otherwise "UTC". */
export function normaliseTimeZone(candidate: string | null | undefined): string {
  if (!candidate || candidate.length > 64) return "UTC";
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: candidate });
    return candidate;
  } catch {
    return "UTC";
  }
}

interface LocalParts {
  year: number;
  month: number; // 1..12
  day: number;
  hour: number;
  minute: number;
  second: number;
}

function localParts(date: Date, timeZone: string): LocalParts {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).formatToParts(date);
  const get = (type: string): number => Number(parts.find((p) => p.type === type)?.value ?? "0");
  return {
    year: get("year"),
    month: get("month"),
    day: get("day"),
    hour: get("hour"),
    minute: get("minute"),
    second: get("second"),
  };
}

/** Offset of `timeZone` from UTC at `date`, in milliseconds (east positive). */
function offsetMs(date: Date, timeZone: string): number {
  const p = localParts(date, timeZone);
  const asUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  return asUtc - Math.floor(date.getTime() / 1000) * 1000;
}

/** "YYYY-MM-DD" of `date` in `timeZone`; the `usage.day` bucket. */
export function localDay(date: Date, timeZone: string): string {
  const p = localParts(date, timeZone);
  const mm = String(p.month).padStart(2, "0");
  const dd = String(p.day).padStart(2, "0");
  return `${p.year}-${mm}-${dd}`;
}

/**
 * Epoch seconds of the next local midnight after `date` in `timeZone`.
 * Two passes handle a DST transition between now and midnight.
 */
export function nextLocalMidnightEpochSeconds(date: Date, timeZone: string): number {
  const p = localParts(date, timeZone);
  const wallClock = Date.UTC(p.year, p.month - 1, p.day + 1, 0, 0, 0);
  let guess = wallClock - offsetMs(date, timeZone);
  guess = wallClock - offsetMs(new Date(guess), timeZone);
  return Math.floor(guess / 1000);
}
