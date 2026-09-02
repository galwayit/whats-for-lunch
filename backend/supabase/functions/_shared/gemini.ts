/**
 * @file gemini.ts
 * @description Minimal Gemini `generateContent` client (JSON mode) and the
 *   tier -> model selection from API.md.
 */

import type { Tier } from "./types.ts";

export const GEMINI_MODELS: Record<Tier, string> = {
  free: "gemini-2.5-flash-lite",
  pro: "gemini-2.5-flash",
};

export function modelForTier(tier: Tier): string {
  return GEMINI_MODELS[tier];
}

export interface GeminiRequest {
  apiKey: string;
  model: string;
  prompt: string;
  temperature?: number;
  maxOutputTokens?: number;
}

export interface GeminiResult {
  text: string;
  /** `usageMetadata.totalTokenCount`, 0 when the API omits it. */
  tokens: number;
  latencyMs: number;
}

export class GeminiError extends Error {
  readonly status: number;
  constructor(status: number, message: string) {
    super(message);
    this.name = "GeminiError";
    this.status = status;
  }
}

const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/models";

/**
 * Calls generateContent with `responseMimeType: application/json`.
 * @throws GeminiError on a non-2xx response or an empty candidate list.
 */
export async function generateJson(
  request: GeminiRequest,
  fetchImpl: typeof fetch = fetch,
): Promise<GeminiResult> {
  const started = performance.now();
  const response = await fetchImpl(`${GEMINI_BASE}/${request.model}:generateContent`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": request.apiKey,
    },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: request.prompt }] }],
      generationConfig: {
        temperature: request.temperature ?? 0.7,
        maxOutputTokens: request.maxOutputTokens ?? 1000,
        responseMimeType: "application/json",
      },
    }),
  });
  const latencyMs = Math.round(performance.now() - started);

  if (!response.ok) {
    // The error body can echo request details; log only the status.
    await response.body?.cancel();
    throw new GeminiError(response.status, `Gemini responded ${response.status}`);
  }
  // `any` at the JSON boundary: only the fields read below are relied upon.
  // deno-lint-ignore no-explicit-any
  const payload: any = await response.json();
  const parts: unknown[] = payload?.candidates?.[0]?.content?.parts ?? [];
  const text = parts
    .map((p) => (typeof p === "object" && p !== null && "text" in p ? String(p.text) : ""))
    .join("");
  if (text.length === 0) {
    throw new GeminiError(502, "Gemini returned no text candidate");
  }
  const tokens = typeof payload?.usageMetadata?.totalTokenCount === "number"
    ? payload.usageMetadata.totalTokenCount
    : 0;
  return { text, tokens, latencyMs };
}
