/**
 * @file places.ts
 * @description Places API (New) calls and the mapping from a Place resource to
 *   the Restaurant JSON. Cuisine and feature derivation from `types`
 *   reproduces `_extractCuisineTypes` / `_extractFeatures` of the legacy
 *   Flutter repository, adapted to the New API type names
 *   (e.g. `italian_restaurant` -> "Italian").
 */

import { haversineKm, roundKm } from "./haversine.ts";
import type { Restaurant, RestaurantReview } from "./types.ts";

const PLACES_BASE = "https://places.googleapis.com/v1";

export const NEARBY_FIELD_MASK = [
  "places.id",
  "places.displayName",
  "places.formattedAddress",
  "places.location",
  "places.rating",
  "places.userRatingCount",
  "places.priceLevel",
  "places.types",
  "places.photos",
  "places.currentOpeningHours.openNow",
].join(",");

export const DETAILS_FIELD_MASK = [
  "id",
  "displayName",
  "formattedAddress",
  "internationalPhoneNumber",
  "websiteUri",
  "location",
  "rating",
  "userRatingCount",
  "priceLevel",
  "types",
  "photos",
  "currentOpeningHours",
  "reviews",
].join(",");

/** Same labels as the legacy Flutter map, keyed by the bare cuisine word. */
const CUISINE_LABELS: Record<string, string> = {
  italian: "Italian",
  chinese: "Chinese",
  japanese: "Japanese",
  mexican: "Mexican",
  indian: "Indian",
  thai: "Thai",
  french: "French",
  american: "American",
  mediterranean: "Mediterranean",
  korean: "Korean",
  vietnamese: "Vietnamese",
  seafood: "Seafood",
  steakhouse: "Steakhouse",
  steak_house: "Steakhouse",
  pizza: "Pizza",
  burger: "Burgers",
  hamburger: "Burgers",
  sushi: "Sushi",
  bakery: "Bakery",
  cafe: "Cafe",
  coffee_shop: "Cafe",
  fast_food: "Fast Food",
  fine_dining: "Fine Dining",
};

/** Places API (New) `priceLevel` enum -> 1..4 (dollar signs). */
const PRICE_LEVELS: Record<string, number> = {
  PRICE_LEVEL_INEXPENSIVE: 1,
  PRICE_LEVEL_MODERATE: 2,
  PRICE_LEVEL_EXPENSIVE: 3,
  PRICE_LEVEL_VERY_EXPENSIVE: 4,
};

/**
 * `_extractCuisineTypes` for New API types: strips a `_restaurant` suffix,
 * looks the word up, de-duplicates, and falls back to "Restaurant"/"Food".
 */
export function extractCuisineTypes(types: string[]): string[] {
  const cuisines: string[] = [];
  for (const type of types) {
    const key = type.toLowerCase().replace(/_restaurant$/, "");
    const label = CUISINE_LABELS[key];
    if (label && !cuisines.includes(label)) cuisines.push(label);
  }
  if (cuisines.length === 0) {
    if (types.includes("restaurant")) cuisines.push("Restaurant");
    else if (types.includes("food")) cuisines.push("Food");
  }
  return cuisines;
}

/** `_extractFeatures`: identical type names, same output order. */
export function extractFeatures(types: string[]): string[] {
  const features: string[] = [];
  if (types.includes("meal_delivery")) features.push("delivery");
  if (types.includes("meal_takeaway")) features.push("takeout");
  if (types.includes("dine_in")) features.push("dine_in");
  if (types.includes("wheelchair_accessible")) features.push("wheelchair_accessible");
  if (types.includes("outdoor_seating")) features.push("outdoor_seating");
  if (types.includes("wifi")) features.push("wifi");
  return features;
}

/** Proxy URL for a photo resource name via the places-photo function. */
export function photoProxyUrl(photoName: string, functionsBase: string, maxWidth = 800): string {
  const base = functionsBase.endsWith("/") ? functionsBase.slice(0, -1) : functionsBase;
  return `${base}/places-photo?name=${encodeURIComponent(photoName)}&maxWidth=${maxWidth}`;
}

