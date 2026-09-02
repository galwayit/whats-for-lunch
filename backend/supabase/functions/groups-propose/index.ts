/**
 * @file groups-propose/index.ts
 * @description POST /groups-propose (auth, host): three Gemini-ranked places
 *   near the group area using the host's preferences and past picks.
 */

import { requireAppUserId, requireUser } from "../_shared/auth.ts";
import { ApiError, ErrorCode, handle, json, readJsonObject } from "../_shared/errors.ts";
import { generateJson, modelForTier } from "../_shared/gemini.ts";
import { nearbyRestaurants } from "../_shared/nearby.ts";
import { buildGroupProposalPrompt, parseGroupProposalResponse } from "../_shared/prompt.ts";
import { functionsBaseUrl, requireEnv, serviceClient, unwrap } from "../_shared/supabase.ts";
import { requirePro } from "../_shared/tier.ts";
import type { GroupRow } from "../_shared/types.ts";
import { optionalObject, requireUuid } from "../_shared/validate.ts";

const PROPOSAL_COUNT = 3;

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const groupId = requireUuid(body, "groupId");
  const hostPreferences = optionalObject(body, "hostPreferences");

  const user = await requireUser(req);
  const client = serviceClient();
  const appUserId = requireAppUserId(req, user);
  await requirePro(client, appUserId);

  const { data: group, error } = await client.from("groups").select("*").eq("id", groupId)
    .maybeSingle();
  if (error) throw new Error(`database: ${error.message}`);
  if (!group) throw new ApiError(ErrorCode.NOT_FOUND, "Group not found");
  const row = group as GroupRow;
  if (row.host_id !== user.id) throw new ApiError(ErrorCode.FORBIDDEN, "Only the host can propose");

  const { restaurants } = await nearbyRestaurants(
    {
      lat: Number(row.area_lat),
      lng: Number(row.area_lng),
      radiusKm: Number(row.radius_km),
      query: "",
    },
    { client, apiKey: requireEnv("GOOGLE_PLACES_API_KEY"), functionsBase: functionsBaseUrl() },
  );
  if (restaurants.length === 0) return json({ proposals: [] });

  const pastRows = unwrap(
    await client
      .from("groups")
      .select("place_name")
      .eq("host_id", user.id)
      .not("place_name", "is", null)
      .order("scheduled_at", { ascending: false })
      .limit(10),
  ) as { place_name: string }[];

  const candidates = restaurants.slice(0, 20);
  const model = modelForTier("pro");
  const prompt = buildGroupProposalPrompt({
    groupName: row.name,
    scheduledAtIso: row.scheduled_at,
    hostPreferences,
    pastPicks: pastRows.map((r) => r.place_name),
    candidates,
    count: PROPOSAL_COUNT,
  });

  let proposals;
  let failure: string | null = null;
  let tokens = 0;
  let latencyMs = 0;
  try {
    const result = await generateJson({ apiKey: requireEnv("GEMINI_API_KEY"), model, prompt });
    tokens = result.tokens;
    latencyMs = result.latencyMs;
    proposals = parseGroupProposalResponse(result.text, candidates, PROPOSAL_COUNT);
  } catch (err: unknown) {
    failure = err instanceof Error ? err.message : String(err);
  }

  await client.from("ai_requests").insert({
    app_user_id: appUserId,
    model,
    tokens,
    latency_ms: latencyMs,
    ok: failure === null,
    error: failure,
  });
  if (failure !== null || !proposals) {
    console.error(`groups-propose failed: ${failure}`);
    throw new ApiError(ErrorCode.UPSTREAM_ERROR, "The recommendation service is unavailable");
  }
  return json({ proposals });
}));
