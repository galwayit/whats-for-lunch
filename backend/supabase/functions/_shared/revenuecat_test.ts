import { assertEquals } from "jsr:@std/assert@1";
import { entitlementRowsFromEvent, type RevenueCatEnvelope, secretsMatch } from "./revenuecat.ts";

const nowMs = Date.parse("2026-09-02T03:00:00Z");
const future = Date.parse("2026-10-02T03:00:00Z");
const past = Date.parse("2026-08-02T03:00:00Z");

function envelope(event: RevenueCatEnvelope["event"]): RevenueCatEnvelope {
  return { api_version: "1.0", event };
}

Deno.test("INITIAL_PURCHASE grants pro until expiration", () => {
  const rows = entitlementRowsFromEvent(
    envelope({
      type: "INITIAL_PURCHASE",
      app_user_id: "$RCAnonymousID:abc",
      entitlement_ids: ["pro"],
      product_id: "lunch_pro_monthly",
      expiration_at_ms: future,
    }),
    nowMs,
  );
  assertEquals(rows, [{
    app_user_id: "$RCAnonymousID:abc",
    is_pro: true,
    product_id: "lunch_pro_monthly",
    expires_at: new Date(future).toISOString(),
    source: "revenuecat",
  }]);
});

Deno.test("RENEWAL refreshes the expiry", () => {
  const rows = entitlementRowsFromEvent(
    envelope({
      type: "RENEWAL",
      app_user_id: "user-1",
      entitlement_ids: ["pro"],
      product_id: "lunch_pro_yearly",
      expiration_at_ms: future,
    }),
    nowMs,
  );
  assertEquals(rows.length, 1);
  assertEquals(rows[0].is_pro, true);
  assertEquals(rows[0].product_id, "lunch_pro_yearly");
});

Deno.test("CANCELLATION keeps pro active until expiry", () => {
  const rows = entitlementRowsFromEvent(
    envelope({
      type: "CANCELLATION",
      app_user_id: "user-1",
      entitlement_ids: ["pro"],
      product_id: "lunch_pro_monthly",
      expiration_at_ms: future,
    }),
    nowMs,
  );
  assertEquals(rows[0].is_pro, true);
  assertEquals(rows[0].expires_at, new Date(future).toISOString());
});

Deno.test("EXPIRATION with a past expiry drops pro", () => {
  const rows = entitlementRowsFromEvent(
    envelope({
      type: "EXPIRATION",
      app_user_id: "user-1",
      entitlement_ids: ["pro"],
      product_id: "lunch_pro_monthly",
      expiration_at_ms: past,
    }),
    nowMs,
  );
  assertEquals(rows[0].is_pro, false);
  assertEquals(rows[0].expires_at, new Date(past).toISOString());
});

Deno.test("TRANSFER moves the entitlement, carrying expiry from the old row", () => {
  const rows = entitlementRowsFromEvent(
    envelope({
      type: "TRANSFER",
      transferred_from: ["$RCAnonymousID:old"],
      transferred_to: ["user-9"],
    }),
    nowMs,
    { product_id: "lunch_pro_yearly", expires_at: new Date(future).toISOString() },
  );
  assertEquals(rows, [
    {
      app_user_id: "$RCAnonymousID:old",
      is_pro: false,
      product_id: "lunch_pro_yearly",
      expires_at: new Date(future).toISOString(),
      source: "revenuecat",
    },
    {
      app_user_id: "user-9",
      is_pro: true,
      product_id: "lunch_pro_yearly",
      expires_at: new Date(future).toISOString(),
      source: "revenuecat",
    },
  ]);
});

Deno.test("purchases without entitlements, TEST events and malformed events change nothing", () => {
  assertEquals(
    entitlementRowsFromEvent(
      envelope({
        type: "INITIAL_PURCHASE",
        app_user_id: "u",
        entitlement_ids: [],
        expiration_at_ms: future,
      }),
      nowMs,
    )[0].is_pro,
    false,
  );
  assertEquals(entitlementRowsFromEvent(envelope({ type: "TEST", app_user_id: "u" }), nowMs), []);
  assertEquals(entitlementRowsFromEvent(envelope({ type: "RENEWAL" }), nowMs), []);
  assertEquals(
    entitlementRowsFromEvent({ event: undefined as unknown as RevenueCatEnvelope["event"] }, nowMs),
    [],
  );
});

Deno.test("secretsMatch compares exactly", () => {
  assertEquals(secretsMatch("abc", "abc"), true);
  assertEquals(secretsMatch("abc", "abd"), false);
  assertEquals(secretsMatch("ab", "abc"), false);
  assertEquals(secretsMatch("", ""), true);
});
