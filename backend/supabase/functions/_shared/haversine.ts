/**
 * @file haversine.ts
 * @description Great-circle distance between two WGS84 points, in kilometres.
 */

/** Mean Earth radius in kilometres (IUGG). */
export const EARTH_RADIUS_KM = 6371.0088;

function toRadians(degrees: number): number {
  return (degrees * Math.PI) / 180;
}

/** Distance in kilometres between two points using the haversine formula. */
export function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(a)));
}

/** Rounds a distance to two decimals, which is all the UI shows. */
export function roundKm(km: number): number {
  return Math.round(km * 100) / 100;
}
