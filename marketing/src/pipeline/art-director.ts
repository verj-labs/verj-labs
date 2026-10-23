import { complete } from "./llm";
import { artSchema, type ArtDraft, type Brand, type DirectorOutput } from "./types";

export async function artDirect(brand: Brand, director: DirectorOutput): Promise<ArtDraft> {
  const system = [
    "You are the art director for a fixed 9:16 template called ProofReel.",
    "Turn each director beat into one shot. Cover every beat id exactly once.",
    "type: big text, no generated media. Use this for the hook, the cta, and any claim that has no matching proof file.",
    "proof: a real file from the brand kit. Use it only when the beat is a claim and a proof id fits. Set proofId to that id.",
    "generate: atmosphere and b-roll only. At most 3 shots in the whole video. Never on a claim, the hook, or the cta.",
    "reason is one sentence: why this shot is type, proof, or generate.",
    "For a generate shot, prompt is the opening frame and endPrompt is the closing frame about five seconds later.",
    "The opening and closing frames share the subject, place, and light. The difference between them is the motion.",
    "Generate prompts are one or two concrete photographic sentences for a vertical frame.",
    "No text, logos, watermarks, or fake product screenshots in a generate prompt.",
    `Never depict: ${brand.bannedLooks.join(", ")}.`,
    "proofId is null unless type is proof. prompt and endPrompt are empty strings unless type is generate.",
    "Keep onScreenText and spokenLine from the director unless a line is too long to sit in a phone safe zone. Hook text stays within 8 words. Overlay text on proof or generate shots stays within 8 words.",
  ].join("\n");

  const prompt = [
    `Colors: background ${brand.colors.bg}, text ${brand.colors.fg}, accent ${brand.colors.accent}.`,
    `Type: ${brand.type.display} for display, ${brand.type.body} for text, ${brand.type.mono} for labels.`,
    `Proof files: ${JSON.stringify(brand.proof)}`,
    `Beats: ${JSON.stringify(director.beats)}`,
  ].join("\n\n");

  let feedback = "";
  let lastError = "Art direction failed.";
  for (let attempt = 0; attempt < 2; attempt += 1) {
    try {
      return await complete(artSchema, "ArtDirection", system, `${prompt}${feedback}`);
    } catch (error) {
      lastError = error instanceof Error ? error.message : lastError;
      feedback = `\n\nYour previous output was rejected: ${lastError}\nFix it.`;
    }
  }
  throw new Error(lastError);
}
