/**
 * @file nearby.ts
 * @description Fresh nearby search. Places content is not persisted. Shared by
 *   places-nearby and groups-propose so both hit the same cache cells.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { reserveUpstream } from "./budget.ts";
import { haversineKm, roundKm } from "./haversine.ts";
import { mapPlace, searchNearbyRaw } from "./places.ts";
import { nowEpochSeconds, type Restaurant } from "./types.ts";

export const PLACES_CACHE_TTL_SECONDS = 24 * 60 * 60;

export interface NearbyRequest {
  lat: number;
  lng: number;
  radiusKm: number;
  query: string;
}

export interface NearbyResult {
  restaurants: Restaurant[];
  cached: boolean;
  fetchedAt: number;
}

export interface NearbyDeps {
  client: SupabaseClient;
  apiKey: string;
  functionsBase: string;
  fetchImpl?: typeof fetch;
}

/** Radius is rounded to 0.5 km so nearby requests share cache rows. */
export function cacheRadius(radiusKm: number): number {
  return Math.round(radiusKm * 2) / 2;
}

/**
 * Fetches current Places content for the user request. Persist only place IDs.
 */
export async function nearbyRestaurants(
  req: NearbyRequest,
  deps: NearbyDeps,
): Promise<NearbyResult> {
  const fetchedAt = nowEpochSeconds();
  await reserveUpstream(deps.client, "places");
  const places = await searchNearbyRaw(req, deps.apiKey, deps.fetchImpl ?? fetch);
  const cached = false;

  const restaurants = places
    .map((p) =>
      mapPlace(p, {
        origin: { lat: req.lat, lng: req.lng },
        functionsBase: deps.functionsBase,
        nowEpochSeconds: fetchedAt,
      })
    )
    .filter((r): r is Restaurant => r !== null)
    .filter((r) => r.distanceFromUser === null || r.distanceFromUser <= req.radiusKm + 0.5);

  for (const r of restaurants) {
    if (r.latitude !== null && r.longitude !== null) {
      r.distanceFromUser = roundKm(haversineKm(req.lat, req.lng, r.latitude, r.longitude));
    }
  }
  return { restaurants, cached, fetchedAt };
}
