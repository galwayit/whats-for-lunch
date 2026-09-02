import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { EXPECTED_PROMPT } from "./__fixtures__/expected_prompt.ts";
import { fixtureCandidates, fixtureContext } from "./__fixtures__/fixtures.ts";
import geminiResponse from "./__fixtures__/gemini_response.json" with { type: "json" };
import {
  buildGroupProposalPrompt,
  buildRecommendationPrompt,
  ParseError,
  parseGroupProposalResponse,
  parseRecommendationResponse,
  stripJsonFence,
} from "./prompt.ts";

Deno.test("buildRecommendationPrompt matches the Dart snapshot", () => {
  const prompt = buildRecommendationPrompt({
    context: fixtureContext,
    cravings: "something light",
    maxResults: 3,
    candidates: fixtureCandidates,
  });
  assertEquals(prompt, EXPECTED_PROMPT);
});

Deno.test("buildRecommendationPrompt leaves an empty line when there are no cravings", () => {
  const prompt = buildRecommendationPrompt({
    context: fixtureContext,
    cravings: null,
    maxResults: 3,
    candidates: fixtureCandidates,
  });
  assertEquals(
    prompt.includes(
      '- Preference scores: {"price_sensitivity":0.7,"variety_seeking":0.5}\n\n\nAVAILABLE',
    ),
    true,
  );
  assertEquals(prompt.includes("Specific cravings"), false);
});

Deno.test("buildRecommendationPrompt caps the list at 20 restaurants but reports the full count", () => {
  const many = Array.from(
    { length: 25 },
    (_, i) => ({ ...fixtureCandidates[0], placeId: `p${i}`, name: `R${i}` }),
  );
  const prompt = buildRecommendationPrompt({
    context: fixtureContext,
    cravings: null,
    maxResults: 3,
    candidates: many,
  });
  assertEquals(prompt.includes("(25 options)"), true);
  assertEquals(prompt.includes("(p19)"), true);
  assertEquals(prompt.includes("(p20)"), false);
});

const meta = { id: "rec-1", userId: 0, generatedAtEpochSeconds: 1725250000 };

Deno.test("parseRecommendationResponse drops hallucinated place ids and keeps rank order", () => {
  const rec = parseRecommendationResponse(JSON.stringify(geminiResponse), fixtureCandidates, meta);
  assertEquals(rec.restaurants.map((r) => r.placeId), [
    "ChIJrTLr-GyuEmsRBfy61i59si0",
    "ChIJN1t_tDeuEmsRUsoyG83frY4",
  ]);
  assertEquals(rec.reasoning, geminiResponse.reasoning);
  assertEquals(rec.overallConfidence, 0.82);
  assertEquals(rec.investmentSummary, geminiResponse.investmentSummary);
  assertEquals(rec.id, "rec-1");
  assertEquals(rec.wasAccepted, false);
  assertEquals(rec.userFeedback, null);
});

Deno.test("parseRecommendationResponse takes factor weights from the first recommendation only", () => {
  const rec = parseRecommendationResponse(JSON.stringify(geminiResponse), fixtureCandidates, meta);
  assertEquals(rec.factorWeights, geminiResponse.recommendations[0].factorScores);
});

Deno.test("parseRecommendationResponse tolerates a json code fence", () => {
  const fenced = "```json\n" + JSON.stringify(geminiResponse) + "\n```";
  const rec = parseRecommendationResponse(fenced, fixtureCandidates, meta);
  assertEquals(rec.restaurants.length, 2);
});

Deno.test("parseRecommendationResponse rejects malformed payloads", () => {
  assertThrows(() => parseRecommendationResponse("not json", fixtureCandidates, meta), ParseError);
  assertThrows(
    () => parseRecommendationResponse('{"reasoning":"x"}', fixtureCandidates, meta),
    ParseError,
  );
  assertThrows(
    () =>
      parseRecommendationResponse(
        '{"recommendations":[],"reasoning":"x"}',
        fixtureCandidates,
        meta,
      ),
    ParseError,
    "overallConfidence",
  );
});

Deno.test("stripJsonFence only strips a wrapping fence", () => {
  assertEquals(stripJsonFence("```json\n{}\n```"), "{}");
  assertEquals(stripJsonFence('  {"a":1} '), '{"a":1}');
});

Deno.test("group proposal prompt and parser round-trip candidates", () => {
  const prompt = buildGroupProposalPrompt({
    groupName: "Friday team lunch",
    scheduledAtIso: "2026-09-04T02:00:00Z",
    hostPreferences: { cuisinePreferences: ["Japanese"] },
    pastPicks: ["Sushi Rocks"],
    candidates: fixtureCandidates,
    count: 3,
  });
  assertEquals(prompt.includes("PLACES THIS GROUP PICKED BEFORE: Sushi Rocks"), true);
  const parsed = parseGroupProposalResponse(
    JSON.stringify({
      proposals: [
        { placeId: "ChIJ7cv00DwsDogRAMDACa2i4K8", reasons: ["central", "cheap", "quick", "extra"] },
        { placeId: "nope", reasons: ["x"] },
        { placeId: "ChIJ7cv00DwsDogRAMDACa2i4K8", reasons: ["duplicate"] },
        { placeId: "ChIJN1t_tDeuEmsRUsoyG83frY4", reasons: [] },
      ],
    }),
    fixtureCandidates,
    3,
  );
  assertEquals(parsed.map((p) => p.restaurant.name), ["Pitt Street Canteen", "Trattoria Bridge"]);
  assertEquals(parsed[0].reasons, ["central", "cheap", "quick"]);
});
