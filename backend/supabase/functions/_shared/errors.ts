/**
 * @file errors.ts
 * @description JSON envelopes, error codes and CORS for every edge function.
 *   Errors always look like `{ "error": { "code", "message", ...extra } }`
 *   (API.md). `handle()` wraps a handler so OPTIONS, ApiError and unexpected
 *   exceptions all produce a consistent response.
 */

export const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-app-user-id, x-timezone, x-guest-token, x-client-info",
  "Access-Control-Max-Age": "86400",
};

/** Error codes. Subscription, quota and sign-in denials map to client gates. */
export const ErrorCode = {
  AI_DAILY_LIMIT: "AI_DAILY_LIMIT",
  HOST_REQUIRES_PRO: "HOST_REQUIRES_PRO",
  SIGN_IN_REQUIRED: "SIGN_IN_REQUIRED",
  BAD_REQUEST: "BAD_REQUEST",
  RATE_LIMITED: "RATE_LIMITED",
  AI_CONSENT_REQUIRED: "AI_CONSENT_REQUIRED",
  AI_UNAVAILABLE: "AI_UNAVAILABLE",
  UNAUTHORIZED: "UNAUTHORIZED",
  FORBIDDEN: "FORBIDDEN",
  NOT_FOUND: "NOT_FOUND",
  METHOD_NOT_ALLOWED: "METHOD_NOT_ALLOWED",
  UPSTREAM_ERROR: "UPSTREAM_ERROR",
  INTERNAL: "INTERNAL",
} as const;

export type ErrorCodeName = (typeof ErrorCode)[keyof typeof ErrorCode];

const DEFAULT_STATUS: Record<ErrorCodeName, number> = {
  AI_DAILY_LIMIT: 402,
  HOST_REQUIRES_PRO: 403,
  SIGN_IN_REQUIRED: 401,
  BAD_REQUEST: 400,
  RATE_LIMITED: 429,
  AI_CONSENT_REQUIRED: 403,
  AI_UNAVAILABLE: 503,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  METHOD_NOT_ALLOWED: 405,
  UPSTREAM_ERROR: 502,
  INTERNAL: 500,
};

/** Thrown anywhere in a handler; `handle()` turns it into the JSON envelope. */
export class ApiError extends Error {
  readonly code: ErrorCodeName;
  readonly status: number;
  readonly extra: Record<string, unknown>;

  constructor(code: ErrorCodeName, message: string, extra: Record<string, unknown> = {}) {
    super(message);
    this.name = "ApiError";
    this.code = code;
    this.status = DEFAULT_STATUS[code];
    this.extra = extra;
  }
}

export function badRequest(message: string): ApiError {
  return new ApiError(ErrorCode.BAD_REQUEST, message);
}

export function json(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json; charset=utf-8", ...headers },
  });
}

export function errorResponse(
  code: ErrorCodeName,
  message: string,
  extra: Record<string, unknown> = {},
  status = DEFAULT_STATUS[code],
): Response {
  return json({ error: { code, message, ...extra } }, status);
}

export type Handler = (req: Request) => Promise<Response>;

/**
 * Wraps a handler with CORS preflight, method checking and error mapping.
 * Unexpected exceptions are logged without the request body and returned as
 * a generic 500 so no internal detail leaks.
 */
export function handle(allowedMethods: string[], fn: Handler): Handler {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }
    if (!allowedMethods.includes(req.method)) {
      return errorResponse(
        ErrorCode.METHOD_NOT_ALLOWED,
        `Use ${allowedMethods.join(" or ")}`,
      );
    }
    try {
      return await fn(req);
    } catch (err: unknown) {
      if (err instanceof ApiError) {
        return errorResponse(err.code, err.message, err.extra, err.status);
      }
      const message = err instanceof Error ? err.message : String(err);
      console.error(`[${new URL(req.url).pathname}] unhandled: ${message}`);
      return errorResponse(ErrorCode.INTERNAL, "Something went wrong");
    }
  };
}

/** Default request body ceiling; large enough for every call except AI candidate lists. */
export const DEFAULT_BODY_LIMIT = 64 * 1024;
/** Ceiling for ai-recommend and groups-propose, whose bodies carry up to 20 restaurant candidates. */
export const AI_BODY_LIMIT = 256 * 1024;

/** Reads and parses a JSON body, returning 400 on syntax errors, non-objects or bodies over `maxBytes`. */
export async function readJsonObject(
  req: Request,
  maxBytes: number = DEFAULT_BODY_LIMIT,
): Promise<Record<string, unknown>> {
  if (Number(req.headers.get("content-length")) > maxBytes) {
    throw badRequest("Request body is too large");
  }
  const reader = req.body?.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  if (reader) {
    try {
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        size += value.byteLength;
        if (size > maxBytes) {
          await reader.cancel();
          throw badRequest("Request body is too large");
        }
        chunks.push(value);
      }
    } finally {
      reader.releaseLock();
    }
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    throw badRequest("Body must be valid JSON");
  }
  if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
    throw badRequest("Body must be a JSON object");
  }
  return parsed as Record<string, unknown>;
}
