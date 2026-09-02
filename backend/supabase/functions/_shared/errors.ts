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

/** Error codes. The first three are mapped to gates by the clients. */
export const ErrorCode = {
  AI_DAILY_LIMIT: "AI_DAILY_LIMIT",
  HOST_REQUIRES_PRO: "HOST_REQUIRES_PRO",
  SIGN_IN_REQUIRED: "SIGN_IN_REQUIRED",
  BAD_REQUEST: "BAD_REQUEST",
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

/** Reads and parses a JSON body, returning 400 on syntax errors or non-objects. */
export async function readJsonObject(req: Request): Promise<Record<string, unknown>> {
  let parsed: unknown;
  try {
    parsed = await req.json();
  } catch {
    throw badRequest("Body must be valid JSON");
  }
  if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
    throw badRequest("Body must be a JSON object");
  }
  return parsed as Record<string, unknown>;
}
