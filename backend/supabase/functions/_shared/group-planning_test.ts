import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { planningDetails, suggestionFromRow, suggestionInput } from "./group-planning.ts";
import { groupFromRow } from "./invites.ts";
import type { GroupRow } from "./types.ts";
Deno.test("planning details preserve integer cents, explicit host and payment arrangement", () => {
  assertEquals(
    planningDetails({
      details: {
        hostName: " Sam ",
        budgetPerPersonMinor: 2550,
        paymentArrangement: "split_equally",
        paymentMethod: "card",
      },
    }, "Host"),
    {
      host_name: "Sam",
      budget_per_person_minor: 2550,
      currency_code: "AUD",
      payment_arrangement: "split_equally",
      payment_method: "card",
    },
  );
});
Deno.test("legacy groups say unspecified instead of inventing budget or payment method", () => {
  const details = planningDetails({}, "Sam");
  assertEquals(details.budget_per_person_minor, null);
  assertEquals(details.payment_method, "undecided");
  assertEquals(details.host_name, "Sam");
});
Deno.test("invalid money, payment options and oversized fields are rejected", () => {
  for (
    const details of [
      { budgetPerPersonMinor: -1 },
      { budgetPerPersonMinor: 1.5 },
      { budgetPerPersonMinor: 1000001 },
      { paymentMethod: "steal" },
      { hostName: "x".repeat(61) },
      { currencyCode: "not-money" },
    ]
  ) assertThrows(() => planningDetails(details, "Host"));
});
Deno.test("guest can suggest a place, time, or both; blank and past alternatives fail", () => {
  assertEquals(
    suggestionInput({ suggestion: { placeName: "New cafe" } }, 100).p_scheduled_at,
    null,
  );
  assertEquals(suggestionInput({ scheduledAt: 200 }, 100).p_place_name, null);
  assertEquals(suggestionInput({ placeName: "Cafe", scheduledAt: 200 }, 100).p_place_name, "Cafe");
  for (
    const input of [{}, { note: "Hi" }, { placeAddress: "No place" }, { scheduledAt: 99 }, {
      placeName: " ",
    }, { placeName: "x".repeat(201) }]
  ) assertThrows(() => suggestionInput(input, 100));
});
Deno.test("public suggestion excludes RSVP IDs, user IDs and guest tokens", () => {
  const row = {
    id: "s",
    group_id: "g",
    rsvp_id: "private",
    display_name: "Sam",
    place_name: "Cafe",
    place_address: null,
    scheduled_at: null,
    note: null,
    status: "pending",
    created_at: "2026-10-01T00:00:00Z",
    guest_token: "private",
  };
  const publicValue = suggestionFromRow(row);
  assertEquals(
    Object.keys(publicValue).sort(),
    [
      "id",
      "groupId",
      "displayName",
      "placeName",
      "placeAddress",
      "scheduledAtEpochSeconds",
      "note",
      "status",
      "createdAtEpochSeconds",
    ].sort(),
  );
});
Deno.test("public group maps unset host explicitly and retains zero-dollar budget", () => {
  const row = {
    id: "g",
    host_id: "h",
    host_name: " ",
    name: "Lunch",
    scheduled_at: "2026-10-01T00:00:00Z",
    area_lat: 0,
    area_lng: 0,
    radius_km: 1,
    place_id: null,
    place_name: null,
    place_address: null,
    invite_code: "ABCD1234",
    created_at: "2026-10-01T00:00:00Z",
    cancelled_at: null,
    budget_per_person_minor: 0,
  } as GroupRow;
  assertEquals(groupFromRow(row).hostName, "Host name not provided");
  assertEquals(groupFromRow(row).budgetPerPersonMinor, 0);
});
