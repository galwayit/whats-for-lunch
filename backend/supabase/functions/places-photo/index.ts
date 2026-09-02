/**
 * @file places-photo/index.ts
 * @description GET /places-photo?name=places/../photos/..&maxWidth=800.
 *   Proxies the photo media endpoint so the API key never reaches clients.
 */

import { ApiError, badRequest, CORS_HEADERS, ErrorCode, handle } from "../_shared/errors.ts";
import { fetchPhoto } from "../_shared/places.ts";
import { requireEnv } from "../_shared/supabase.ts";

const PHOTO_NAME = /^places\/[A-Za-z0-9_-]+\/photos\/[A-Za-z0-9_-]+$/;

Deno.serve(handle(["GET"], async (req) => {
  const url = new URL(req.url);
  const name = url.searchParams.get("name") ?? "";
  if (!PHOTO_NAME.test(name)) throw badRequest("name must look like places/<id>/photos/<id>");
  const requested = Number(url.searchParams.get("maxWidth") ?? "800");
  const maxWidth = Number.isInteger(requested) ? Math.min(1600, Math.max(64, requested)) : 800;

  const upstream = await fetchPhoto(name, maxWidth, requireEnv("GOOGLE_PLACES_API_KEY"));
  if (!upstream.ok) {
    await upstream.body?.cancel();
    if (upstream.status === 404) throw new ApiError(ErrorCode.NOT_FOUND, "Photo not found");
    throw new ApiError(ErrorCode.UPSTREAM_ERROR, `Photo upstream responded ${upstream.status}`);
  }
  return new Response(upstream.body, {
    status: 200,
    headers: {
      ...CORS_HEADERS,
      "Content-Type": upstream.headers.get("Content-Type") ?? "image/jpeg",
      "Cache-Control": "public, max-age=86400, s-maxage=604800",
    },
  });
}));
