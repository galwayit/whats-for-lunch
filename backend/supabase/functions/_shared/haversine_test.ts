import { assertAlmostEquals, assertEquals } from "jsr:@std/assert@1";
import { haversineKm, roundKm } from "./haversine.ts";

Deno.test("haversineKm matches known great-circle distances", () => {
  // Sydney CBD to Melbourne CBD: ~713.8 km on a 6371 km sphere.
  assertAlmostEquals(haversineKm(-33.8688, 151.2093, -37.8136, 144.9631), 713.8, 1.0);
  // Paris to London: ~343.5 km.
  assertAlmostEquals(haversineKm(48.8566, 2.3522, 51.5074, -0.1278), 343.5, 1.0);
  // Quarter of the equator: ~10,007.5 km.
  assertAlmostEquals(haversineKm(0, 0, 0, 90), 10007.5, 1.0);
});

Deno.test("haversineKm is zero for the same point and symmetric", () => {
  assertEquals(haversineKm(-33.87, 151.21, -33.87, 151.21), 0);
  assertAlmostEquals(
    haversineKm(-33.87, 151.21, -33.86, 151.20),
    haversineKm(-33.86, 151.20, -33.87, 151.21),
    1e-9,
  );
});

Deno.test("roundKm keeps two decimals", () => {
  assertEquals(roundKm(0.71549), 0.72);
  assertEquals(roundKm(1.005), 1); // floating point: 1.005*100 = 100.49999
});
