/**
 * @file invitations/index.ts
 * @description GET /invitations?code=ABCD1234 (public): the invitation view
 *   for the apps and the web landing page. `myStatus` is resolved from the
 *   JWT or the `x-guest-token` header when present.
 */

import { getUser, guestToken } from "../_shared/auth.ts";
import { ApiError, badRequest, ErrorCode, handle, json } from "../_shared/errors.ts";
import { buildInvitation, findMyRsvp, normaliseInviteCode } from "../_shared/invites.ts";
import { requireEnv, serviceClient, unwrap } from "../_shared/supabase.ts";
import type { GroupRow, RsvpRow } from "../_shared/types.ts";

Deno.serve(handle(["GET"], async (req) => {
  const code = normaliseInviteCode(new URL(req.url).searchParams.get("code"));
  if (!code) throw badRequest("code must be 8 characters");

  const client = serviceClient();
  const { data: group, error } = await client
    .from("groups")
    .select("*")
    .eq("invite_code", code)
    .is("cancelled_at", null)
    .maybeSingle();
  if (error) throw new Error(`database: ${error.message}`);
  if (!group) throw new ApiError(ErrorCode.NOT_FOUND, "Invitation not found");

  const rsvps = unwrap(
    await client.from("rsvps").select("*").eq("group_id", group.id).order("responded_at", {
      ascending: true,
      nullsFirst: false,
    }),
  ) as RsvpRow[];

  const user = await getUser(req);
  const mine = findMyRsvp(rsvps, user?.id ?? null, guestToken(req));
  return json({
    invitation: buildInvitation(
      group as GroupRow,
      rsvps,
      mine?.status ?? null,
      requireEnv("INVITE_LINK_BASE"),
    ),
  });
}));
