/** Validate a non-secret configuration and optionally produce reviewable SQL. */
import {
  aiDisclosure,
  parseAiConfig,
} from "../supabase/functions/_shared/ai-config.ts";
const path = Deno.args.find((arg) => !arg.startsWith("--"));
if (!path || Deno.args.some((arg) => arg.startsWith("--") && arg !== "--sql")) {
  console.error(
    "Usage: deno run --allow-read scripts/ai-parameters.ts config.json [--sql]",
  );
  Deno.exit(1);
}
try {
  const raw = JSON.parse(await Deno.readTextFile(path));
  const config = parseAiConfig(raw);
  if (Deno.args.includes("--sql")) {
    const literal = JSON.stringify(raw).replaceAll("'", "''");
    console.log(
      `UPDATE public.system_parameters SET value = '${literal}'::jsonb WHERE key = 'ai.providers';`,
    );
  } else {
    console.log(
      JSON.stringify(
        {
          valid: true,
          enabled: config.enabled,
          primary: config.primary,
          backup: config.backup,
          disclosure: await aiDisclosure(config),
        },
        null,
        2,
      ),
    );
  }
} catch {
  // Do not echo invalid input: an operator may have accidentally entered a credential.
  console.error(
    "Invalid AI configuration. Check AI_PROVIDERS.md; API keys must only go in Supabase Secrets.",
  );
  Deno.exit(1);
}
