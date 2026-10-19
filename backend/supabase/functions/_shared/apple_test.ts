import { assertEquals, assertRejects, assertThrows } from "jsr:@std/assert@1";
import {
  appleClientSecret,
  revokeAppleAuthorization,
  validateAppleExchangeIdentity,
} from "./apple.ts";
import { base64UrlEncode } from "./push.ts";

const encode = (value: unknown) => base64UrlEncode(new TextEncoder().encode(JSON.stringify(value)));
const claims = {
  iss: "https://appleid.apple.com",
  aud: "au.iapp.lunch",
  sub: "apple-user",
  exp: 2_000_000_000,
};
const token = (overrides = {}) =>
  `${encode({ alg: "RS256" })}.${encode({ ...claims, ...overrides })}.fixture`;
Deno.test("Apple exchange must belong to the signed-in account and native bundle", () => {
  validateAppleExchangeIdentity(token(), "apple-user", "au.iapp.lunch", 1_000);
  for (
    const bad of [{ sub: "other-user" }, { aud: "other-app" }, { iss: "https://attacker.test" }, {
      exp: 0,
    }]
  ) {
    assertThrows(() =>
      validateAppleExchangeIdentity(token(bad), "apple-user", "au.iapp.lunch", 1_000)
    );
  }
});

async function fixtureConfig() {
  const key = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, [
    "sign",
    "verify",
  ]);
  const der = new Uint8Array(await crypto.subtle.exportKey("pkcs8", key.privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${
    btoa(String.fromCharCode(...der))
  }\n-----END PRIVATE KEY-----`;
  return {
    key,
    config: {
      clientId: "au.iapp.lunch",
      teamId: "fixture-team",
      keyId: "fixture-key",
      privateKey: pem,
    },
  };
}
Deno.test("Apple client assertion uses a valid ES256 signature and a five minute lifetime", async () => {
  const { key, config } = await fixtureConfig();
  const jwt = await appleClientSecret(config, 1000);
  const [header, body, signature] = jwt.split(".");
  const payload = JSON.parse(atob(body));
  assertEquals(payload.exp - payload.iat, 300);
  const bytes = Uint8Array.from(
    atob(signature.replace(/-/g, "+").replace(/_/g, "/")),
    (c) => c.charCodeAt(0),
  );
  assertEquals(
    await crypto.subtle.verify(
      { name: "ECDSA", hash: "SHA-256" },
      key.publicKey,
      bytes,
      new TextEncoder().encode(`${header}.${body}`),
    ),
    true,
  );
});
Deno.test("Apple revocation only happens after a verified same-account code exchange", async () => {
  const { config } = await fixtureConfig();
  const urls: string[] = [];
  const fake = (async (url: string | URL | Request, init?: RequestInit) => {
    urls.push(String(url));
    if (String(url).endsWith("/token")) {
      return Response.json({ id_token: token(), refresh_token: "fixture-refresh" });
    }
    assertEquals(new URLSearchParams(String(init?.body)).get("token"), "fixture-refresh");
    return new Response(null, { status: 200 });
  }) as typeof fetch;
  await revokeAppleAuthorization("fixture-code", "apple-user", config, fake);
  assertEquals(urls.length, 2);
  urls.length = 0;
  await assertRejects(() => revokeAppleAuthorization("fixture-code", "wrong-user", config, fake));
  assertEquals(urls.length, 1);
});
