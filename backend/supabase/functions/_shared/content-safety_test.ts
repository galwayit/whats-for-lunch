import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { checkSharedText, newGuestToken } from "./content-safety.ts";
import { ApiError } from "./errors.ts";

Deno.test("shared text rejects obvious abuse including compatibility and invisible characters", () => {
  for (const text of ["kill yourself", "FUCK you", "ｆｕｃｋ", "fu\u200bck"]) {
    assertThrows(() => checkSharedText(text), ApiError);
  }
  for (const text of ["Sam", "Scunthorpe Cafe", "Could we meet at 12?", null]) {
    checkSharedText(text);
  }
});
Deno.test("guest capability has 256 random bits without identity information", () => {
  const a = newGuestToken();
  assertEquals(/^[a-f0-9]{64}$/.test(a), true);
  assertEquals(newGuestToken() === a, false);
});
