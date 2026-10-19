/** Small provider adapters; no SDK retries, redirects, prompt logging or client secrets. */
import type { AiProvider } from "./ai-config.ts";
import type { Tier } from "./types.ts";
export type JsonSchema = Record<string, unknown>;
export class ProviderFailure extends Error {
  constructor(readonly reason: string, readonly canFallback = true, readonly status?: number) {
    super(reason);
    this.name = "ProviderFailure";
  }
}
function records(value: unknown): Record<string, unknown>[] {
  return Array.isArray(value)
    ? value.filter((item): item is Record<string, unknown> =>
      item !== null && typeof item === "object" && !Array.isArray(item)
    )
    : [];
}
function partText(part: Record<string, unknown>): string {
  return typeof part.text === "string" ? part.text : "";
}

export interface ProviderResult {
  text: string;
  tokens: number;
}
function tokenCount(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 ? Math.floor(value) : 0;
}
export async function callAiProvider(
  provider: AiProvider,
  tier: Tier,
  apiKey: string,
  prompt: string,
  schema: JsonSchema,
  signal: AbortSignal,
  fetchImpl: typeof fetch = fetch,
): Promise<ProviderResult> {
  const model = provider.models[tier];
  let endpoint: string;
  let body: Record<string, unknown>;
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  switch (provider.kind) {
    case "google":
      endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${
        encodeURIComponent(model)
      }:generateContent`;
      headers["x-goog-api-key"] = apiKey;
      body = {
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: {
          maxOutputTokens: provider.maxOutputTokens,
          responseMimeType: "application/json",
          responseJsonSchema: schema,
          ...(model.startsWith("gemini-2.5-") ? { thinkingConfig: { thinkingBudget: 0 } } : {}),
        },
      };
      break;
    case "openai":
      endpoint = "https://api.openai.com/v1/responses";
      headers.Authorization = `Bearer ${apiKey}`;
      body = {
        model,
        input: [{ role: "user", content: prompt }],
        store: false,
        max_output_tokens: provider.maxOutputTokens,
        text: { format: { type: "json_schema", name: "lunch_picks", strict: true, schema } },
      };
      break;
    case "anthropic":
      endpoint = "https://api.anthropic.com/v1/messages";
      headers["x-api-key"] = apiKey;
      headers["anthropic-version"] = "2023-06-01";
      body = {
        model,
        max_tokens: provider.maxOutputTokens,
        messages: [{ role: "user", content: prompt }],
        output_config: { format: { type: "json_schema", schema } },
      };
      break;
    case "openai-compatible":
      endpoint = provider.endpoint!;
      headers.Authorization = `Bearer ${apiKey}`;
      body = {
        model,
        messages: [{ role: "user", content: prompt }],
        max_tokens: provider.maxOutputTokens,
        response_format: {
          type: "json_schema",
          json_schema: { name: "lunch_picks", strict: true, schema },
        },
      };
      break;
  }
  let response: Response;
  try {
    response = await fetchImpl(endpoint, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
      signal,
      redirect: "error",
    });
  } catch {
    throw new ProviderFailure(signal.aborted ? "timeout" : "network");
  }
  if (!response.ok) {
    await response.body?.cancel();
    // Never echo upstream bodies: they can contain secrets or personal prompt data.
    // Configuration failures also merit the independent backup; bad requests do not.
    throw new ProviderFailure(
      `http_${response.status}`,
      [401, 402, 403, 404, 408, 429].includes(response.status) || response.status >= 500,
      response.status,
    );
  }
  // Provider payloads are untrusted JSON. Parse only bounded bodies and known fields.
  let raw = "";
  const reader = response.body?.getReader();
  try {
    if (!reader) throw new ProviderFailure("empty_response");
    const decoder = new TextDecoder();
    let bytes = 0;
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      bytes += value.byteLength;
      if (bytes > 128 * 1024) {
        await reader.cancel();
        throw new ProviderFailure("oversized_response");
      }
      raw += decoder.decode(value, { stream: true });
    }
    raw += decoder.decode();
  } catch (error) {
    if (error instanceof ProviderFailure) throw error;
    throw new ProviderFailure(signal.aborted ? "timeout" : "network");
  } finally {
    reader?.releaseLock();
  }
  // deno-lint-ignore no-explicit-any
  let payload: any;
  try {
    payload = JSON.parse(raw);
  } catch {
    throw new ProviderFailure("invalid_json");
  }
  let output: unknown;
  let tokens = 0;
  if (provider.kind === "google") {
    const candidate = payload?.candidates?.[0];
    if (
      payload?.promptFeedback?.blockReason ||
      ["SAFETY", "BLOCKLIST", "PROHIBITED_CONTENT", "RECITATION", "SPII", "IMAGE_SAFETY"].includes(
        candidate?.finishReason,
      )
    ) throw new ProviderFailure("refusal", false);
    if (candidate?.finishReason !== "STOP") throw new ProviderFailure("incomplete");
    output = records(candidate?.content?.parts).filter((p) => !p.thought).map(partText).join("");
    tokens = tokenCount(payload?.usageMetadata?.totalTokenCount);
  } else if (provider.kind === "openai") {
    const messages = records(payload?.output).filter((o) => o.type === "message");
    const content = messages.flatMap((m) => records(m.content));
    if (content.some((c: { type?: string }) => c.type === "refusal")) {
      throw new ProviderFailure("refusal", false);
    }
    if (payload?.status !== "completed") throw new ProviderFailure("incomplete");
    output = content.filter((c) => c.type === "output_text").map(partText).join("");
    tokens = tokenCount(payload?.usage?.total_tokens);
  } else if (provider.kind === "anthropic") {
    if (payload?.stop_reason === "refusal") throw new ProviderFailure("refusal", false);
    if (payload?.stop_reason !== "end_turn") throw new ProviderFailure("incomplete");
    output = records(payload?.content).filter((c) => c.type === "text").map(partText).join("");
    tokens = tokenCount(payload?.usage?.input_tokens) + tokenCount(payload?.usage?.output_tokens);
  } else {
    const choice = payload?.choices?.[0];
    if (choice?.message?.refusal || choice?.finish_reason === "content_filter") {
      throw new ProviderFailure("refusal", false);
    }
    if (choice?.finish_reason !== "stop") throw new ProviderFailure("incomplete");
    output = choice?.message?.content;
    tokens = tokenCount(payload?.usage?.total_tokens);
  }
  if (typeof output !== "string" || !output.trim()) throw new ProviderFailure("empty_output");
  return { text: output, tokens };
}
