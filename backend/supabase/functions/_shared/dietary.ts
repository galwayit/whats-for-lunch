import type { Restaurant } from "./types.ts";
import { stringArray } from "./validate.ts";

function family(value: string): string {
  const key = value.toLowerCase().replace(/[- ]/g, "_");
  if (["nut", "nuts", "nut_allergy", "peanut", "peanuts", "tree_nut", "tree_nuts"].includes(key)) {
    return "nuts";
  }
  if (
    ["shellfish", "shellfish_allergy", "crustacean", "crustaceans", "mollusc", "molluscs"].includes(
      key,
    )
  ) return "shellfish";
  return key;
}

/** Ranking cannot turn absent allergen evidence into a safe recommendation. */
export function matchesDietary(
  r: Restaurant,
  restrictions: unknown,
  allergens: unknown,
  requireVerification: boolean,
): boolean {
  const diets = stringArray(restrictions);
  const allergies = stringArray(allergens);
  const reported = new Set(stringArray(r.allergenInfo).map(family));
  if (allergies.some((a) => reported.has(family(a)))) return false;
  if (!requireVerification || (!diets.length && !allergies.length)) return true;
  // The current data source has no explicit certified free-from evidence.
  if (allergies.length || r.hasVerifiedDietaryInfo !== true) return false;
  return diets.every((diet) => stringArray(r.supportedDietaryRestrictions).includes(diet));
}
