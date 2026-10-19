/**
 * @file prompt.ts
 * @description Ports `_buildRecommendationPrompt` and
 *   `_parseRecommendationResponse` from the Flutter AIService
 *   (archive/flutter/lib/services/ai_service.dart) byte-for-byte, plus the
 *   smaller prompt used by groups-propose. Everything here is pure.
 */

import type { AiRecommendation, RecommendationContext, Restaurant } from "./types.ts";

export interface RecommendationPromptInput {
  context: RecommendationContext;
  cravings: string | null;
  maxResults: number;
  candidates: Restaurant[];
}

/** Dart prints whole doubles with a trailing ".0"; keep the prompt identical. */
function dartDouble(value: number): string {
  return Number.isInteger(value) ? value.toFixed(1) : String(value);
}

/** `_formatPriceLevel` from ai_service.dart. */
export function formatPriceLevel(priceLevel: number | null): string {
  switch (priceLevel) {
    case 1:
      return "$ (Budget-friendly)";
    case 2:
      return "$$ (Moderate)";
    case 3:
      return "$$$ (Upscale)";
    case 4:
      return "$$$$ (Premium)";
    default:
      return "N/A";
  }
}

function restaurantBlock(r: Restaurant): string {
  const rating = r.rating === null ? "N/A" : dartDouble(r.rating);
  const avgCost = r.averageMealCost === null ? "N/A" : r.averageMealCost.toFixed(2);
  const valueScore = Math.round((r.valueScore ?? 0.5) * 100);
  const distance = r.distanceFromUser === null ? "N/A" : r.distanceFromUser.toFixed(1);
  return `
- ${r.name} (${r.placeId})
  Location: ${r.address ?? r.location}
  Rating: ${rating}/5 (${r.reviewCount ?? 0} reviews)
  Price Level: ${formatPriceLevel(r.priceLevel)}
  Average Cost: $${avgCost}
  Value Score: ${valueScore}%
  Cuisine: ${r.cuisineTypes.join(", ")}
  Dietary Support: ${r.supportedDietaryRestrictions.join(", ")}
  Features: ${r.features.join(", ")}
  Distance: ${distance} km
`;
}

/**
 * Builds the recommendation prompt. The text (including trailing spaces on
 * two lines and the blank line left by an absent cravings entry) matches the
 * Dart original so the model behaves the same.
 */
export function buildRecommendationPrompt(input: RecommendationPromptInput): string {
  const { context, cravings, maxResults } = input;
  const restaurants = input.candidates;
  const cravingsLine = cravings !== null ? `- Specific cravings: ${cravings}` : "";

  return `You are a food recommendation AI that helps users make investment-minded dining decisions. 
Your task is to recommend the best restaurants from the available options based on user context.
Restaurant names, cuisine, reviews and an empty allergen list are not evidence of allergy safety.
Never claim a venue or meal is allergen-free or safe for an allergy. Missing dietary data means unknown, not compatible.
If any dietary or allergy requirements are present, explain that ingredients and cross-contact must be confirmed directly with the venue.

USER CONTEXT:
- Current meal type: ${context.mealType}
- Budget range: ${context.budgetRange}
- Dietary preferences: ${JSON.stringify(context.dietaryPreferences)}
- Recent meals: ${context.recentMeals.slice(0, 5).join(", ")}
- Location: ${JSON.stringify(context.location)}
- Time context: ${JSON.stringify(context.temporal)}
- Preference scores: ${JSON.stringify(context.preferenceScores)}
${cravingsLine}

AVAILABLE RESTAURANTS (${restaurants.length} options):
${restaurants.slice(0, 20).map(restaurantBlock).join("\n")}

RECOMMENDATION CRITERIA (weighted importance):
1. Budget Compatibility (25%): Match user's budget range with restaurant pricing
2. Dietary Compatibility (25%): Match dietary restrictions and preferences  
3. Location Convenience (20%): Prefer closer restaurants, consider travel time
4. Historical Preferences (15%): Learn from past selections and ratings
5. Temporal Relevance (10%): Consider time of day, day of week patterns
6. Social Validation (5%): Factor in ratings and review counts

INVESTMENT MINDSET MESSAGING:
- Frame costs as "investment opportunities" not expenses
- Emphasize value scores and cost-effectiveness
- Highlight long-term satisfaction potential
- Use positive psychology in cost discussions

RESPONSE FORMAT (JSON):
{
  "recommendations": [
    {
      "placeId": "restaurant_place_id",
      "rank": 1,
      "confidenceScore": 0.85,
      "investmentScore": 0.90,
      "factorScores": {
        "budget": 0.9,
        "dietary": 0.8,
        "location": 0.7,
        "history": 0.6,
        "temporal": 0.8,
        "social": 0.7
      }
    }
  ],
  "reasoning": "Clear explanation of why these restaurants were selected, emphasizing investment mindset and value proposition",
  "overallConfidence": 0.82,
  "investmentSummary": "Brief summary of the investment opportunity and expected value"
}

Recommend up to ${maxResults} restaurants, ranked by overall suitability.
Focus on providing clear reasoning that builds trust and explains the value proposition.
`;
}