export interface MapOptions {
  /** Request point; when present `distanceFromUser` is computed. */
  origin: { lat: number; lng: number } | null;
  /** e.g. https://<ref>.supabase.co/functions/v1 */
  functionsBase: string;
  nowEpochSeconds: number;
}

/**
 * Maps one Place resource to a Restaurant. Returns null when the id or name
 * is missing, mirroring the legacy parser.
 */
// `any` at the JSON boundary: the Places response is validated field by field.
// deno-lint-ignore no-explicit-any
export function mapPlace(place: any, options: MapOptions): Restaurant | null {
  if (typeof place !== "object" || place === null) return null;
  const placeId: unknown = place.id;
  const name: unknown = place.displayName?.text;
  if (typeof placeId !== "string" || typeof name !== "string") return null;

  const lat = optionalNumber(place.location?.latitude);
  const lng = optionalNumber(place.location?.longitude);
  const types: string[] = Array.isArray(place.types)
    ? place.types.filter((t: unknown): t is string => typeof t === "string")
    : [];
  const photoNames: string[] = Array.isArray(place.photos)
    ? place.photos.map((p: unknown) => (p as { name?: unknown })?.name).filter((
      n: unknown,
    ): n is string => typeof n === "string")
    : [];
  const priceLevel = typeof place.priceLevel === "string"
    ? PRICE_LEVELS[place.priceLevel] ?? null
    : null;
  const cuisineTypes = extractCuisineTypes(types);
  const address = typeof place.formattedAddress === "string" ? place.formattedAddress : null;
  const weekday: unknown = place.currentOpeningHours?.weekdayDescriptions;

  let distance: number | null = null;
  if (options.origin && lat !== null && lng !== null) {
    distance = roundKm(haversineKm(options.origin.lat, options.origin.lng, lat, lng));
  }

  return {
    placeId,
    name,
    location: address ?? "Unknown location",
    address,
    phoneNumber: typeof place.internationalPhoneNumber === "string"
      ? place.internationalPhoneNumber
      : null,
    website: typeof place.websiteUri === "string" ? place.websiteUri : null,
    latitude: lat,
    longitude: lng,
    distanceFromUser: distance,
    rating: optionalNumber(place.rating),
    reviewCount: optionalNumber(place.userRatingCount),
    priceLevel,
    priceRanges: priceLevel !== null ? ["$".repeat(priceLevel)] : [],
    cuisineType: cuisineTypes[0] ?? null,
    cuisineTypes,
    supportedDietaryRestrictions: [],
    allergenInfo: [],
    dietaryCompatibilityScores: {},
    hasVerifiedDietaryInfo: false,
    communityVerificationCount: 0,
    openingHours: Array.isArray(weekday)
      ? weekday.filter((d: unknown): d is string => typeof d === "string")
      : [],
    isOpenNow: place.currentOpeningHours?.openNow === true,
    currentWaitTime: null,
    features: extractFeatures(types),
    averageMealCost: null,
    valueScore: null,
    mealTypeAverageCosts: {},
    recentReviews: [],
    cachedAtEpochSeconds: options.nowEpochSeconds,
    lastVerifiedEpochSeconds: null,
    photoReference: photoNames[0] ?? null,
    photoReferences: photoNames,
    photoUrl: photoNames[0] ? photoProxyUrl(photoNames[0], options.functionsBase) : null,
  };
}

/** Maps the `reviews` array of a Place details resource. */
// deno-lint-ignore no-explicit-any
export function mapReviews(reviews: any): RestaurantReview[] {
  if (!Array.isArray(reviews)) return [];
  const out: RestaurantReview[] = [];
  for (const r of reviews) {
    if (typeof r !== "object" || r === null || typeof r.name !== "string") continue;
    const publishTime = typeof r.publishTime === "string" ? Date.parse(r.publishTime) : NaN;
    out.push({
      reviewId: r.name,
      authorName: typeof r.authorAttribution?.displayName === "string"
        ? r.authorAttribution.displayName
        : "Anonymous",
      authorPhotoUrl: typeof r.authorAttribution?.photoUri === "string"
        ? r.authorAttribution.photoUri
        : null,
      rating: typeof r.rating === "number" ? Math.round(r.rating) : 0,
      text: typeof r.text?.text === "string" ? r.text.text : null,
      timeEpochSeconds: Number.isFinite(publishTime) ? Math.floor(publishTime / 1000) : 0,
      relativeTimeDescription: typeof r.relativePublishTimeDescription === "string"
        ? r.relativePublishTimeDescription
        : "",
    });
  }
  return out;
}

function optionalNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

/* ---------- Network calls ---------- */

export class PlacesError extends Error {
  readonly status: number;
  constructor(status: number, message: string) {
    super(message);
    this.name = "PlacesError";
    this.status = status;
  }
}

export interface NearbyParams {
  lat: number;
  lng: number;
  radiusKm: number;
  /** Normalised query; when non-empty `places:searchText` is used instead. */
  query: string;
}

async function placesPost(
  path: string,
  body: unknown,
  fieldMask: string,
  apiKey: string,
  fetchImpl: typeof fetch,
): Promise<unknown> {
  const response = await fetchImpl(`${PLACES_BASE}/${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": apiKey,
      "X-Goog-FieldMask": fieldMask,
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    await response.body?.cancel();
    throw new PlacesError(response.status, `Places API responded ${response.status}`);
  }
  return await response.json();
}

/**
 * Raw Place resources near a point. Without a query this is `searchNearby`
 * restricted to restaurants; with a query it is `searchText` biased to the
 * same circle, because searchNearby has no text filter.
 */
export async function searchNearbyRaw(
  params: NearbyParams,
  apiKey: string,
  fetchImpl: typeof fetch = fetch,
): Promise<unknown[]> {
  const radiusMetres = Math.min(50_000, Math.max(1, Math.round(params.radiusKm * 1000)));
  const circle = {
    center: { latitude: params.lat, longitude: params.lng },
    radius: radiusMetres,
  };
  const body = params.query.length > 0
    ? {
      textQuery: params.query,
      includedType: "restaurant",
      maxResultCount: 20,
      locationBias: { circle },
    }
    : {
      includedTypes: ["restaurant"],
      maxResultCount: 20,
      locationRestriction: { circle },
    };
  const path = params.query.length > 0 ? "places:searchText" : "places:searchNearby";
  const payload = await placesPost(path, body, NEARBY_FIELD_MASK, apiKey, fetchImpl);
  const places = (payload as { places?: unknown }).places;
  return Array.isArray(places) ? places : [];
}

/** Raw Place details resource. Throws PlacesError(404) when unknown. */
export async function placeDetailsRaw(
  placeId: string,
  apiKey: string,
  fetchImpl: typeof fetch = fetch,
): Promise<unknown> {
  const response = await fetchImpl(`${PLACES_BASE}/places/${encodeURIComponent(placeId)}`, {
    headers: { "X-Goog-Api-Key": apiKey, "X-Goog-FieldMask": DETAILS_FIELD_MASK },
  });
  if (!response.ok) {
    await response.body?.cancel();
    throw new PlacesError(response.status, `Places API responded ${response.status}`);
  }
  return await response.json();
}

/** Fetches photo bytes for a photo resource name (`places/../photos/..`). */
export function fetchPhoto(
  photoName: string,
  maxWidthPx: number,
  apiKey: string,
  fetchImpl: typeof fetch = fetch,
): Promise<Response> {
  const url = `${PLACES_BASE}/${photoName}/media?maxWidthPx=${maxWidthPx}`;
  return fetchImpl(url, { headers: { "X-Goog-Api-Key": apiKey }, redirect: "follow" });
}

/** Lower-cases, collapses whitespace and trims; "" when absent. */
export function normaliseQuery(query: unknown): string {
  if (typeof query !== "string") return "";
  return query.toLowerCase().replace(/\s+/g, " ").trim().slice(0, 100);
}

/** Post-filters that neither Places endpoint applies uniformly. */
export function applyFilters(
  restaurants: Restaurant[],
  maxPrice: number | null,
  minRating: number | null,
): Restaurant[] {
  return restaurants.filter((r) => {
    if (maxPrice !== null && r.priceLevel !== null && r.priceLevel > maxPrice) return false;
    if (minRating !== null && (r.rating ?? 0) < minRating) return false;
    return true;
  });
}
