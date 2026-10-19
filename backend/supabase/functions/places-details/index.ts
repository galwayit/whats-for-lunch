/**
 * @file places-details/index.ts
 * @description POST /places-details: fresh place details and attributed reviews; no persistent cache.
 */

import { reserveUpstream } from "../_shared/budget.ts";
import { ApiError, ErrorCode, handle, json, readJsonObject } from "../_shared/errors.ts";
import { mapPlace, mapReviews, placeDetailsRaw, PlacesError } from "../_shared/places.ts";
import { functionsBaseUrl, requireEnv, serviceClient } from "../_shared/supabase.ts";
import { nowEpochSeconds } from "../_shared/types.ts";
import { requirePlaceId } from "../_shared/validate.ts";

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const placeId = requirePlaceId(body, "placeId");
  const client = serviceClient();
  const now = nowEpochSeconds();

  const fetchedAt = now;
  let payload: unknown;
  try {
    await reserveUpstream(client, "places");
    payload = await placeDetailsRaw(placeId, requireEnv("GOOGLE_PLACES_API_KEY"));
  } catch (err: unknown) {
    if (err instanceof PlacesError && err.status === 404) {
      throw new ApiError(ErrorCode.NOT_FOUND, "Unknown place");
    }
    throw err;
  }

  const restaurant = mapPlace(payload, {
    origin: null,
    functionsBase: functionsBaseUrl(),
    nowEpochSeconds: fetchedAt,
  });
  if (!restaurant) throw new ApiError(ErrorCode.UPSTREAM_ERROR, "Place payload was incomplete");
  const reviews = mapReviews((payload as { reviews?: unknown }).reviews);
  restaurant.recentReviews = reviews;
  return json({ restaurant, reviews });
}));
