import { requireUser } from "../_shared/auth.ts";
import { safetyContext } from "../_shared/content-safety.ts";
import { handle, json, readJsonObject } from "../_shared/errors.ts";
import { planningDetails, planningRpcError } from "../_shared/group-planning.ts";
import { groupFromRow } from "../_shared/invites.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { requireUuid } from "../_shared/validate.ts";
import type { GroupRow } from "../_shared/types.ts";

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const groupId = requireUuid(body, "groupId");
  const user = await requireUser(req);
  const client = serviceClient();
  await safetyContext(client, groupId, user.id, null);
  const details = planningDetails(body, user.displayName);
  const { data, error } = await client.rpc("update_group_details", {
    p_group_id: groupId,
    p_host_id: user.id,
    p_host_name: details.host_name,
    p_budget: details.budget_per_person_minor,
    p_currency: details.currency_code,
    p_arrangement: details.payment_arrangement,
    p_method: details.payment_method,
  });
  planningRpcError(error);
  return json({ group: groupFromRow(data as GroupRow) });
}));
