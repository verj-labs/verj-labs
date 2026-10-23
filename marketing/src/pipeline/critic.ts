import { complete } from "./llm";
import { findBanned, voiceScript, words } from "./text";
import { criticSchema, type ArtOutput, type Brand, type Notes, type Repair } from "./types";

export function hardIssues(brand: Brand, art: ArtOutput): string[] {
  const issues: string[] = [];
  const script = art.shots.map((shot) => `${shot.onScreenText}\n${shot.spokenLine}`).join("\n");
  for (const phrase of findBanned(script, brand.bannedPhrases)) {
    issues.push(`Banned phrase: ${phrase}`);
  }
  const hook = art.shots.find((shot) => shot.role === "hook");
  if (!hook) issues.push("Missing hook.");
  else if (words(hook.onScreenText) > 12) issues.push("Hook is longer than 12 words.");

  const usedProof = new Set(art.shots.filter((shot) => shot.type === "proof").map((shot) => shot.proofId));
  const unusedProof = brand.proof.filter((item) => !usedProof.has(item.id));
  for (const shot of art.shots) {
    if (shot.type !== "type" && words(shot.onScreenText) > 10) {
      issues.push(`Shot ${shot.id} overlay is longer than 10 words.`);
    }
    if (words(shot.spokenLine) > 22) issues.push(`Shot ${shot.id} spoken line is longer than 22 words.`);
    if (shot.claim && shot.type === "generate") {
      issues.push(`Claim shot ${shot.id} was generated instead of set in type or proof.`);
    }
    if (shot.claim && shot.type !== "proof" && unusedProof.length > 0) {
      issues.push(`Claim shot ${shot.id} did not use a proof asset.`);
    }
  }
  const generated = art.shots.filter((shot) => shot.type === "generate").length;
  if (generated > 3) issues.push(`Too many generated clips: ${generated}.`);
  const total = art.shots.reduce((sum, shot) => sum + shot.durationSec, 0);
  if (total < 18 || total > 32) issues.push(`Duration ${total.toFixed(1)}s is outside 18–32 seconds.`);
  if (words(voiceScript(art.shots.map((shot) => shot.spokenLine))) > 80) {
    issues.push("Spoken script is over 80 words and may run past the video.");
  }
  return issues;
}

function noteFor(repair: Repair): Notes["repair"] {
  const detail =
    repair.action === "regenerate"
      ? repair.prompt
      : repair.action === "rewrite"
        ? repair.onScreenText
        : "Switched off generated media.";
  return { shotId: repair.shotId, action: repair.action, detail };
}

function chooseRepair(art: ArtOutput, issues: string[], suggested: Repair | null): Repair | null {
  if (issues.length === 0) return null;
  const claim = art.shots.find((shot) => shot.claim && shot.type === "generate");
  if (claim) {
    return {
      shotId: claim.id,
      action: "switch-to-type",
      prompt: "",
      onScreenText: claim.onScreenText,
      spokenLine: claim.spokenLine,
    };
  }
  if (suggested && art.shots.some((shot) => shot.id === suggested.shotId)) return suggested;
  const hook = art.shots.find((shot) => shot.role === "hook") ?? art.shots[0];
  if (!hook) return null;
  return {
    shotId: hook.id,
    action: "rewrite",
    prompt: "",
    onScreenText: hook.onScreenText,
    spokenLine: hook.spokenLine,
  };
}

export async function critique(brand: Brand, art: ArtOutput): Promise<{ notes: Notes; repair: Repair | null }> {
  const hard = hardIssues(brand, art);
  let suggested: Repair | null = null;
  let voiceIssues: string[] = [];
  try {
    const review = await complete(
      criticSchema,
      "CriticNotes",
      [
        "You review a 9:16 social video plan for a specific brand.",
        "Judge the voice, the hook, and whether a claim is specific.",
        "Do not invent facts. Do not ask for text inside generated images.",
        "If it fails, propose exactly one repair:",
        "regenerate — a generate shot with a weak prompt. Include the new prompt.",
        "switch-to-type — a generated shot that should be type instead.",
        "rewrite — fix one shot. Include the full replacement onScreenText and spokenLine.",
        "If it passes, set passed true and repair null.",
        `Never use: ${brand.bannedPhrases.join(", ")}.`,
        `Voice: ${brand.voice}`,
      ].join("\n"),
      `Hard checks already found:\n${hard.length ? hard.join("\n") : "None."}\n\nShots:\n${JSON.stringify(art.shots, null, 2)}`,
    );
    voiceIssues = review.issues;
    suggested = review.repair;
    if (review.passed && hard.length === 0) {
      return { notes: { passed: true, repaired: false, issues: [], repair: null }, repair: null };
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "Critic request failed.";
    if (hard.length === 0) {
      return {
        notes: { passed: true, repaired: false, issues: [`Critic model was skipped: ${message}`], repair: null },
        repair: null,
      };
    }
    voiceIssues = [message];
  }

  const issues = [...hard, ...voiceIssues.filter((issue) => !hard.includes(issue))];
  const repair = chooseRepair(art, hard.length ? hard : issues, suggested);
  return {
    notes: { passed: false, repaired: false, issues, repair: repair ? noteFor(repair) : null },
    repair,
  };
}
