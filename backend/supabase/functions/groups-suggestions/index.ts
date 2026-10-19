import { notifyUsers } from "../_shared/notify.ts";
import { requireUser } from "../_shared/auth.ts";
import {
  ApiError,
  badRequest,
  ErrorCode,
  handle,
  json,
  readJsonObject,
} from "../_shared/errors.ts";
import {
  planningRpcError,
  suggestionFromRow,
  type SuggestionRow,
} from "../_shared/group-planning.ts";
import { groupFromRow } from "../_shared/invites.ts";
import { serviceClient, unwrap } from "../_shared/supabase.ts";
import { requireUuid } from "../_shared/validate.ts";
import type { GroupRow } from "../_shared/types.ts";
import { safetyContext } from "../_shared/content-safety.ts";

Deno.serve(handle(["GET", "POST"], async (req) => {
  const user = await requireUser(req);
  const client = serviceClient();
  const body = req.method === "GET"
    ? Object.fromEntries(new URL(req.url).searchParams)
    : await readJsonObject(req);
  const groupId = requireUuid(body, "groupId");
  const hidden = await safetyContext(client, groupId, user.id, null);
  if (req.method === "GET") {
    const group = unwrap(
      await client.from("groups").select("host_id").eq("id", groupId).is("cancelled_at", null)
        .maybeSingle(),
    );
    const owner = group as { host_id: string } | null;
    if (!owner) throw new ApiError(ErrorCode.NOT_FOUND, "Group not found");
    if (owner.host_id !== user.id) {
      throw new ApiError(ErrorCode.FORBIDDEN, "Only the host can review suggestions");
    }
    const rows = unwrap(
      await client.from("group_suggestions").select("*").eq("group_id", groupId).is(
        "moderated_at",
        null,
      ).order(
        "created_at",
        { ascending: false },
      ).limit(200),
    ) as SuggestionRow[];
    return json(
      { suggestions: rows.filter((s) => !hidden.has(s.rsvp_id)).map(suggestionFromRow) },
      200,
      { "Cache-Control": "no-store" },
    );
  }
  const suggestionId = requireUuid(body, "suggestionId");
  if (typeof body.accept !== "boolean") throw badRequest("accept must be a boolean");
  const { data, error } = await client.rpc("review_group_suggestion", {
    p_group_id: groupId,
    p_suggestion_id: suggestionId,
    p_host_id: user.id,
    p_accept: body.accept,
  });
  planningRpcError(error);
  const updated = data as GroupRow;
  if (body.accept) {
    try {
      const guests = unwrap(
        await client.from("rsvps").select("guest_user_id").eq("group_id", groupId).not(
          "guest_user_id",
          "is",
          null,
        ),
      ) as { guest_user_id: string }[];
      await notifyUsers(client, guests.map((guest) => guest.guest_user_id), {
        data: { type: "invitation", groupId, code: updated.invite_code },
        notification: {
          title: `${updated.name} has changed`,
          body: "Check the new place and time, then RSVP again.",
        },
      });
    } catch {
      console.warn("Plan updated; guest notifications unavailable");
    }
  }
  return json({ group: groupFromRow(updated) });
}));
