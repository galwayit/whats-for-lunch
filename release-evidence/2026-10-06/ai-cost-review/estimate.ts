/** Read-only cost model. Uses fictional fixtures and the real prompt builders; no API calls. */
import { buildGroupProposalPrompt, buildRecommendationPrompt } from "../../../backend/supabase/functions/_shared/prompt.ts";
import { GROUP_PROPOSAL_SCHEMA, RECOMMENDATION_SCHEMA } from "../../../backend/supabase/functions/_shared/ai-schema.ts";
import { fixtureCandidates, fixtureContext } from "../../../backend/supabase/functions/_shared/__fixtures__/fixtures.ts";

const candidates = Array.from({ length: 20 }, (_, i) => ({
  ...fixtureCandidates[i % fixtureCandidates.length],
  placeId: `fictionalPlaceIdentifier${String(i).padStart(4, "0")}`,
  name: `Fictional Lunch Place ${i + 1}`,
}));
const sizes = (label: string, prompt: string, schema: Record<string, unknown>) => {
  const schemaChars = JSON.stringify(schema).length;
  const chars = prompt.length + schemaChars;
  return {
    label,
    prompt_chars: prompt.length,
    schema_chars: schemaChars,
    approximate_input_tokens: [Math.ceil(chars / 4), Math.ceil(chars / 3)],
  };
};
const promptSizes = [
  sizes("why_this", buildRecommendationPrompt({ context: fixtureContext, cravings: null, maxResults: 3, candidates: candidates.slice(0, 1) }), RECOMMENDATION_SCHEMA),
  sizes("ask_ai", buildRecommendationPrompt({ context: fixtureContext, cravings: "Something light, nearby, within my budget", maxResults: 3, candidates }), RECOMMENDATION_SCHEMA),
  sizes("group_proposals", buildGroupProposalPrompt({ groupName: "Fictional team lunch", scheduledAtIso: "2026-10-06T02:00:00Z", hostPreferences: { budgetLevel: 2, dietaryRestrictions: ["vegetarian"], allergens: [], maxTravelDistance: 2 }, pastPicks: ["Fictional cafe one", "Fictional cafe two"], candidates, count: 3 }), GROUP_PROPOSAL_SCHEMA),
];
const rates = {
  openai: { model: "gpt-6-luna", input: 0.10, cached_input: 0.01, cache_write: 0.125, output: 0.50, source: "https://developers.openai.com/api/docs/pricing" },
  google: { model: "gemini-3.8-flash", input: 0.75, output: 3.75, valid_through: "2026-12-31", source: "https://ai.google.dev/gemini-api/docs/generate-content/latest-model" },
  google_2027: { model: "gemini-3.8-flash", input: 1.50, output: 7.50, valid_from: "2027-01-01", source: "https://ai.google.dev/gemini-api/docs/generate-content/latest-model" },
  claude: { model: "claude-haiku-4-5", input: 1, output: 5, source: "https://platform.claude.com/docs/en/models/haiku-4-5/overview" },
};
const cost = (input: number, output: number, inputRate: number, outputRate: number) => (input * inputRate + output * outputRate) / 1_000_000;
const operations = [
  { name: "why_this", input_tokens: 1500, output_tokens_including_reasoning: 500 },
  { name: "ask_ai", input_tokens: 4000, output_tokens_including_reasoning: 1000 },
  { name: "group_proposals", input_tokens: 3000, output_tokens_including_reasoning: 800 },
  { name: "ask_ai_at_output_cap", input_tokens: 4000, output_tokens_including_reasoning: 2048 },
].map((op) => ({
  ...op,
  openai_usd_per_request: cost(op.input_tokens, op.output_tokens_including_reasoning, rates.openai.cache_write, rates.openai.output),
  openai_usd_per_1000_requests: cost(op.input_tokens, op.output_tokens_including_reasoning, rates.openai.cache_write, rates.openai.output) * 1000,
}));
const fullAsk = operations.find((x) => x.name === "ask_ai")!;
const googleAsk = cost(4000, 1000, rates.google.input, rates.google.output);
const monthly = [30, 90, 300, 30_000].map((requests) => ({
  requests,
  openai_usd: requests * fullAsk.openai_usd_per_request,
  google_usd_if_every_request_uses_backup: requests * googleAsk,
}));
console.log(JSON.stringify({
  assessed_on: "2026-10-06",
  currency: "USD",
  methodology: "Forecast, not observed provider charges. Prompt size ranges use characters/4 to characters/3, not an exact tokenizer; provider framing is excluded. Operation budgets add headroom. All assumed output tokens include reasoning. OpenAI estimates conservatively price all input at the cache-write rate without also charging the base input rate. No cache-read savings, tax, FX, app-store fees, backend, Places or photos included in AI estimates.",
  rates_per_million_tokens: rates,
  prompt_sizes: promptSizes,
  operations,
  monthly,
  comparisons_per_1000_full_asks: {
    openai_uncached_input: cost(4000, 1000, rates.openai.input, rates.openai.output) * 1000,
    openai_cache_write_input: fullAsk.openai_usd_per_request * 1000,
    google_2026: googleAsk * 1000,
    google_2027: cost(4000, 1000, rates.google_2027.input, rates.google_2027.output) * 1000,
    claude: cost(4000, 1000, rates.claude.input, rates.claude.output) * 1000,
    openai_plus_5_percent_google_failover: (fullAsk.openai_usd_per_request + 0.05 * googleAsk) * 1000,
  },
  places_example: {
    basis: "Global list pricing, first paid volume tier, after shared billing-account free caps; assumes one fresh Nearby Enterprise request for every full Ask AI or group action.",
    nearby_usd_per_request: 0.035,
    details_with_reviews_usd_per_request: 0.025,
    photo_usd_per_request: 0.007,
    free_monthly_events_per_relevant_sku: 1000,
    source: "https://developers.google.com/maps/billing-and-pricing/pricing",
    marginal_nearby_usd_for_300_operations: 300 * 0.035,
    account_example_30000_nearby_requests_usd: (30_000 - 1000) * 0.035,
  },
}, null, 2));
