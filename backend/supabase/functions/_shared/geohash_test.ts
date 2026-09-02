import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { geohashEncode } from "./geohash.ts";

Deno.test("geohashEncode reproduces published vectors", () => {
  // Wikipedia examples: 57.64911,10.40744 -> u4pruydqqvj; 42.605,-5.603 -> ezs42.
  assertEquals(geohashEncode(57.64911, 10.40744, 6), "u4pruy");
  assertEquals(geohashEncode(57.64911, 10.40744, 11), "u4pruydqqvj");
  assertEquals(geohashEncode(42.605, -5.603, 5), "ezs42");
  assertEquals(geohashEncode(0, 0, 6), "s00000");
  // Sydney CBD, precision 6 (the places cache cell).
  assertEquals(geohashEncode(-33.8688, 151.2093), "r3gx2f");
});

Deno.test("geohashEncode defaults to precision 6 and rejects bad input", () => {
  assertEquals(geohashEncode(-33.87, 151.21).length, 6);
  assertThrows(() => geohashEncode(91, 0), RangeError);
  assertThrows(() => geohashEncode(0, 181), RangeError);
  assertThrows(() => geohashEncode(0, 0, 0), RangeError);
  assertThrows(() => geohashEncode(Number.NaN, 0), RangeError);
});

Deno.test("nearby points share a cell, distant points do not", () => {
  const a = geohashEncode(-33.8688, 151.2093);
  const b = geohashEncode(-33.8689, 151.2094);
  const c = geohashEncode(-33.9, 151.3);
  assertEquals(a, b);
  assertEquals(a === c, false);
});
