/**
 * @file groups-propose/index.ts
 * @description POST /groups-propose (auth, host): three AI-ranked places
 *   near the group area using the host's preferences and past picks.
 */

import { aiDisclosure, loadAiConfig, requireConfiguredRoute } from "../_shared/ai-config.ts";
import { routeAi, serverRouterDependencies } from "../_shared/ai-router.ts";
import { GROUP_PROPOSAL_SCHEMA } from "../_shared/ai-schema.ts";
import { refundAi, requireAiConsent, reserveAi } from "../_shared/ai-access.ts";
import { requireAppUserId, requireUser } from "../_shared/auth.ts";
import { safetyContext } from "../_shared/content-safety.ts";
import { matchesDietary } from "../_shared/dietary.ts";
import { ApiError, ErrorCode, handle, json, readJsonObject } from "../_shared/errors.ts";
import { nearbyRestaurants } from "../_shared/nearby.ts";
import { buildGroupProposalPrompt, parseGroupProposalResponse } from "../_shared/prompt.ts";
import { functionsBaseUrl, requireEnv, serviceClient, unwrap } from "../_shared/supabase.ts";
import { requirePro } from "../_shared/tier.ts";
import type { GroupRow } from "../_shared/types.ts";
import { isChainRestaurant } from "../_shared/restaurant-chains.ts";
import { optionalObject, requireUuid } from "../_shared/validate.ts";

const PROPOSAL_COUNT = 3;

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req);
  const groupId = requireUuid(body, "groupId");
  const hostPreferences = optionalObject(body, "hostPreferences");

  const user = await requireUser(req);
  const client = serviceClient();
  await safetyContext(client, groupId, user.id, null);
  const appUserId = requireAppUserId(req, user);
  await requirePro(client, appUserId);

  const { data: group, error } = await client.from("groups").select("*").eq("id", groupId)
    .maybeSingle();
  if (error) throw new Error(`database: ${error.message}`);
  if (!group) throw new ApiError(ErrorCode.NOT_FOUND, "Group not found");
  const row = group as GroupRow;
  if (row.host_id !== user.id) throw new ApiError(ErrorCode.FORBIDDEN, "Only the host can propose");

  const config = await loadAiConfig(client);
  requireAiConsent(body, (await aiDisclosure(config)).consentVersion);
  requireConfiguredRoute(config, (name) => Deno.env.get(name));
  const requestId = await reserveAi(client, appUserId, "pro");
  try {
    const { restaurants } = await nearbyRestaurants(
      {
        lat: Number(row.area_lat),
        lng: Number(row.area_lng),
        radiusKm: Number(row.radius_km),
        query: "",
      },
      { client, apiKey: requireEnv("GOOGLE_PLACES_API_KEY"), functionsBase: functionsBaseUrl() },
    );
    const candidates = restaurants.filter((r) =>
      hostPreferences.includeChains !== false || !isChainRestaurant(r.name)
    ).filter((r) =>
      matchesDietary(
        r,
        hostPreferences.dietaryRestrictions,
        hostPreferences.allergens,
        hostPreferences.requireDietaryVerification !== false,
      )
    ).slice(0, 20);
    if (candidates.length === 0) {
      await refundAi(client, appUserId, requestId);
      return json({ proposals: [] });
    }

    const pastRows = unwrap(
      await client
        .from("groups")
        .select("place_name")
        .eq("host_id", user.id)
        .not("place_name", "is", null)
        .order("scheduled_at", { ascending: false })
        .limit(10),
    ) as { place_name: string }[];

    const prompt = buildGroupProposalPrompt({
      groupName: row.name,
      scheduledAtIso: row.scheduled_at,
      hostPreferences,
      pastPicks: pastRows.map((r) => r.place_name),
      candidates,
      count: PROPOSAL_COUNT,
    });

    const proposals = await routeAi(config, "pro", prompt, GROUP_PROPOSAL_SCHEMA, (text) => {
      const result = parseGroupProposalResponse(text, candidates, PROPOSAL_COUNT);
      if (
        !result.length || result.some((p) => !p.reasons.length || p.reasons.some((r) => !r.trim()))
      ) throw new Error("Invalid proposals");
      return result;
    }, serverRouterDependencies(client, appUserId, requestId));
    return json({ proposals });
  } catch (error) {
    await refundAi(client, appUserId, requestId);
    throw error;
  }
}));
