import { ApiError, ErrorCode } from "./errors.ts";
import { base64UrlEncode, pemToDer } from "./push.ts";

export interface AppleConfig {
  clientId: string;
  teamId: string;
  keyId: string;
  privateKey: string;
}

export function appleConfig(): AppleConfig {
  const read = (name: string): string => {
    const value = Deno.env.get(name)?.trim();
    if (!value) throw new Error(`${name} is not configured`);
    return value;
  };
  return {
    clientId: read("APPLE_CLIENT_ID"),
    teamId: read("APPLE_TEAM_ID"),
    keyId: read("APPLE_KEY_ID"),
    privateKey: read("APPLE_SIGN_IN_PRIVATE_KEY"),
  };
}

/** A short-lived client assertion; the private key never leaves the server. */
export async function appleClientSecret(
  config: AppleConfig,
  now = Math.floor(Date.now() / 1000),
): Promise<string> {
  const encode = (value: unknown) =>
    base64UrlEncode(new TextEncoder().encode(JSON.stringify(value)));
  const unsigned = `${encode({ alg: "ES256", kid: config.keyId })}.${
    encode({
      iss: config.teamId,
      sub: config.clientId,
      aud: "https://appleid.apple.com",
      iat: now,
      exp: now + 300,
    })
  }`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(config.privateKey),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;
}

/** Only for the ID token received directly from Apple's HTTPS token endpoint.
 * Never call this to authenticate an unverified token supplied by a client.
 */
export function validateAppleExchangeIdentity(
  idToken: string,
  subject: string,
  clientId: string,
  now = Date.now(),
): void {
  try {
    const payload = idToken.split(".")[1];
    const claims = JSON.parse(atob(payload.replace(/-/g, "+").replace(/_/g, "/")));
    if (
      claims.iss !== "https://appleid.apple.com" || claims.aud !== clientId ||
      claims.sub !== subject ||
      typeof claims.exp !== "number" || claims.exp * 1000 <= now
    ) throw new Error("identity mismatch");
  } catch {
    throw new ApiError(ErrorCode.FORBIDDEN, "Use the Apple account linked to your Lunch account.");
  }
}

/** Exchange a fresh native authorization code, verify its account, then revoke.
 * Apple tokens and codes are deliberately never persisted or logged.
 */
export async function revokeAppleAuthorization(
  code: string,
  subject: string,
  config: AppleConfig,
  fetchImpl: typeof fetch = fetch,
): Promise<void> {
  const credentials = {
    client_id: config.clientId,
    client_secret: await appleClientSecret(config),
  };
  const response = await fetchImpl("https://appleid.apple.com/auth/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ ...credentials, code, grant_type: "authorization_code" }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) {
    await response.body?.cancel();
    throw new ApiError(
      ErrorCode.UPSTREAM_ERROR,
      "Apple verification failed. Please try deleting your account again.",
    );
  }
  const tokens = await response.json();
  if (
    typeof tokens.id_token !== "string" || typeof tokens.refresh_token !== "string" ||
    !tokens.refresh_token
  ) {
    throw new ApiError(
      ErrorCode.UPSTREAM_ERROR,
      "Apple did not return the tokens needed to delete your account.",
    );
  }
  validateAppleExchangeIdentity(tokens.id_token, subject, config.clientId);
  const revoked = await fetchImpl("https://appleid.apple.com/auth/revoke", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      ...credentials,
      token: tokens.refresh_token,
      token_type_hint: "refresh_token",
    }),
    signal: AbortSignal.timeout(10_000),
  });
  await revoked.body?.cancel();
  if (!revoked.ok) {
    throw new ApiError(
      ErrorCode.UPSTREAM_ERROR,
      "Apple revocation failed. Your account has not been deleted.",
    );
  }
}
