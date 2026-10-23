/**
 * @file ai-recommend/index.ts
 * @description POST /ai-recommend: tier + daily quota, Provider ranking of the
 *   client's candidates, usage logging.
 */

import { aiDisclosure, loadAiConfig, requireConfiguredRoute } from "../_shared/ai-config.ts";
import { routeAi, serverRouterDependencies } from "../_shared/ai-router.ts";
import { RECOMMENDATION_SCHEMA } from "../_shared/ai-schema.ts";
import { refundAi, requireAiConsent, reserveAi } from "../_shared/ai-access.ts";
import { getUser, requireAppUserId } from "../_shared/auth.ts";
import {
  AI_BODY_LIMIT,
  ApiError,
  ErrorCode,
  handle,
  json,
  readJsonObject,
} from "../_shared/errors.ts";
import { buildRecommendationPrompt, parseRecommendationResponse } from "../_shared/prompt.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { tierFor } from "../_shared/tier.ts";
import { isChainRestaurant } from "../_shared/restaurant-chains.ts";
import { matchesDietary } from "../_shared/dietary.ts";
import { nowEpochSeconds, type RecommendationContext, type Restaurant } from "../_shared/types.ts";
import {
  optionalObject,
  optionalString,
  requireArray,
  requireInteger,
  requireObject,
  requireString,
  stringArray,
} from "../_shared/validate.ts";

const MAX_CANDIDATES = 20;

function parseContext(raw: Record<string, unknown>): RecommendationContext {
  return {
    mealType: requireString(raw, "mealType", 40),
    includeChains: raw.includeChains !== false,
    budgetRange: requireString(raw, "budgetRange", 40),
    dietaryPreferences: optionalObject(raw, "dietaryPreferences"),
    recentMeals: stringArray(raw.recentMeals).slice(0, 20),
    location: optionalObject(raw, "location"),
    temporal: optionalObject(raw, "temporal"),
    preferenceScores: Object.fromEntries(
      Object.entries(optionalObject(raw, "preferenceScores")).filter(
        (entry): entry is [string, number] => typeof entry[1] === "number",
      ),
    ),
  };
}

/** Candidates are trusted client-side Restaurant objects; only the id is checked. */
function parseCandidates(raw: unknown[]): Restaurant[] {
  const out: Restaurant[] = [];
  for (const item of raw) {
    if (typeof item !== "object" || item === null) continue;
    const candidate = item as Restaurant;
    if (typeof candidate.placeId === "string" && typeof candidate.name === "string") {
      out.push({
        ...candidate,
        cuisineTypes: stringArray(candidate.cuisineTypes),
        supportedDietaryRestrictions: stringArray(candidate.supportedDietaryRestrictions),
        features: stringArray(candidate.features),
        rating: typeof candidate.rating === "number" ? candidate.rating : null,
        reviewCount: typeof candidate.reviewCount === "number" ? candidate.reviewCount : null,
        priceLevel: typeof candidate.priceLevel === "number" ? candidate.priceLevel : null,
        averageMealCost: typeof candidate.averageMealCost === "number"
          ? candidate.averageMealCost
          : null,
        valueScore: typeof candidate.valueScore === "number" ? candidate.valueScore : null,
        distanceFromUser: typeof candidate.distanceFromUser === "number"
          ? candidate.distanceFromUser
          : null,
        address: typeof candidate.address === "string" ? candidate.address : null,
        location: typeof candidate.location === "string" ? candidate.location : "",
      });
    }
  }
  return out;
}

Deno.serve(handle(["POST"], async (req) => {
  const body = await readJsonObject(req, AI_BODY_LIMIT);
  const cravings = optionalString(body, "cravings", 200);
  const maxResults = requireInteger(body, "maxResults", 1, 10);
  const context = parseContext(requireObject(body, "context"));
  const candidates = parseCandidates(requireArray(body, "candidates", MAX_CANDIDATES))
    .filter((r) => context.includeChains !== false || !isChainRestaurant(r.name))
    .filter((r) =>
      matchesDietary(
        r,
        context.dietaryPreferences.restrictions,
        context.dietaryPreferences.allergies,
        context.dietaryPreferences.requireVerification !== false,
      )
    );
  if (candidates.length === 0) throw new ApiError(ErrorCode.BAD_REQUEST, "candidates is empty");

  const client = serviceClient();
  const user = await getUser(req);
  const appUserId = requireAppUserId(req, user);
  const tier = await tierFor(client, appUserId);

  const config = await loadAiConfig(client);
  requireAiConsent(body, (await aiDisclosure(config)).consentVersion);
  requireConfiguredRoute(config, (name) => Deno.env.get(name));
  const prompt = buildRecommendationPrompt({ context, cravings, maxResults, candidates });
  const requestId = await reserveAi(client, appUserId, tier);
  try {
    const recommendation = await routeAi(config, tier, prompt, RECOMMENDATION_SCHEMA, (text) => {
      const result = parseRecommendationResponse(text, candidates, {
        id: crypto.randomUUID(),
        userId: 0,
        generatedAtEpochSeconds: nowEpochSeconds(),
      });
      if (
        !result.restaurants.length || !result.reasoning.trim() || result.overallConfidence < 0 ||
        result.overallConfidence > 1
      ) throw new Error("Invalid recommendation");
      result.restaurants = [...new Map(result.restaurants.map((r) => [r.placeId, r])).values()]
        .slice(0, maxResults);
      return result;
    }, serverRouterDependencies(client, appUserId, requestId));
    return json({ recommendation });
  } catch (error) {
    await refundAi(client, appUserId, requestId);
    throw error;
  }
}));
