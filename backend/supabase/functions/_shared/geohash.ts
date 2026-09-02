/**
 * @file geohash.ts
 * @description Pure geohash encoder (standard base32 alphabet). Precision 6
 *   gives cells of roughly 1.2 km x 0.6 km, which is what places-nearby uses
 *   as its cache cell.
 */

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

export const PLACES_CACHE_PRECISION = 6;

/**
 * Encodes a WGS84 point to a geohash string.
 * @throws RangeError when the coordinates or precision are out of range.
 */
export function geohashEncode(
  lat: number,
  lng: number,
  precision = PLACES_CACHE_PRECISION,
): string {
  if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
    throw new RangeError(`latitude out of range: ${lat}`);
  }
  if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
    throw new RangeError(`longitude out of range: ${lng}`);
  }
  if (!Number.isInteger(precision) || precision < 1 || precision > 12) {
    throw new RangeError(`precision out of range: ${precision}`);
  }

  let latMin = -90;
  let latMax = 90;
  let lngMin = -180;
  let lngMax = 180;
  let bits = 0;
  let bitCount = 0;
  let evenBit = true; // longitude bits sit on even positions
  let hash = "";

  while (hash.length < precision) {
    if (evenBit) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        bits = (bits << 1) | 1;
        lngMin = mid;
      } else {
        bits = bits << 1;
        lngMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        bits = (bits << 1) | 1;
        latMin = mid;
      } else {
        bits = bits << 1;
        latMax = mid;
      }
    }
    evenBit = !evenBit;
    bitCount++;
    if (bitCount === 5) {
      hash += BASE32[bits];
      bits = 0;
      bitCount = 0;
    }
  }
  return hash;
}
