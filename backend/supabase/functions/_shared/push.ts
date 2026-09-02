/**
 * @file push.ts
 * @description FCM HTTP v1 sender with no external libraries. The service
 *   account JSON (secret FCM_SERVICE_ACCOUNT_JSON) is used to mint a
 *   short-lived OAuth2 access token via a Web Crypto RS256 JWT; the token is
 *   cached in module scope for its lifetime.
 */

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

export interface PushMessage {
  /** Data payload; every value must be a string for FCM. */
  data: Record<string, string>;
  notification?: { title: string; body: string };
}

export interface PushOutcome {
  token: string;
  ok: boolean;
  /** True when FCM reported the token as no longer registered. */
  stale: boolean;
}

const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const DEFAULT_TOKEN_URI = "https://oauth2.googleapis.com/token";

/** Parses and validates the secret. Throws on a malformed value. */
export function parseServiceAccount(raw: string | undefined): ServiceAccount {
  if (!raw) throw new Error("FCM_SERVICE_ACCOUNT_JSON is not set");
  // deno-lint-ignore no-explicit-any
  let parsed: any;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error("FCM_SERVICE_ACCOUNT_JSON is not valid JSON");
  }
  for (const key of ["project_id", "client_email", "private_key"]) {
    if (typeof parsed?.[key] !== "string" || parsed[key].length === 0) {
      throw new Error(`FCM_SERVICE_ACCOUNT_JSON is missing ${key}`);
    }
  }
  return {
    project_id: parsed.project_id,
    client_email: parsed.client_email,
    private_key: parsed.private_key,
    token_uri: typeof parsed.token_uri === "string" ? parsed.token_uri : DEFAULT_TOKEN_URI,
  };
}

export function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** PEM (PKCS#8) -> DER bytes for `crypto.subtle.importKey`. */
export function pemToDer(pem: string): Uint8Array<ArrayBuffer> {
  const body = pem
    .replace(/-----BEGIN [A-Z ]+-----/, "")
    .replace(/-----END [A-Z ]+-----/, "")
    .replace(/\s+/g, "");
  const binary = atob(body);
  const bytes = new Uint8Array(new ArrayBuffer(binary.length));
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** Builds and signs the OAuth2 JWT assertion (RS256). */
export async function signServiceAccountJwt(
  account: ServiceAccount,
  nowSeconds = Math.floor(Date.now() / 1000),
): Promise<string> {
  const encoder = new TextEncoder();
  const header = base64UrlEncode(encoder.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claims = base64UrlEncode(encoder.encode(JSON.stringify({
    iss: account.client_email,
    scope: SCOPE,
    aud: account.token_uri ?? DEFAULT_TOKEN_URI,
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  })));
  const unsigned = `${header}.${claims}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(unsigned),
  );
  return `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;
}

let cachedToken: { value: string; expiresAtMs: number } | null = null;

async function accessToken(account: ServiceAccount, fetchImpl: typeof fetch): Promise<string> {
  if (cachedToken && cachedToken.expiresAtMs > Date.now() + 60_000) return cachedToken.value;
  const assertion = await signServiceAccountJwt(account);
  const response = await fetchImpl(account.token_uri ?? DEFAULT_TOKEN_URI, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) {
    await response.body?.cancel();
    throw new Error(`OAuth token exchange failed with ${response.status}`);
  }
  const payload = await response.json() as { access_token?: string; expires_in?: number };
  if (typeof payload.access_token !== "string") throw new Error("OAuth response had no token");
  cachedToken = {
    value: payload.access_token,
    expiresAtMs: Date.now() + (payload.expires_in ?? 3600) * 1000,
  };
  return cachedToken.value;
}

/** Sends one message to one device token. Never throws; see PushOutcome. */
export async function sendPush(
  account: ServiceAccount,
  token: string,
  message: PushMessage,
  fetchImpl: typeof fetch = fetch,
): Promise<PushOutcome> {
  try {
    const bearer = await accessToken(account, fetchImpl);
    const response = await fetchImpl(
      `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${bearer}` },
        body: JSON.stringify({
          message: {
            token,
            data: message.data,
            notification: message.notification,
            android: { priority: "high" },
            apns: { headers: { "apns-priority": "10" } },
          },
        }),
      },
    );
    if (response.ok) {
      await response.body?.cancel();
      return { token, ok: true, stale: false };
    }
    const text = await response.text();
    const stale = response.status === 404 || text.includes("UNREGISTERED");
    console.warn(`FCM send failed: status=${response.status} stale=${stale}`);
    return { token, ok: false, stale };
  } catch (err: unknown) {
    console.warn(`FCM send error: ${err instanceof Error ? err.message : String(err)}`);
    return { token, ok: false, stale: false };
  }
}

/** Fan-out to many tokens; returns the tokens FCM says are gone. */
export async function sendPushToAll(
  account: ServiceAccount,
  tokens: string[],
  message: PushMessage,
  fetchImpl: typeof fetch = fetch,
): Promise<{ sent: number; staleTokens: string[] }> {
  const unique = [...new Set(tokens)];
  const outcomes = await Promise.all(unique.map((t) => sendPush(account, t, message, fetchImpl)));
  return {
    sent: outcomes.filter((o) => o.ok).length,
    staleTokens: outcomes.filter((o) => o.stale).map((o) => o.token),
  };
}
