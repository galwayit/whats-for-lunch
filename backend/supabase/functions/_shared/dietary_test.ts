import { assertEquals } from "jsr:@std/assert@1";
import { matchesDietary } from "./dietary.ts";
import type { Restaurant } from "./types.ts";

const restaurant = (overrides: Partial<Restaurant> = {}) =>
  ({
    supportedDietaryRestrictions: [],
    allergenInfo: [],
    hasVerifiedDietaryInfo: false,
    ...overrides,
  }) as Restaurant;

Deno.test("dietary verification never treats missing allergen evidence as safety", () => {
  assertEquals(matchesDietary(restaurant(), [], [], true), true);
  assertEquals(matchesDietary(restaurant(), [], ["nuts"], true), false);
  assertEquals(
    matchesDietary(restaurant({ hasVerifiedDietaryInfo: true }), [], ["nuts"], true),
    false,
  );
  assertEquals(matchesDietary(restaurant(), [], ["nuts"], false), true);
});
Deno.test("known allergen conflicts remain excluded when verification is optional", () => {
  for (
    const [reported, requested] of [["peanuts", "nut_allergy"], ["Tree Nuts", "nuts"], [
      "crustaceans",
      "shellfish_allergy",
    ]]
  ) {
    assertEquals(
      matchesDietary(restaurant({ allergenInfo: [reported] }), [], [requested], false),
      false,
    );
  }
});
Deno.test("verified diets require explicit support for every requirement", () => {
  const r = restaurant({
    hasVerifiedDietaryInfo: true,
    supportedDietaryRestrictions: ["vegetarian"],
    dietaryCompatibilityScores: { gluten_free: 1 },
  });
  assertEquals(matchesDietary(r, ["vegetarian"], [], true), true);
  assertEquals(matchesDietary(r, ["vegetarian", "gluten_free"], [], true), false);
  assertEquals(
    matchesDietary(
      restaurant({ supportedDietaryRestrictions: ["vegetarian"] }),
      ["vegetarian"],
      [],
      true,
    ),
    false,
  );
});