/** Strips a ```json fence if the model wrapped its output despite the MIME type. */
export function stripJsonFence(text: string): string {
  const trimmed = text.trim();
  const match = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/);
  return match ? match[1] : trimmed;
}

export interface ParseMeta {
  id: string;
  userId: number;
  generatedAtEpochSeconds: number;
}

export class ParseError extends Error {
  constructor(message: string) {
    super(`Failed to parse AI response: ${message}`);
    this.name = "ParseError";
  }
}

function asNumber(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new ParseError(`${field} is not a number`);
  }
  return value;
}

/**
 * Port of `_parseRecommendationResponse`: keeps only place ids present in the
 * candidates (in the model's ranked order) and takes factor weights from the
 * first recommendation that has `factorScores`.
 * @throws ParseError when the payload is not the documented shape.
 */
export function parseRecommendationResponse(
  responseText: string,
  candidates: Restaurant[],
  meta: ParseMeta,
): AiRecommendation {
  // `any` at the JSON boundary: the model output is validated field by field below.
  // deno-lint-ignore no-explicit-any
  let parsed: any;
  try {
    parsed = JSON.parse(stripJsonFence(responseText));
  } catch (err: unknown) {
    throw new ParseError(err instanceof Error ? err.message : "invalid JSON");
  }
  if (typeof parsed !== "object" || parsed === null || !Array.isArray(parsed.recommendations)) {
    throw new ParseError("missing recommendations array");
  }

  const byId = new Map(candidates.map((c) => [c.placeId, c]));
  const restaurants: Restaurant[] = [];
  const factorWeights: Record<string, number> = {};

  for (const rec of parsed.recommendations) {
    if (typeof rec !== "object" || rec === null) continue;
    const restaurant = typeof rec.placeId === "string" ? byId.get(rec.placeId) : undefined;
    if (!restaurant) continue; // hallucinated or no longer available
    restaurants.push(restaurant);
    if (
      Object.keys(factorWeights).length === 0 && rec.factorScores &&
      typeof rec.factorScores === "object"
    ) {
      for (const [key, value] of Object.entries(rec.factorScores)) {
        if (typeof value === "number" && Number.isFinite(value)) factorWeights[key] = value;
      }
    }
  }

  if (typeof parsed.reasoning !== "string") throw new ParseError("reasoning is not a string");

  return {
    id: meta.id,
    userId: meta.userId,
    restaurants,
    reasoning: parsed.reasoning,
    factorWeights,
    overallConfidence: asNumber(parsed.overallConfidence, "overallConfidence"),
    investmentSummary: typeof parsed.investmentSummary === "string"
      ? parsed.investmentSummary
      : null,
    generatedAtEpochSeconds: meta.generatedAtEpochSeconds,
    wasAccepted: false,
    userFeedback: null,
  };
}

/* ---------- Group proposals (groups-propose) ---------- */

export interface GroupProposalPromptInput {
  groupName: string;
  scheduledAtIso: string;
  hostPreferences: Record<string, unknown>;
  pastPicks: string[];
  candidates: Restaurant[];
  count: number;
}

export function buildGroupProposalPrompt(input: GroupProposalPromptInput): string {
  const past = input.pastPicks.length > 0 ? input.pastPicks.join(", ") : "none";
  return `You are helping a host choose where a group should have lunch.

GROUP: ${input.groupName}, scheduled ${input.scheduledAtIso}
HOST PREFERENCES: ${JSON.stringify(input.hostPreferences)}
PLACES THIS GROUP PICKED BEFORE: ${past}

CANDIDATE RESTAURANTS (${input.candidates.length} options):
${input.candidates.slice(0, 20).map(restaurantBlock).join("\n")}

Pick the ${input.count} best places for a group, favouring variety over past picks, dietary
flexibility, and good ratings. Respond with JSON only:
{
  "proposals": [
    { "placeId": "restaurant_place_id", "reasons": ["short reason", "short reason"] }
  ]
}
`;
}

export interface ParsedProposal {
  restaurant: Restaurant;
  reasons: string[];
}

/** Keeps only candidate place ids, in ranked order, with up to three reasons each. */
export function parseGroupProposalResponse(
  responseText: string,
  candidates: Restaurant[],
  count: number,
): ParsedProposal[] {
  // deno-lint-ignore no-explicit-any
  let parsed: any;
  try {
    parsed = JSON.parse(stripJsonFence(responseText));
  } catch (err: unknown) {
    throw new ParseError(err instanceof Error ? err.message : "invalid JSON");
  }
  if (typeof parsed !== "object" || parsed === null || !Array.isArray(parsed.proposals)) {
    throw new ParseError("missing proposals array");
  }
  const byId = new Map(candidates.map((c) => [c.placeId, c]));
  const out: ParsedProposal[] = [];
  for (const item of parsed.proposals) {
    if (out.length >= count) break;
    if (typeof item !== "object" || item === null) continue;
    const restaurant = typeof item.placeId === "string" ? byId.get(item.placeId) : undefined;
    if (!restaurant || out.some((p) => p.restaurant.placeId === restaurant.placeId)) continue;
    const reasons = Array.isArray(item.reasons)
      ? item.reasons.filter((r: unknown): r is string => typeof r === "string").slice(0, 3)
      : [];
    out.push({ restaurant, reasons });
  }
  return out;
}
