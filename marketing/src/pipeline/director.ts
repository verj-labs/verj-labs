import { complete } from "./llm";
import { directorSchema, type Brand, type DirectorDraft, type DirectorOutput } from "./types";

function normalize(raw: DirectorDraft): DirectorOutput {
  const beats = raw.beats.map((beat, index) => ({
    id: beat.id.trim() || `beat-${index + 1}`,
    role: beat.role,
    onScreenText: beat.onScreenText.trim(),
    spokenLine: beat.spokenLine.trim(),
    claim: beat.claim,
    visualIntent: beat.visualIntent.trim(),
    durationSec: beat.durationSec,
  }));
  if (beats.length < 4 || beats.length > 6) {
    throw new Error(`Director returned ${beats.length} beats. Need 4 to 6.`);
  }
  if (beats[0]?.role !== "hook") throw new Error("The first beat must be the hook.");
  const rationale = raw.rationale.trim();
  if (!rationale) throw new Error("The director did not explain the idea.");
  if (beats[beats.length - 1]?.role !== "cta") throw new Error("The last beat must be the cta.");
  if (beats.slice(1, -1).some((beat) => beat.role !== "beat")) {
    throw new Error("Middle beats must use the role beat.");
  }
  if (new Set(beats.map((beat) => beat.id)).size !== beats.length) {
    throw new Error("Beat ids must be unique.");
  }
  for (const beat of beats) {
    if (!beat.onScreenText || !beat.spokenLine) throw new Error(`Beat ${beat.id} is missing text.`);
  }
  return { kind: raw.kind, rationale, beats };
}

export async function direct(brand: Brand, brief: string): Promise<DirectorOutput> {
  const system = [
    "You are the director for a 9:16 social video, about 20 to 30 seconds.",
    "You write the hook, the spoken lines, and the shot list. You do not write image prompts.",
    "The first beat is the hook. The last beat is the cta. Between them, put 2 to 4 beats.",
    "The hook on-screen text is at most 8 words and must make sense with the sound off.",
    "Spoken lines, read in order, are one voiceover. Keep the full voiceover under 70 words.",
    "onScreenText is the big type. spokenLine is what the voice says during that shot.",
    "claim is true only when the line states a fact about real work.",
    "Facts must come from the brand kit or the brief. Do not invent numbers, clients, or outcomes.",
    "Hook duration about 2 seconds. Other beats about 3 to 4 seconds.",
    "The cta should land on the brand's call to action.",
    "kind is case-study, service, or opinion, based on the brief.",
    "rationale is two to four sentences in plain language: what this reel is, why that kind, and how the hook turns into the call to action.",
    "The rationale is the decision. It is not a shot list and not an image prompt.",
    `Voice: ${brand.voice}`,
    `Audience: ${brand.audience}`,
    `Call to action: ${brand.cta}`,
    `Never use these phrases: ${brand.bannedPhrases.join(", ")}.`,
  ].join("\n");

  const kit = JSON.stringify({ facts: brand.facts, proof: brand.proof.map((item) => item.caption) }, null, 2);
  let feedback = "";
  let lastError = "The director did not return a usable shot list.";
  for (let attempt = 0; attempt < 2; attempt += 1) {
    const raw = await complete(
      directorSchema,
      "DirectorOutput",
      system,
      `Brief:\n${brief}\n\nBrand facts:\n${kit}${feedback}`,
    );
    try {
      return normalize(raw);
    } catch (error) {
      lastError = error instanceof Error ? error.message : lastError;
      feedback = `\n\nYour previous output was rejected: ${lastError}\nFix it.`;
    }
  }
  throw new Error(lastError);
}
