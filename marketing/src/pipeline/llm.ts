import { createGateway, generateObject } from "ai";
import type { z } from "zod";

const DEFAULT_MODEL = "anthropic/claude-sonnet-5.5";

export function requireEnv(...names: string[]): string {
  for (const name of names) {
    const value = process.env[name]?.trim();
    if (value) return value;
  }
  throw new Error(`${names.join(" or ")} is not set. Add it to marketing/.env.`);
}

export async function complete<T>(schema: z.ZodType<T>, schemaName: string, system: string, prompt: string): Promise<T> {
  const apiKey = requireEnv("AI_GATEWAY_API_KEY", "AI_GATEWAY_KEY");
  const gateway = createGateway({ apiKey });
  const modelId = process.env.AI_GATEWAY_MODEL?.trim() || DEFAULT_MODEL;
  const { object } = await generateObject({
    model: gateway(modelId),
    schema,
    schemaName,
    system,
    prompt,
  });
  return object;
}
