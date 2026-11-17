import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { ApiError, ErrorCode } from "./errors.ts";
import { ENTITLEMENT_FRESH_MS, tierFor, tierFromRow } from "./tier.ts";

const nowMs = Date.parse("2026-09-02T03:00:00Z");

Deno.test("tierFromRow honours is_pro and expires_at", () => {
  assertEquals(tierFromRow(null, nowMs), "free");
  assertEquals(tierFromRow({ is_pro: false, expires_at: null }, nowMs), "free");
  assertEquals(tierFromRow({ is_pro: true, expires_at: null }, nowMs), "free");
  assertEquals(tierFromRow({ is_pro: true, expires_at: "2026-10-01T00:00:00Z" }, nowMs), "pro");
  assertEquals(tierFromRow({ is_pro: true, expires_at: "2026-09-01T00:00:00Z" }, nowMs), "free");
});

type Row = { is_pro: boolean; expires_at: string | null; reconciled_at: string | null };

/** `reconcile` stands in for the RevenueCat read; it counts calls and may replace the stored row. */
function billing(stored: Row | null, afterReconcile?: Row | "outage" | "fault") {
  const state = { row: stored, reconciles: 0 };
  const client = {
    from: () => ({
      select: () => ({
        eq: () => ({ maybeSingle: () => Promise.resolve({ data: state.row, error: null }) }),
      }),
    }),
  } as unknown as Parameters<typeof tierFor>[0];
  const reconcile = () => {
    state.reconciles++;
    if (afterReconcile === "outage") {
      return Promise.reject(
        new ApiError(
          ErrorCode.UPSTREAM_ERROR,
          "Subscription verification is temporarily unavailable",
        ),
      );
    }
    if (afterReconcile === "fault") return Promise.reject(new Error("database: fictional fault"));
    if (afterReconcile) state.row = afterReconcile;
    return Promise.resolve([]);
  };
  return { state, tier: () => tierFor(client, "fictional-user", reconcile) };
}

const ago = (ms: number) => new Date(Date.now() - ms).toISOString();
const pro = (reconciledAgoMs: number): Row => ({
  is_pro: true,
  expires_at: new Date(Date.now() + 86_400_000).toISOString(),
  reconciled_at: ago(reconciledAgoMs),
});
const free: Row = { is_pro: false, expires_at: null, reconciled_at: ago(1000) };

Deno.test("a recently verified Pro row is trusted without a provider call", async () => {
  const { state, tier } = billing(pro(ENTITLEMENT_FRESH_MS - 30_000), "outage");
  assertEquals(await tier(), "pro");
  assertEquals(state.reconciles, 0);
});

Deno.test("a stale or never-verified Pro row is reconciled before it is trusted", async () => {
  const refunded = billing(pro(ENTITLEMENT_FRESH_MS + 30_000), free);
  assertEquals(await refunded.tier(), "free");
  assertEquals(refunded.state.reconciles, 1);

  const legacy = billing({ ...pro(0), reconciled_at: null }, pro(0));
  assertEquals(await legacy.tier(), "pro");
  assertEquals(legacy.state.reconciles, 1);
});

Deno.test("a free, absent or expired row is always reconciled so a new purchase is seen at once", async () => {
  const expired: Row = { ...pro(1000), expires_at: ago(1000) };
  for (const stored of [free, null, expired]) {
    const { state, tier } = billing(stored, pro(0));
    assertEquals(await tier(), "pro");
    assertEquals(state.reconciles, 1);
  }
});

Deno.test("a provider outage leaves a free account free instead of failing the request", async () => {
  for (const stored of [free, null]) {
    const { state, tier } = billing(stored, "outage");
    assertEquals(await tier(), "free");
    assertEquals(state.reconciles, 1);
  }
});

Deno.test("a provider outage never extends a stale Pro row", async () => {
  const { state, tier } = billing(pro(ENTITLEMENT_FRESH_MS + 30_000), "outage");
  await assertRejects(tier, Error, "temporarily unavailable");
  assertEquals(state.reconciles, 1);
});

Deno.test("a configuration or database fault is not hidden as a free tier", async () => {
  const { state, tier } = billing(free, "fault");
  await assertRejects(tier, Error, "database: fictional fault");
  assertEquals(state.reconciles, 1);
});
