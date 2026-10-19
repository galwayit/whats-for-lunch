/**
 * @file invitations-respond/index.ts
 * @description POST /invitations-respond (public): accept or decline. Signed-in
 *   guests upsert on (group_id, guest_user_id); anonymous web guests get a
 *   `guestToken` (returned once, sent back as `x-guest-token`) keyed on
 *   (group_id, guest_token).
 */

import { suggestionFromRow, type SuggestionRow } from "../_shared/group-planning.ts";
import { getUser, guestToken } from "../_shared/auth.ts";
import { checkSharedText, safetyContext } from "../_shared/content-safety.ts";
import {
  ApiError,
  badRequest,
  ErrorCode,
  handle,
  json,
  readJsonObject,
} from "../_shared/errors.ts";
import { buildInvitation, findMyRsvp, normaliseInviteCode } from "../_shared/invites.ts";
import { notifyUsers } from "../_shared/notify.ts";
import { requireEnv, serviceClient, unwrap } from "../_shared/supabase.ts";
import type { GroupRow, RsvpRow, RsvpStatus } from "../_shared/types.ts";
import { optionalString, requireEnum } from "../_shared/validate.ts";

const STATUSES = ["accepted", "declined"] as const;

function newGuestToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const code = normaliseInviteCode(typeof body.code === "string" ? body.code : null);
  if (!code) throw badRequest("code must be 8 characters");
  const status: RsvpStatus = requireEnum(body, "status", STATUSES);
  const displayNameInput = optionalString(body, "displayName", 60);

  const client = serviceClient();
  const { data: group, error } = await client
    .from("groups")
    .select("*")
    .eq("invite_code", code)
    .is("cancelled_at", null)
    .maybeSingle();
  if (error) throw new Error(`database: ${error.message}`);
  if (!group) throw new ApiError(ErrorCode.NOT_FOUND, "Invitation not found");
  const groupRow = group as GroupRow;

  const user = await getUser(req);
  checkSharedText(displayNameInput ?? user?.displayName);
  const hidden = await safetyContext(client, groupRow.id, user?.id ?? null, guestToken(req));
  const respondedAt = new Date().toISOString();
  let issuedToken: string | null = null;

  if (user) {
    const displayName = displayNameInput ?? user.displayName;
    unwrap(
      await client
        .from("rsvps")
        .upsert(
          {
            group_id: groupRow.id,
            guest_user_id: user.id,
            display_name: displayName,
            status,
            responded_at: respondedAt,
          },
          { onConflict: "group_id,guest_user_id" },
        )
        .select("id"),
    );
  } else {
    const existingToken = guestToken(req);
    const { data: existing } = existingToken
      ? await client.from("rsvps").select("id").eq("group_id", groupRow.id).eq(
        "guest_token",
        existingToken,
      ).maybeSingle()
      : { data: null };
    if (existing) {
      const update: Record<string, unknown> = { status, responded_at: respondedAt };
      if (displayNameInput) update.display_name = displayNameInput;
      unwrap(await client.from("rsvps").update(update).eq("id", existing.id).select("id"));
    } else {
      if (!displayNameInput) throw badRequest("displayName is required when not signed in");
      issuedToken = existingToken ?? newGuestToken();
      unwrap(
        await client
          .from("rsvps")
          .insert({
            group_id: groupRow.id,
            guest_token: issuedToken,
            display_name: displayNameInput,
            status,
            responded_at: respondedAt,
          })
          .select("id"),
      );
    }
  }

  const rsvps = unwrap(
    await client.from("rsvps").select("*").eq("group_id", groupRow.id).order("responded_at", {
      ascending: true,
      nullsFirst: false,
    }),
  ) as RsvpRow[];

  const responderName = displayNameInput ?? user?.displayName ?? "A guest";
  await notifyUsers(client, [groupRow.host_id], {
    data: { type: "rsvp", groupId: groupRow.id, status },
    notification: {
      title: `${responderName} ${status} ${groupRow.name}`,
      body: groupRow.place_name ? `Lunch at ${groupRow.place_name}` : "Tap to see who is coming",
    },
  });

  const invitation = buildInvitation(
    groupRow,
    rsvps.filter((r) => !hidden.has(r.id)),
    status,
    requireEnv("INVITE_LINK_BASE"),
  );
  const mine = findMyRsvp(rsvps, user?.id ?? null, issuedToken ?? guestToken(req));
  if (mine) {
    const rows = unwrap(
      await client.from("group_suggestions").select("*").eq("group_id", groupRow.id).eq(
        "rsvp_id",
        mine.id,
      ).is("moderated_at", null).order("created_at", { ascending: false }).limit(1),
    ) as SuggestionRow[];
    invitation.mySuggestion = rows[0] ? suggestionFromRow(rows[0]) : null;
  }
  return json(issuedToken ? { invitation, guestToken: issuedToken } : { invitation });
}));
