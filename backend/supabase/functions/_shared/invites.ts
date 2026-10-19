/**
 * @file invites.ts
 * @description Invite codes and Invitation assembly. Codes are 8 characters
 *   of Crockford base32 (no I, L, O, U) and are generated in SQL by
 *   `generate_invite_code()`; this module validates, normalises and maps rows
 *   to the JSON the clients expect.
 */

import {
  type GroupRow,
  type Invitation,
  type LunchGroup,
  type Rsvp,
  type RsvpRow,
  type RsvpStatus,
  toEpochSeconds,
} from "./types.ts";

export const CROCKFORD_ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
export const INVITE_CODE_LENGTH = 8;

const CODE_PATTERN = new RegExp(`^[${CROCKFORD_ALPHABET}]{${INVITE_CODE_LENGTH}}$`);

/**
 * Upper-cases and applies the Crockford decoding aliases (I/L -> 1, O -> 0)
 * so a hand-typed code still matches. Returns null when the result is not a
 * well-formed code.
 */
export function normaliseInviteCode(raw: string | null | undefined): string | null {
  if (typeof raw !== "string") return null;
  const cleaned = raw.trim().toUpperCase().replace(/[IL]/g, "1").replace(/O/g, "0").replace(
    /-/g,
    "",
  );
  return CODE_PATTERN.test(cleaned) ? cleaned : null;
}

export function isValidInviteCode(code: string): boolean {
  return CODE_PATTERN.test(code);
}

/** Builds the public landing URL for a code from INVITE_LINK_BASE. */
export function inviteUrl(code: string, base: string): string {
  const trimmed = base.endsWith("/") ? base : `${base}/`;
  return `${trimmed}${code}`;
}

export function groupFromRow(row: GroupRow): LunchGroup {
  return {
    id: row.id,
    hostId: row.host_id,
    hostName: row.host_name.trim() || "Host name not provided",
    budgetPerPersonMinor: row.budget_per_person_minor ?? null,
    currencyCode: row.currency_code ?? "AUD",
    paymentArrangement: row.payment_arrangement ?? "undecided",
    paymentMethod: row.payment_method ?? "undecided",
    name: row.name,
    scheduledAtEpochSeconds: toEpochSeconds(row.scheduled_at),
    areaLatitude: Number(row.area_lat),
    areaLongitude: Number(row.area_lng),
    radiusKm: Number(row.radius_km),
    placeId: row.place_id,
    placeName: row.place_name,
    placeAddress: row.place_address,
    inviteCode: row.invite_code,
    createdAtEpochSeconds: toEpochSeconds(row.created_at),
  };
}

export function rsvpFromRow(row: RsvpRow): Rsvp {
  return {
    id: row.id,
    groupId: row.group_id,
    guestUserId: row.guest_user_id,
    displayName: row.display_name,
    status: row.status,
    respondedAtEpochSeconds: row.responded_at ? toEpochSeconds(row.responded_at) : null,
  };
}

/**
 * Assembles the Invitation payload. `myStatus` is the status of the rsvp row
 * that belongs to the caller (matched by user id or guest token), or null.
 */
export function buildInvitation(
  group: GroupRow,
  rsvps: RsvpRow[],
  myStatus: RsvpStatus | null,
  linkBase: string,
): Invitation {
  return {
    group: groupFromRow(group),
    attendees: rsvps.map(rsvpFromRow),
    myStatus,
    inviteUrl: inviteUrl(group.invite_code, linkBase),
  };
}

/** Finds the caller's own rsvp among the group's rows. */
export function findMyRsvp(
  rsvps: RsvpRow[],
  userId: string | null,
  guestToken: string | null,
): RsvpRow | null {
  if (userId) {
    const byUser = rsvps.find((r) => r.guest_user_id === userId);
    if (byUser) return byUser;
  }
  if (guestToken) {
    const byToken = rsvps.find((r) => r.guest_token === guestToken);
    if (byToken) return byToken;
  }
  return null;
}
