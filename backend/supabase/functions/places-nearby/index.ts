/**
 * @file places-nearby/index.ts
 * @description POST /places-nearby: cached restaurant search around a point.
 */

import { handle, json, readJsonObject } from "../_shared/errors.ts";
import { nearbyRestaurants } from "../_shared/nearby.ts";
import { applyFilters, normaliseQuery } from "../_shared/places.ts";
import { functionsBaseUrl, requireEnv, serviceClient } from "../_shared/supabase.ts";
import { optionalNumber, requireNumber } from "../_shared/validate.ts";

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const lat = requireNumber(body, "lat", -90, 90);
  const lng = requireNumber(body, "lng", -180, 180);
  const radiusKm = requireNumber(body, "radiusKm", 0.1, 50);
  const maxPrice = optionalNumber(body, "maxPrice", 1, 4);
  const minRating = optionalNumber(body, "minRating", 0, 5);
  const query = normaliseQuery(body.query);

  const result = await nearbyRestaurants({ lat, lng, radiusKm, query }, {
    client: serviceClient(),
    apiKey: requireEnv("GOOGLE_PLACES_API_KEY"),
    functionsBase: functionsBaseUrl(),
  });

  return json({
    restaurants: applyFilters(result.restaurants, maxPrice, minRating),
    cached: result.cached,
    fetchedAt: result.fetchedAt,
  });
}));
