import { notifyUsers } from "../_shared/notify.ts";
import { getUser, guestToken } from "../_shared/auth.ts";
import { checkSharedText, safetyContext } from "../_shared/content-safety.ts";
import { badRequest, handle, json, readJsonObject } from "../_shared/errors.ts";
import {
  planningRpcError,
  suggestionFromRow,
  suggestionInput,
  type SuggestionRow,
} from "../_shared/group-planning.ts";
import { buildInvitation, findMyRsvp, normaliseInviteCode } from "../_shared/invites.ts";
import { requireEnv, serviceClient, unwrap } from "../_shared/supabase.ts";
import { optionalString } from "../_shared/validate.ts";
import type { GroupRow, RsvpRow } from "../_shared/types.ts";

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const code = normaliseInviteCode(typeof body.code === "string" ? body.code : null);
  if (!code) throw badRequest("code must be 8 characters");
  const input = suggestionInput(body);
  const user = await getUser(req);
  const existingToken = guestToken(req);
  const token = user ? null : existingToken ??
    Array.from(crypto.getRandomValues(new Uint8Array(32)), (b) => b.toString(16).padStart(2, "0"))
      .join("");
  const name = optionalString(body, "displayName", 60) ?? user?.displayName.slice(0, 60) ?? null;
  checkSharedText(name);
  const client = serviceClient();
  const before = unwrap(
    await client.from("groups").select("id").eq("invite_code", code).maybeSingle(),
  ) as { id: string } | null;
  if (!before) throw badRequest("Invitation unavailable");
  const hidden = await safetyContext(client, before.id, user?.id ?? null, token);
  const { data, error } = await client.rpc("submit_group_suggestion", {
    p_code: code,
    p_user_id: user?.id ?? null,
    p_guest_token: token,
    p_display_name: name,
    ...input,
  });
  planningRpcError(error);
  const suggestion = data as SuggestionRow;
  const group = unwrap(
    await client.from("groups").select("*").eq("id", suggestion.group_id).single(),
  ) as GroupRow;
  const rsvps = unwrap(
    await client.from("rsvps").select("*").eq("group_id", group.id),
  ) as RsvpRow[];
  const mine = findMyRsvp(rsvps, user?.id ?? null, token);
  const invitation = buildInvitation(
    group,
    rsvps.filter((r) => !hidden.has(r.id)),
    mine?.status ?? null,
    requireEnv("INVITE_LINK_BASE"),
  );
  invitation.mySuggestion = suggestionFromRow(suggestion);
  if (data.new_submission === true) {
    try {
      await notifyUsers(client, [group.host_id], {
        data: { type: "rsvp", groupId: group.id },
        notification: {
          title: "A guest suggested a change",
          body: `${suggestion.display_name} suggested another place or time for ${group.name}.`,
        },
      });
    } catch {
      console.warn("Suggestion saved; host notification unavailable");
    }
  }
  return json({ invitation, ...(!user && !existingToken ? { guestToken: token } : {}) });
}));
