/**
 * @file groups-confirm/index.ts
 * @description POST /groups-confirm (auth, host): records the chosen place and
 *   pushes an `invitation` notification to guests with a pending rsvp.
 */

import { requireUser } from "../_shared/auth.ts";
import { checkSharedText, safetyContext } from "../_shared/content-safety.ts";
import { ApiError, ErrorCode, handle, json, readJsonObject } from "../_shared/errors.ts";
import { groupFromRow } from "../_shared/invites.ts";
import { notifyUsers } from "../_shared/notify.ts";
import { serviceClient, unwrap } from "../_shared/supabase.ts";
import type { GroupRow } from "../_shared/types.ts";
import { requirePlaceId, requireString, requireUuid } from "../_shared/validate.ts";

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const groupId = requireUuid(body, "groupId");
  const placeId = requirePlaceId(body, "placeId");
  const placeName = requireString(body, "placeName", 200);
  const placeAddress = requireString(body, "placeAddress", 400);

  const user = await requireUser(req);
  const client = serviceClient();
  checkSharedText(placeName, placeAddress);
  await safetyContext(client, groupId, user.id, null);

  const { data: existing, error } = await client.from("groups").select("id, host_id").eq(
    "id",
    groupId,
  ).maybeSingle();
  if (error) throw new Error(`database: ${error.message}`);
  if (!existing) throw new ApiError(ErrorCode.NOT_FOUND, "Group not found");
  if (existing.host_id !== user.id) {
    throw new ApiError(ErrorCode.FORBIDDEN, "Only the host can confirm");
  }

  const row = unwrap(
    await client
      .from("groups")
      .update({ place_id: placeId, place_name: placeName, place_address: placeAddress })
      .eq("id", groupId)
      .select("*")
      .single(),
  ) as GroupRow;

  const pending = unwrap(
    await client
      .from("rsvps")
      .select("guest_user_id")
      .eq("group_id", groupId)
      .eq("status", "pending")
      .not("guest_user_id", "is", null),
  ) as { guest_user_id: string }[];

  await notifyUsers(client, pending.map((r) => r.guest_user_id), {
    data: { type: "invitation", groupId: row.id, code: row.invite_code },
    notification: {
      title: `${row.host_name} picked ${placeName}`,
      body: `${row.name}: tap to RSVP`,
    },
  });

  return json({ group: groupFromRow(row) });
}));
