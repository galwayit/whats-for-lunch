/**
 * @file nearby.ts
 * @description Nearby search backed by `places_cache` (24 h TTL). Shared by
 *   places-nearby and groups-propose so both hit the same cache cells.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { geohashEncode } from "./geohash.ts";
import { haversineKm, roundKm } from "./haversine.ts";
import { mapPlace, searchNearbyRaw } from "./places.ts";
import { nowEpochSeconds, type Restaurant, toEpochSeconds } from "./types.ts";

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
 * Returns restaurants for the request, from cache when fresh. The cached
 * payload holds raw Place resources so distance is always recomputed from
 * the caller's exact point.
 */
export async function nearbyRestaurants(
  req: NearbyRequest,
  deps: NearbyDeps,
): Promise<NearbyResult> {
  const cell = geohashEncode(req.lat, req.lng);
  const radius = cacheRadius(req.radiusKm);
  const now = nowEpochSeconds();

  const { data: hit, error } = await deps.client
    .from("places_cache")
    .select("payload, fetched_at")
    .eq("cell", cell)
    .eq("radius_km", radius)
    .eq("query", req.query)
    .maybeSingle();
  if (error) throw new Error(`database: ${error.message}`);

  let places: unknown[];
  let cached = false;
  let fetchedAt = now;
  if (
    hit && now - toEpochSeconds(hit.fetched_at) < PLACES_CACHE_TTL_SECONDS &&
    Array.isArray(hit.payload)
  ) {
    places = hit.payload;
    cached = true;
    fetchedAt = toEpochSeconds(hit.fetched_at);
  } else {
    places = await searchNearbyRaw(
      { lat: req.lat, lng: req.lng, radiusKm: req.radiusKm, query: req.query },
      deps.apiKey,
      deps.fetchImpl ?? fetch,
    );
    const { error: upsertError } = await deps.client.from("places_cache").upsert({
      cell,
      radius_km: radius,
      query: req.query,
      payload: places,
      fetched_at: new Date(now * 1000).toISOString(),
    });
    if (upsertError) console.warn(`places_cache upsert failed: ${upsertError.message}`);
  }

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
