import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { base64UrlEncode, parseServiceAccount, pemToDer, signServiceAccountJwt } from "./push.ts";

Deno.test("base64UrlEncode uses the URL alphabet without padding", () => {
  assertEquals(base64UrlEncode(new TextEncoder().encode("hi?")), "aGk_");
  assertEquals(base64UrlEncode(new Uint8Array([251, 255])), "-_8");
});

Deno.test("pemToDer strips armour and whitespace", () => {
  const der = pemToDer("-----BEGIN PRIVATE KEY-----\nAQID\nBA==\n-----END PRIVATE KEY-----\n");
  assertEquals(Array.from(der), [1, 2, 3, 4]);
});

Deno.test("parseServiceAccount validates the secret shape without echoing it", () => {
  assertThrows(() => parseServiceAccount(undefined), Error, "not set");
  assertThrows(() => parseServiceAccount("{"), Error, "valid JSON");
  assertThrows(
    () => parseServiceAccount(JSON.stringify({ project_id: "p" })),
    Error,
    "client_email",
  );
  const ok = parseServiceAccount(
    JSON.stringify({ project_id: "p", client_email: "e", private_key: "k" }),
  );
  assertEquals(ok.token_uri, "https://oauth2.googleapis.com/token");
});

Deno.test("signServiceAccountJwt produces a verifiable RS256 token", async () => {
  const pair = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${
    btoa(String.fromCharCode(...pkcs8))
  }\n-----END PRIVATE KEY-----`;
  const jwt = await signServiceAccountJwt(
    { project_id: "p", client_email: "svc@p.iam.gserviceaccount.com", private_key: pem },
    1_725_250_000,
  );
  const [header, claims, signature] = jwt.split(".");
  const decode = (s: string) => JSON.parse(atob(s.replace(/-/g, "+").replace(/_/g, "/")));
  assertEquals(decode(header), { alg: "RS256", typ: "JWT" });
  assertEquals(decode(claims).iss, "svc@p.iam.gserviceaccount.com");
  assertEquals(decode(claims).exp, 1_725_250_000 + 3600);
  const sigBytes = Uint8Array.from(
    atob(signature.replace(/-/g, "+").replace(/_/g, "/")),
    (c) => c.charCodeAt(0),
  );
  const valid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    pair.publicKey,
    sigBytes,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  assertEquals(valid, true);
});
