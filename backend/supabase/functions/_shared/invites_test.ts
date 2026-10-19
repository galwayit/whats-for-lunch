import { assertEquals } from "jsr:@std/assert@1";
import {
  buildInvitation,
  CROCKFORD_ALPHABET,
  findMyRsvp,
  INVITE_CODE_LENGTH,
  inviteUrl,
  isValidInviteCode,
  normaliseInviteCode,
} from "./invites.ts";
import type { GroupRow, RsvpRow } from "./types.ts";

Deno.test("Crockford alphabet has 32 symbols without I, L, O, U", () => {
  assertEquals(CROCKFORD_ALPHABET.length, 32);
  assertEquals(new Set(CROCKFORD_ALPHABET).size, 32);
  for (const banned of "ILOU") assertEquals(CROCKFORD_ALPHABET.includes(banned), false);
  assertEquals(INVITE_CODE_LENGTH, 8);
});

Deno.test("isValidInviteCode accepts 8 Crockford characters only", () => {
  assertEquals(isValidInviteCode("ABCD1234"), true);
  assertEquals(isValidInviteCode("7ZYXWVTS"), true);
  assertEquals(isValidInviteCode("ABCD123"), false);
  assertEquals(isValidInviteCode("ABCDILOU"), false);
  assertEquals(isValidInviteCode("abcd1234"), false);
  assertEquals(isValidInviteCode("ABCD-123"), false);
});

Deno.test("normaliseInviteCode upper-cases and applies decoding aliases", () => {
  assertEquals(normaliseInviteCode(" abcd1234 "), "ABCD1234");
  assertEquals(normaliseInviteCode("abcdilo1"), "ABCD1101");
  assertEquals(normaliseInviteCode("ABCD-1234"), "ABCD1234");
  assertEquals(normaliseInviteCode("ABCDU234"), null);
  assertEquals(normaliseInviteCode("short"), null);
  assertEquals(normaliseInviteCode(null), null);
});

Deno.test("inviteUrl tolerates a missing trailing slash", () => {
  assertEquals(
    inviteUrl("ABCD1234", "https://lunch.iapp.au/i/"),
    "https://lunch.iapp.au/i/ABCD1234",
  );
  assertEquals(
    inviteUrl("ABCD1234", "https://lunch.iapp.au/i"),
    "https://lunch.iapp.au/i/ABCD1234",
  );
});

const group: GroupRow = {
  id: "0b1a7d2e-1111-4f5e-8a9b-000000000001",
  host_id: "6f9f1c2d-2222-4f5e-8a9b-000000000002",
  host_name: "Ray",
  name: "Friday team lunch",
  scheduled_at: "2026-09-04T02:00:00+00:00",
  area_lat: -33.87,
  area_lng: 151.21,
  radius_km: 2,
  place_id: null,
  place_name: null,
  place_address: null,
  invite_code: "ABCD1234",
  created_at: "2026-09-02T03:00:00+00:00",
  cancelled_at: null,
};

const rsvps: RsvpRow[] = [
  {
    id: "r1",
    group_id: group.id,
    guest_user_id: "6f9f1c2d-2222-4f5e-8a9b-000000000003",
    guest_token: null,
    display_name: "Sam",
    status: "accepted",
    responded_at: "2026-09-02T04:00:00+00:00",
  },
  {
    id: "r2",
    group_id: group.id,
    guest_user_id: null,
    guest_token: "a".repeat(64),
    display_name: "Web guest",
    status: "declined",
    responded_at: null,
  },
];

Deno.test("buildInvitation converts rows to the Kotlin JSON shape with epoch seconds", () => {
  const invitation = buildInvitation(group, rsvps, "accepted", "https://lunch.iapp.au/i/");
  assertEquals(invitation, {
    group: {
      id: group.id,
      hostId: group.host_id,
      hostName: "Ray",
      budgetPerPersonMinor: null,
      currencyCode: "AUD",
      paymentArrangement: "undecided",
      paymentMethod: "undecided",
      name: "Friday team lunch",
      scheduledAtEpochSeconds: Date.parse("2026-09-04T02:00:00Z") / 1000,
      areaLatitude: -33.87,
      areaLongitude: 151.21,
      radiusKm: 2,
      placeId: null,
      placeName: null,
      placeAddress: null,
      inviteCode: "ABCD1234",
      createdAtEpochSeconds: Date.parse("2026-09-02T03:00:00Z") / 1000,
    },
    attendees: [
      {
        id: "r1",
        groupId: group.id,
        guestUserId: "6f9f1c2d-2222-4f5e-8a9b-000000000003",
        displayName: "Sam",
        status: "accepted",
        respondedAtEpochSeconds: Date.parse("2026-09-02T04:00:00Z") / 1000,
      },
      {
        id: "r2",
        groupId: group.id,
        guestUserId: null,
        displayName: "Web guest",
        status: "declined",
        respondedAtEpochSeconds: null,
      },
    ],
    myStatus: "accepted",
    inviteUrl: "https://lunch.iapp.au/i/ABCD1234",
  });
});

Deno.test("findMyRsvp prefers the user id, then the guest token", () => {
  assertEquals(findMyRsvp(rsvps, "6f9f1c2d-2222-4f5e-8a9b-000000000003", null)?.id, "r1");
  assertEquals(findMyRsvp(rsvps, null, "a".repeat(64))?.id, "r2");
  assertEquals(findMyRsvp(rsvps, "nobody", "b".repeat(64)), null);
});
