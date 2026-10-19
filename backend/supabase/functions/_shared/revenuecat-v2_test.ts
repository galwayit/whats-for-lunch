import { assert, assertEquals, assertRejects, assertThrows } from "jsr:@std/assert@1";
import { ApiError } from "./errors.ts";
import { revenueCatReader } from "./revenuecat-v2.ts";
import { entitlementFromSubscriptions } from "./revenuecat.ts";
const user = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const base = "https://api.revenuecat.com/v2/projects/proj_fixture";
const config = {
  projectId: "proj_fixture",
  apiKey: "sk_fixture_not_a_real_key",
  allowSandbox: false,
};
const policy = { productIds: ["lunch_pro_monthly"], allowSandbox: false };
const now = Date.parse("2026-10-01T00:00:00Z");
const expiry = Date.parse("2026-11-01T00:00:00Z");
const ent = {
  object: "entitlement",
  id: "ent_pro",
  project_id: "proj_fixture",
  lookup_key: "pro",
  state: "active",
};
const product = {
  object: "product",
  id: "prod_monthly",
  store_identifier: "lunch_pro_monthly",
  type: "subscription",
};
function list(items: unknown[], next_page: string | null = null) {
  return { object: "list", items, next_page };
}
function sub(extra: Record<string, unknown> = {}) {
  return {
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
    entitlements: list([ent]),
    ...extra,
  };
}
function fake(handler: (url: URL) => Response | Promise<Response>): typeof fetch {
  return ((input: string | URL | Request, init?: RequestInit) => {
    assertEquals(init?.method, "GET");
    assertEquals(init?.redirect, "error");
    assertEquals(new Headers(init?.headers).get("Authorization"), `Bearer ${config.apiKey}`);
    assert(init?.signal);
    const url = new URL(String(input));
    assertEquals(url.origin, "https://api.revenuecat.com");
    return Promise.resolve(handler(url));
  }) as typeof fetch;
}
function json(value: unknown, status = 200) {
  return Response.json(value, { status });
}
Deno.test("v2 GET verifies configured project, product identifier and exact Pro entitlement", async () => {
  const calls: string[] = [];
  const read = revenueCatReader(
    config,
    fake((url) => {
      calls.push(url.href);
      return json(url.pathname.endsWith("/subscriptions") ? list([sub()]) : product);
    }),
  );
  assertEquals(entitlementFromSubscriptions(user, await read(user), now, policy).is_pro, true);
  assertEquals(calls, [
    `${base}/customers/${user}/subscriptions?limit=100&environment=production`,
    `${base}/products/prod_monthly`,
  ]);
});
Deno.test("subscription pagination preserves environment and finds Pro beyond page one", async () => {
  const calls: string[] = [];
  const read = revenueCatReader(
    config,
    fake((url) => {
      calls.push(url.href);
      if (url.pathname.includes("/products/")) return json(product);
      assertEquals(url.searchParams.get("environment"), "production");
      return json(
        url.searchParams.has("starting_after") ? list([sub()]) : list(
          [sub({ id: "sub_old", gives_access: false })],
          `/v2/projects/proj_fixture/customers/${user}/subscriptions?starting_after=sub_old`,
        ),
      );
    }),
  );
  assertEquals(entitlementFromSubscriptions(user, await read(user), now, policy).is_pro, true);
  assertEquals(calls.length, 3);
});
Deno.test("nested entitlement pages use subscription read scope", async () => {
  const read = revenueCatReader(
    config,
    fake((url) => {
      if (url.pathname.includes("/products/")) return json(product);
      if (url.pathname.endsWith("/entitlements")) return json(list([ent]));
      return json(
        list([
          sub({
            entitlements: list(
              [{ ...ent, id: "ent_other", lookup_key: "other" }],
              `${base}/subscriptions/sub_monthly/entitlements?status=active&starting_after=ent_other`,
            ),
          }),
        ]),
      );
    }),
  );
  assertEquals(entitlementFromSubscriptions(user, await read(user), now, policy).is_pro, true);
});
Deno.test("sandbox opt-in requests both environments but Test Store never grants", async () => {
  const read = revenueCatReader(
    { ...config, allowSandbox: true },
    fake((url) => {
      assertEquals(url.searchParams.has("environment"), false);
      assert(!url.pathname.includes("/products/"));
      return json(list([sub({ store: "test_store", environment: "sandbox" })]));
    }),
  );
  assertEquals(
    entitlementFromSubscriptions(user, await read(user), now, { ...policy, allowSandbox: true })
      .is_pro,
    false,
  );
});
Deno.test("unrelated and unqualified subscriptions need no product reads", async () => {
  const read = revenueCatReader(
    config,
    fake((url) => {
      assert(url.pathname.endsWith("/subscriptions"));
      return json(
        list([
          sub({ gives_access: false }),
          sub({ id: "sub_other", entitlements: list([{ ...ent, lookup_key: "other" }]) }),
          sub({ id: "sub_sandbox", environment: "sandbox" }),
          sub({ id: "sub_unknown", environment: "unknown" }),
        ]),
      );
    }),
  );
  assertEquals((await read(user)).products, []);
});
Deno.test("product reads are shared across transfer accounts", async () => {
  let count = 0;
  const read = revenueCatReader(
    config,
    fake((url) => {
      if (url.pathname.includes("/products/")) {
        count++;
        return json(product);
      }
      return json(list([sub()]));
    }),
  );
  await Promise.all([read(user), read("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")]);
  assertEquals(count, 1);
});
Deno.test("aliases are URL encoded; original_customer_id cannot redirect reads", async () => {
  const alias = "account/alias?value=secret#part";
  const read = revenueCatReader(
    config,
    fake((url) => {
      if (url.pathname.includes("/products/")) return json(product);
      assertEquals(
        url.pathname,
        `/v2/projects/proj_fixture/customers/${encodeURIComponent(alias)}/subscriptions`,
      );
      return json(list([sub({ customer_id: "canonical_id", original_customer_id: "old_owner" })]));
    }),
  );
  assertEquals(
    entitlementFromSubscriptions(alias, await read(alias), now, policy).app_user_id,
    alias,
  );
});
Deno.test("only recognized first-page missing customers map to no subscription", async () => {
  const read = revenueCatReader(
    config,
    fake(() => json({ type: "resource_missing", param: "customer_id" }, 404)),
  );
  assertEquals(await read(user), { projectId: config.projectId, subscriptions: [], products: [] });
  for (
    const error of [
      { type: "resource_missing", param: "project_id" },
      { type: "server_error" },
      null,
    ]
  ) {
    await assertRejects(
      () => revenueCatReader(config, fake(() => json(error, 404)))(user),
      ApiError,
    );
  }
});
Deno.test("permission, auth, rate limits, redirects and outages throw without revoking paid state", async () => {
  for (const status of [301, 401, 403, 429, 500, 503]) {
    await assertRejects(
      () => revenueCatReader(config, fake(() => new Response("private body", { status })))(user),
      ApiError,
      "Subscription verification is temporarily unavailable",
    );
  }
  const failing = (() => {
    throw new Error("transport contains private credentials");
  }) as typeof fetch;
  const error = await assertRejects(() => revenueCatReader(config, failing)(user), ApiError);
  assert(!error.message.includes("private credentials"));
});
Deno.test("malformed responses throw instead of clearing paid state", async () => {
  for (
    const body of [
      null,
      {},
      { object: "list", items: {} },
      list([null]),
      list([sub({ gives_access: "true" })]),
      list([sub({ current_period_ends_at: "2026-11-01" })]),
      list([sub({ entitlements: {} })]),
    ]
  ) {
    await assertRejects(() => revenueCatReader(config, fake(() => json(body)))(user), ApiError);
  }
  await assertRejects(
    () => revenueCatReader(config, fake(() => new Response("not json")))(user),
    ApiError,
  );
});
Deno.test("missing or mismatched products never yield a partial snapshot", async () => {
  for (
    const reply of [
      () => json({ type: "resource_missing" }, 404),
      () => json({ ...product, id: "prod_other" }),
      () => json({ ...product, store_identifier: null }),
    ]
  ) {
    await assertRejects(
      () =>
        revenueCatReader(
          config,
          fake((url) => url.pathname.endsWith("/subscriptions") ? json(list([sub()])) : reply()),
        )(user),
      ApiError,
    );
  }
});
Deno.test("pagination cannot leak credentials to another origin, customer, project or URL credentials", async () => {
  for (
    const next of [
      "https://attacker.invalid/steal?starting_after=sub_old",
      `${base}/customers/other/subscriptions?starting_after=sub_old`,
      `${
        base.replace("proj_fixture", "proj_other")
      }/customers/${user}/subscriptions?starting_after=sub_old`,
      `https://user:pass@api.revenuecat.com/v2/projects/proj_fixture/customers/${user}/subscriptions?starting_after=sub_old`,
      `${base}/customers/${user}/subscriptions#fragment`,
      `${base}/customers/${user}/subscriptions?limit=100`,
    ]
  ) {
    let count = 0;
    const read = revenueCatReader(
      config,
      fake(() => {
        count++;
        return json(list([], next));
      }),
    );
    await assertRejects(() => read(user), ApiError);
    assertEquals(count, 1);
  }
});
Deno.test("looping, failing and excessive pages never return incomplete data", async () => {
  let count = 0;
  const looping = revenueCatReader(
    config,
    fake(() => {
      count++;
      return json(list([], `${base}/customers/${user}/subscriptions?starting_after=repeat`));
    }),
  );
  await assertRejects(() => looping(user), ApiError);
  assertEquals(count, 2);
  count = 0;
  const endless = revenueCatReader(
    config,
    fake(() =>
      json(list([], `${base}/customers/${user}/subscriptions?starting_after=cursor${count++}`))
    ),
  );
  await assertRejects(() => endless(user), ApiError);
  assertEquals(count, 10);
  count = 0;
  const missingLater = revenueCatReader(
    config,
    fake(() =>
      count++ === 0
        ? json(list([], `${base}/customers/${user}/subscriptions?starting_after=last`))
        : json({ type: "resource_missing" }, 404)
    ),
  );
  await assertRejects(() => missingLater(user), ApiError);
});
Deno.test("invalid project IDs fail before transmitting credentials", () => {
  for (const projectId of ["", "66f64377", "proj", "../other", "project?key=value"]) {
    assertThrows(() => revenueCatReader({ ...config, projectId }));
  }
});
