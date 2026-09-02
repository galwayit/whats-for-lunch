/**
 * @file places-details/index.ts
 * @description POST /places-details: place details + reviews, cached 24 h.
 */

import { ApiError, ErrorCode, handle, json, readJsonObject } from "../_shared/errors.ts";
import { mapPlace, mapReviews, placeDetailsRaw, PlacesError } from "../_shared/places.ts";
import { functionsBaseUrl, requireEnv, serviceClient } from "../_shared/supabase.ts";
import { nowEpochSeconds, toEpochSeconds } from "../_shared/types.ts";
import { requirePlaceId } from "../_shared/validate.ts";

const TTL_SECONDS = 24 * 60 * 60;

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const placeId = requirePlaceId(body, "placeId");
  const client = serviceClient();
  const now = nowEpochSeconds();

  const { data: hit, error } = await client
    .from("place_details_cache")
    .select("payload, fetched_at")
    .eq("place_id", placeId)
    .maybeSingle();
  if (error) throw new Error(`database: ${error.message}`);

  let payload: unknown;
  let fetchedAt = now;
  if (hit && now - toEpochSeconds(hit.fetched_at) < TTL_SECONDS) {
    payload = hit.payload;
    fetchedAt = toEpochSeconds(hit.fetched_at);
  } else {
    try {
      payload = await placeDetailsRaw(placeId, requireEnv("GOOGLE_PLACES_API_KEY"));
    } catch (err: unknown) {
      if (err instanceof PlacesError && err.status === 404) {
        throw new ApiError(ErrorCode.NOT_FOUND, "Unknown place");
      }
      throw err;
    }
    const { error: upsertError } = await client.from("place_details_cache").upsert({
      place_id: placeId,
      payload,
      fetched_at: new Date(now * 1000).toISOString(),
    });
    if (upsertError) console.warn(`place_details_cache upsert failed: ${upsertError.message}`);
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
