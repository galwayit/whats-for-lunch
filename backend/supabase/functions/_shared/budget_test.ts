import { assertEquals, assertMatch, assertRejects } from "jsr:@std/assert@1";
import { clientNetwork, reserveCaller } from "./budget.ts";
import { ApiError } from "./errors.ts";

type Call = { name: string; args: Record<string, unknown> };

/** `user` is the account the fictional JWT verifies as; null means the public key or no session. */
function fakeClient(user: string | null, allowed = true) {
  const calls: Call[] = [];
  const client = {
    auth: {
      getUser: () => {
        calls.push({ name: "auth.getUser", args: {} });
        return Promise.resolve(
          user
            ? { data: { user: { id: user, user_metadata: {}, identities: [] } }, error: null }
            : { data: { user: null }, error: { message: "invalid" } },
        );
      },
    },
    rpc: (name: string, args: Record<string, unknown>) => {
      calls.push({ name, args });
      return Promise.resolve({ data: allowed, error: null });
    },
  } as unknown as Parameters<typeof reserveCaller>[0];
  return { client, calls };
}

function request(headers: Record<string, string>): Request {
  return new Request("https://lunch.test/places-nearby", { headers });
}

const env = (values: Record<string, string> = {}) => (name: string) =>
  ({ SUPABASE_SERVICE_ROLE_KEY: "fictional-salt", SUPABASE_ANON_KEY: "public-key", ...values })[
    name
  ];

Deno.test("clientNetwork prefers the unforgeable header, groups an IPv6 range and rejects non-addresses", () => {
  assertEquals(
    clientNetwork(request({ "x-forwarded-for": "192.0.2.1", "cf-connecting-ip": "198.51.100.7" })),
    "198.51.100.7",
  );
  assertEquals(
    clientNetwork(request({ "x-forwarded-for": "203.0.113.9, 10.0.0.1" })),
    "203.0.113.9",
  );
  for (const forged of ["unknown", "203.0.113.9:5678", "[2001:db8::1]", ""]) {
    assertEquals(clientNetwork(request({ "x-forwarded-for": forged })), null);
  }
  assertEquals(
    clientNetwork(request({ "x-forwarded-for": "2001:DB8:1:2:aaaa:bbbb:cccc:dddd" })),
    clientNetwork(request({ "x-forwarded-for": "2001:db8:0001:2::1" })),
  );
  assertEquals(clientNetwork(request({ "x-forwarded-for": "2001:db8::1" })), "2001:db8:0:0");
  assertEquals(clientNetwork(request({ "x-forwarded-for": "::ffff:203.0.113.9" })), "203.0.113.9");
  assertEquals(clientNetwork(request({})), null);
});

Deno.test("a signed-in caller is limited by account, a guest by network, and neither is stored raw", async () => {
  const account = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
  const signedIn = fakeClient(account);
  for (const ip of ["203.0.113.9", "198.51.100.7"]) {
    await reserveCaller(
      signedIn.client,
      request({ authorization: "Bearer fictional-jwt", "x-forwarded-for": ip }),
      "places",
      2,
      env(),
    );
  }
  const guest = fakeClient(null);
  await reserveCaller(
    guest.client,
    request({ "x-forwarded-for": "203.0.113.9" }),
    "photos",
    1,
    env(),
  );

  assertEquals(signedIn.calls.map((c) => c.name), [
    "auth.getUser",
    "reserve_caller_request",
    "auth.getUser",
    "reserve_caller_request",
  ]);
  assertEquals(signedIn.calls[1].args, {
    p_provider: "places",
    p_caller_hash: signedIn.calls[3].args.p_caller_hash,
    p_limit: 200,
    p_requests: 2,
  });
  assertMatch(String(signedIn.calls[1].args.p_caller_hash), /^[a-f0-9]{64}$/);
  assertEquals(guest.calls[0].args.p_limit, 1000);
  assertEquals(guest.calls[0].args.p_requests, 1);
  assertMatch(String(guest.calls[0].args.p_caller_hash), /^[a-f0-9]{64}$/);
  assertEquals(guest.calls[0].args.p_caller_hash === signedIn.calls[1].args.p_caller_hash, false);
  assertEquals(JSON.stringify([signedIn.calls, guest.calls]).includes(account), false);
});

Deno.test("the caller hash depends on the server-side salt", async () => {
  const hashes: unknown[] = [];
  for (const salt of ["fictional-salt", "another-salt"]) {
    const { client, calls } = fakeClient(null);
    await reserveCaller(
      client,
      request({ "x-forwarded-for": "203.0.113.9" }),
      "places",
      1,
      env({ SUPABASE_SERVICE_ROLE_KEY: salt }),
    );
    hashes.push(calls[0].args.p_caller_hash);
  }
  assertEquals(hashes[0] === hashes[1], false);
});

Deno.test("an exhausted caller is rate limited and the check itself spends no global budget", async () => {
  const { client, calls } = fakeClient(null, false);
  // The public key as bearer is a signed-out caller: no Auth round trip, counted by address.
  const req = request({ authorization: "Bearer public-key", "x-forwarded-for": "203.0.113.9" });
  const error = await assertRejects(() => reserveCaller(client, req, "places", 2, env()), ApiError);
  assertEquals(error.code, "RATE_LIMITED");
  assertEquals(error.status, 429);
  assertEquals(calls.map((c) => c.name), ["reserve_caller_request"]);
});

Deno.test("per-caller limits are configurable and reject invalid configuration", async () => {
  const { client, calls } = fakeClient(null);
  const req = request({ "x-forwarded-for": "203.0.113.9" });
  await reserveCaller(client, req, "photos", 1, env({ PHOTOS_CALLER_DAILY_REQUEST_LIMIT: "50" }));
  assertEquals(calls[0].args.p_limit, 50);
  await assertRejects(
    () => reserveCaller(client, req, "places", 1, env({ PLACES_CALLER_DAILY_REQUEST_LIMIT: "0" })),
    Error,
    "Invalid upstream budget configuration",
  );
  await assertRejects(
    () => reserveCaller(client, req, "places", 1, () => undefined),
    Error,
    "SUPABASE_SERVICE_ROLE_KEY",
  );
  assertEquals(calls.length, 1);
});

Deno.test("a request without a caller address falls back to the global cap alone", async () => {
  const { client, calls } = fakeClient(null);
  await reserveCaller(client, request({}), "places", 1, env());
  assertEquals(calls.length, 0);
});
