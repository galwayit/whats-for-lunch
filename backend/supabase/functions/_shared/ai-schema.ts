/** Portable JSON-schema subset accepted by all built-in adapters. Domain checks follow. */
const object = (properties: Record<string, unknown>) => ({
  type: "object",
  properties,
  required: Object.keys(properties),
  additionalProperties: false,
});
const number = { type: "number" };
const string = { type: "string" };
export const RECOMMENDATION_SCHEMA = object({
  recommendations: {
    type: "array",
    items: object({
      placeId: string,
      rank: { type: "integer" },
      confidenceScore: number,
      investmentScore: number,
      factorScores: object({
        budget: number,
        dietary: number,
        location: number,
        history: number,
        temporal: number,
        social: number,
      }),
    }),
  },
  reasoning: string,
  overallConfidence: number,
  investmentSummary: { type: ["string", "null"] },
});
export const GROUP_PROPOSAL_SCHEMA = object({
  proposals: {
    type: "array",
    items: object({ placeId: string, reasons: { type: "array", items: string } }),
  },
});
