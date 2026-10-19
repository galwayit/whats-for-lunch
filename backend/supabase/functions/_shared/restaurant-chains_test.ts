import { assertEquals } from "jsr:@std/assert@1";
import { isChainRestaurant } from "./restaurant-chains.ts";

Deno.test("chain filtering recognises regional names and punctuation", () => {
  for (
    const name of [
      "Hungry Jack's Burgers Melbourne Central",
      "HUNGRY JACK’S",
      "Hungry Jacks",
      "Hungry-Jack’s",
      "HungryJacks",
      "Burger King",
      "McDonald’s",
      "Domino's Pizza",
      "Grill’d",
      "KFC Swanston Street",
    ]
  ) {
    assertEquals(isChainRestaurant(name), true, name);
  }
});

Deno.test("chain filtering does not match unrelated substrings", () => {
  for (
    const name of [
      "Jack’s Corner Cafe",
      "The Hungry Hippo",
      "Burger Kingdom",
      "Subwayman Coffee",
      "Local Pizza Kitchen",
    ]
  ) {
    assertEquals(isChainRestaurant(name), false, name);
  }
});
