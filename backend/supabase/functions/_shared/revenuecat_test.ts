import { assertEquals } from "jsr:@std/assert@1";
import {
  affectedAccountIds,
  approvedProductIds,
  entitlementFromSubscriptions,
  GRACE_VERIFICATION_TTL_MS,
  type RevenueCatSnapshot,
  type RevenueCatSubscription,
  secretsMatch,
} from "./revenuecat.ts";
const user = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const now = Date.parse("2026-10-01T00:00:00Z");
const expiry = Date.parse("2026-11-01T00:00:00Z");
const policy = { productIds: ["lunch_pro_monthly", "lunch_pro_yearly"], allowSandbox: false };
function customer(overrides: Partial<RevenueCatSubscription> = {}): RevenueCatSnapshot {
  return {
    projectId: "proj_fixture",
    subscriptions: [{
      object: "subscription",
      id: "sub_monthly",
      customer_id: user,
      product_id: "prod_monthly",
      current_period_ends_at: expiry,
      ends_at: expiry,
      gives_access: true,
      status: "active",
      environment: "production",
      store: "app_store",
      entitlements: {
        object: "list",
        items: [{
          object: "entitlement",
          id: "ent_pro",
          project_id: "proj_fixture",
          lookup_key: "pro",
          state: "active",
        }],
        next_page: null,
      },
      ...overrides,
    }],
    products: [{
      object: "product",
      id: "prod_monthly",
      store_identifier: "lunch_pro_monthly",
      type: "subscription",
    }],
  };
}
function pro(snapshot: RevenueCatSnapshot, allowSandbox = false) {
  return entitlementFromSubscriptions(user, snapshot, now, { ...policy, allowSandbox });
}
Deno.test("an unconfigured catalogue remains free even with an active Apple Pro subscription", () => {
  for (const value of [undefined, "", " ,  , "]) {
    const productIds = approvedProductIds(value);
    assertEquals(productIds, []);
    assertEquals(
      entitlementFromSubscriptions(user, customer(), now, { productIds, allowSandbox: false })
        .is_pro,
      false,
    );
  }
  assertEquals(approvedProductIds(" lunch_pro_monthly, lunch_pro_yearly,lunch_pro_monthly, "), [
    "lunch_pro_monthly",
    "lunch_pro_yearly",
  ]);
});
Deno.test("v2 exact Pro entitlement and approved Apple product grant access", () => {
  assertEquals(pro(customer()), {
    app_user_id: user,
    is_pro: true,
    product_id: "lunch_pro_monthly",
    expires_at: new Date(expiry).toISOString(),
    environment: "PRODUCTION",
    source: "revenuecat",
  });
});
Deno.test("unknown products, unrelated or archived entitlements and other projects fail closed", () => {
  const noCustomer = customer();
  noCustomer.subscriptions = [];
  const noProduct = customer();
  noProduct.products = [];
  const wrongProduct = customer();
  wrongProduct.products[0].store_identifier = "unrelated";
  const oneTime = customer();
  oneTime.products[0].type = "one_time";
  const unrelated = customer();
  unrelated.subscriptions[0].entitlements.items[0].lookup_key = "other";
  const archived = customer();
  archived.subscriptions[0].entitlements.items[0].state = "inactive";
  const otherProject = customer();
  otherProject.subscriptions[0].entitlements.items[0].project_id = "proj_other";
  for (
    const value of [noCustomer, noProduct, wrongProduct, oneTime, unrelated, archived, otherProject]
  ) {
    assertEquals(pro(value).is_pro, false);
  }
});
Deno.test("Test Store, promotional and unqualified stores never unlock Apple Pro", () => {
  for (const store of ["test_store", "promotional", "play_store", "stripe"]) {
    assertEquals(pro(customer({ store }), true).is_pro, false);
  }
});
Deno.test("Apple sandbox requires explicit opt-in; unknown environment never grants", () => {
  assertEquals(pro(customer({ environment: "sandbox" })).is_pro, false);
  assertEquals(pro(customer({ environment: "sandbox" }), true).environment, "SANDBOX");
  assertEquals(pro(customer({ environment: "unknown" }), true).is_pro, false);
});
Deno.test("refunded or revoked subscriptions with future dates do not grant access", () => {
  for (const status of ["active", "expired", "in_grace_period", "in_billing_retry", "paused"]) {
    assertEquals(pro(customer({ gives_access: false, status })).is_pro, false);
  }
});
Deno.test("null, invalid and expired billing periods never become permanent Pro", () => {
  for (const end of [null, 0, -1, NaN, Infinity, 8.64e15 + 1, now, now - 1]) {
    assertEquals(pro(customer({ current_period_ends_at: end })).is_pro, false);
  }
});
Deno.test("grace access uses a bounded verification lease without inventing a grace end", () => {
  const row = pro(customer({ current_period_ends_at: now - 1000, status: "in_grace_period" }));
  assertEquals(row.is_pro, true);
  assertEquals(row.expires_at, new Date(now + GRACE_VERIFICATION_TTL_MS).toISOString());
  assertEquals(
    pro(customer({ status: "in_grace_period", current_period_ends_at: null })).is_pro,
    false,
  );
  assertEquals(
    pro(customer({ status: "in_grace_period", current_period_ends_at: now + 1000 })).expires_at,
    new Date(now + 1000).toISOString(),
  );
});
Deno.test("a queued renewal cannot extend the current product beyond its current period", () => {
  assertEquals(
    pro(customer({ ends_at: expiry + 31 * 86400000 })).expires_at,
    new Date(expiry).toISOString(),
  );
  assertEquals(pro(customer({ current_period_ends_at: now - 1, ends_at: expiry })).is_pro, false);
});
Deno.test("trials and future status names use the authoritative gives_access decision", () => {
  assertEquals(pro(customer({ status: "trialing" })).is_pro, true);
  assertEquals(pro(customer({ status: "future_access_granting_state" })).is_pro, true);
});
Deno.test("multiple subscriptions select longest access; production wins over sandbox", () => {
  const value = customer({ environment: "sandbox", current_period_ends_at: expiry + 10000 });
  value.subscriptions.push(
    ...customer({ id: "sub_other", current_period_ends_at: expiry - 1000 }).subscriptions,
  );
  assertEquals(pro(value, true).environment, "PRODUCTION");
  assertEquals(pro(value, true).expires_at, new Date(expiry - 1000).toISOString());
  value.subscriptions.reverse();
  assertEquals(pro(value, true).expires_at, new Date(expiry - 1000).toISOString());
  value.subscriptions[1].environment = "production";
  assertEquals(pro(value).expires_at, new Date(expiry + 10000).toISOString());
});
Deno.test("transfers reconcile both account IDs without copying a permanent source grant", () => {
  const other = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
  assertEquals(
    affectedAccountIds({
      type: "TRANSFER",
      transferred_from: [user, "$RCAnonymousID:guest"],
      transferred_to: [other],
      aliases: [user],
    }),
    [user, other],
  );
  assertEquals(pro({ projectId: "proj_fixture", subscriptions: [], products: [] }).is_pro, false);
});
Deno.test("webhook secrets compare exactly", () => {
  assertEquals(secretsMatch("abc", "abc"), true);
  assertEquals(secretsMatch("abc", "abd"), false);
  assertEquals(secretsMatch("ab", "abc"), false);
});
