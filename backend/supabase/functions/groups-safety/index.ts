import { getUser, guestToken } from "../_shared/auth.ts";
import { badRequest, handle, json, readJsonObject } from "../_shared/errors.ts";
import { planningRpcError } from "../_shared/group-planning.ts";
import { normaliseInviteCode } from "../_shared/invites.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { requireEnum, requireUuid } from "../_shared/validate.ts";

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const code = normaliseInviteCode(typeof body.code === "string" ? body.code : null);
  if (!code) throw badRequest("Invalid invitation code");
  const user = await getUser(req);
  const token = guestToken(req);
  if (!user && !token) throw badRequest("Open the invitation before reporting it");
  const { data, error } = await serviceClient().rpc("group_safety_action", {
    p_code: code,
    p_user_id: user?.id ?? null,
    p_guest_token: token,
    p_target_kind: requireEnum(body, "targetKind", ["group", "rsvp", "suggestion"]),
    p_target_id: body.targetId == null ? null : requireUuid(body, "targetId"),
    p_action: requireEnum(body, "action", ["report", "block", "report_block"]),
    p_reason: requireEnum(body, "reason", ["harassment", "hate", "sexual", "spam", "other"]),
  });
  planningRpcError(error);
  return json({ reportId: data, recorded: true }, 200, { "Cache-Control": "no-store" });
}));
