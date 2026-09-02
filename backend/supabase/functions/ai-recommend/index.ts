/**
 * @file ai-recommend/index.ts
 * @description POST /ai-recommend: tier + daily quota, Gemini ranking of the
 *   client's candidates, usage logging.
 */

import { getUser, requireAppUserId } from "../_shared/auth.ts";
import { ApiError, ErrorCode, handle, json, readJsonObject } from "../_shared/errors.ts";
import { generateJson, modelForTier } from "../_shared/gemini.ts";
import {
  buildRecommendationPrompt,
  ParseError,
  parseRecommendationResponse,
} from "../_shared/prompt.ts";
import { decideAiQuota, localDay, normaliseTimeZone } from "../_shared/quota.ts";
import { requireEnv, serviceClient } from "../_shared/supabase.ts";
import { tierFor } from "../_shared/tier.ts";
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
  const body = await readJsonObject(req);
  const cravings = optionalString(body, "cravings", 200);
  const maxResults = requireInteger(body, "maxResults", 1, 10);
  const context = parseContext(requireObject(body, "context"));
  const candidates = parseCandidates(requireArray(body, "candidates", MAX_CANDIDATES));
  if (candidates.length === 0) throw new ApiError(ErrorCode.BAD_REQUEST, "candidates is empty");

  const client = serviceClient();
  const user = await getUser(req);
  const appUserId = requireAppUserId(req, user);
  const tier = await tierFor(client, appUserId);
  const timeZone = normaliseTimeZone(req.headers.get("x-timezone"));
  const now = new Date();
  const day = localDay(now, timeZone);

  if (tier === "free") {
    const { data, error } = await client
      .from("usage")
      .select("ai_requests")
      .eq("app_user_id", appUserId)
      .eq("day", day)
      .maybeSingle();
    if (error) throw new Error(`database: ${error.message}`);
    const decision = decideAiQuota({ tier, usedToday: data?.ai_requests ?? 0, now, timeZone });
    if (!decision.allow) {
      throw new ApiError(ErrorCode.AI_DAILY_LIMIT, "Daily AI limit reached", {
        resetsAt: decision.resetsAt,
      });
    }
    const { error: incError } = await client.rpc("increment_ai_usage", {
      p_app_user_id: appUserId,
      p_day: day,
      p_delta: 1,
    });
    if (incError) throw new Error(`database: ${incError.message}`);
  }

  const model = modelForTier(tier);
  const prompt = buildRecommendationPrompt({ context, cravings, maxResults, candidates });
  let text = "";
  let tokens = 0;
  let latencyMs = 0;
  let failure: string | null = null;
  try {
    const result = await generateJson({ apiKey: requireEnv("GEMINI_API_KEY"), model, prompt });
    text = result.text;
    tokens = result.tokens;
    latencyMs = result.latencyMs;
  } catch (err: unknown) {
    failure = err instanceof Error ? err.message : String(err);
  }

  let recommendation = null;
  if (failure === null) {
    try {
      recommendation = parseRecommendationResponse(text, candidates, {
        id: crypto.randomUUID(),
        userId: 0,
        generatedAtEpochSeconds: nowEpochSeconds(),
      });
    } catch (err: unknown) {
      failure = err instanceof ParseError ? err.message : String(err);
    }
  }

  await client.from("ai_requests").insert({
    app_user_id: appUserId,
    model,
    tokens,
    latency_ms: latencyMs,
    ok: failure === null,
    error: failure,
  });

  if (failure !== null || recommendation === null) {
    if (tier === "free") {
      // Give the free request back: the user got nothing for it.
      await client.rpc("increment_ai_usage", { p_app_user_id: appUserId, p_day: day, p_delta: -1 });
    }
    console.error(`ai-recommend failed: ${failure}`);
    throw new ApiError(ErrorCode.UPSTREAM_ERROR, "The recommendation service is unavailable");
  }
  return json({ recommendation });
}));
