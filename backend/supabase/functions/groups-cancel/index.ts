/**
 * @file groups-cancel/index.ts
 * @description POST /groups-cancel (auth, host): soft-cancels a group. The
 * operation is idempotent; cancelled groups disappear from app queries and
 * their public invitations immediately stop resolving.
 */

import { requireUser } from "../_shared/auth.ts";
import { ApiError, ErrorCode, handle, readJsonObject } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { requireUuid } from "../_shared/validate.ts";

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const groupId = requireUuid(body, "groupId");
  const user = await requireUser(req);
  const client = serviceClient();

  const { data: group, error } = await client
    .from("groups")
    .select("id, host_id, cancelled_at")
    .eq("id", groupId)
    .maybeSingle();
  if (error) throw new Error(`database: ${error.message}`);
  if (!group) throw new ApiError(ErrorCode.NOT_FOUND, "Group not found");
  if (group.host_id !== user.id) {
    throw new ApiError(ErrorCode.FORBIDDEN, "Only the host can cancel");
  }

  if (!group.cancelled_at) {
    const { error: updateError } = await client
      .from("groups")
      .update({ cancelled_at: new Date().toISOString() })
      .eq("id", groupId);
    if (updateError) throw new Error(`database: ${updateError.message}`);
  }

  return new Response(null, { status: 204 });
}));
