/** Only the consent disclosure is public; no models, endpoints, limits or secrets. */
import { aiDisclosure, loadAiConfig, requireConfiguredRoute } from "../_shared/ai-config.ts";
import { handle, json } from "../_shared/errors.ts";
import { serviceClient } from "../_shared/supabase.ts";
Deno.serve(handle(["GET"], async () => {
  const config = await loadAiConfig(serviceClient());
  requireConfiguredRoute(config, (name) => Deno.env.get(name));
  return json(await aiDisclosure(config), 200, { "Cache-Control": "no-store" });
}));
