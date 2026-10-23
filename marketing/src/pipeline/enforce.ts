import { clamp } from "./text";
import type { ArtDraft, ArtOutput, ArtShot, Brand, DirectorOutput } from "./types";

function fitDurations(shots: ArtShot[]): void {
  for (const shot of shots) {
    shot.durationSec = shot.type === "generate" ? 5 : clamp(shot.durationSec || 3, 2, 6);
  }
  const flex = shots.filter((shot) => shot.type !== "generate");
  if (flex.length === 0) return;
  const fixed = shots.filter((shot) => shot.type === "generate").reduce((sum, shot) => sum + shot.durationSec, 0);
  const currentFlex = flex.reduce((sum, shot) => sum + shot.durationSec, 0);
  const desired = clamp(fixed + currentFlex, 20, 30);
  const budget = clamp(desired - fixed, flex.length * 2, flex.length * 6);
  const current = currentFlex || 1;
  for (const shot of flex) {
    shot.durationSec = clamp(Math.round((shot.durationSec / current) * budget * 10) / 10, 2, 6);
  }
  const drift = Math.round((budget - flex.reduce((sum, shot) => sum + shot.durationSec, 0)) * 10) / 10;
  const last = flex[flex.length - 1];
  if (last) last.durationSec = clamp(Math.round((last.durationSec + drift) * 10) / 10, 2, 6);
}

export function enforceArt(raw: ArtDraft, director: DirectorOutput, brand: Brand): ArtOutput {
  const proposed = new Map(raw.shots.map((shot) => [shot.beatId, shot]));
  const used = new Set<string>();
  let generateBudget = 3;

  const takeProof = (preferred: string | null, allowAny: boolean): string | null => {
    const named = brand.proof.find((item) => item.id === preferred && !used.has(item.id));
    const fallback = allowAny ? brand.proof.find((item) => !used.has(item.id)) : undefined;
    const match = named ?? fallback;
    if (!match) return null;
    used.add(match.id);
    return match.id;
  };

  const shots: ArtShot[] = director.beats.map((beat) => {
    const idea = proposed.get(beat.id);
    let type = idea?.type ?? "type";
    let prompt = (idea?.prompt ?? "").trim();
    let endPrompt = (idea?.endPrompt ?? "").trim();
    let reason = (idea?.reason ?? "").trim();
    let proofId: string | null = null;

    const cannotGenerate = beat.role === "hook" || beat.role === "cta" || beat.claim || generateBudget <= 0;
    if (type === "generate" && cannotGenerate) type = "type";

    if (beat.claim) {
      const claimed = takeProof(idea?.proofId ?? null, true);
      if (claimed) {
        type = "proof";
        proofId = claimed;
      } else {
        type = "type";
      }
    } else if (type === "proof") {
      proofId = takeProof(idea?.proofId ?? null, false);
      if (!proofId) type = "type";
    }

    if (type !== (idea?.type ?? "type")) reason = "";

    if (type === "generate") {
      generateBudget -= 1;
      if (!prompt) {
        prompt = `Vertical 9:16 photograph. ${beat.visualIntent}. No text, no logos, no readable screens.`;
      }
      if (!endPrompt) {
        endPrompt = `${prompt} The same scene a moment later, the motion finished, same light and place.`;
      }
      if (!reason) reason = "Generated b-roll, held between a start frame and an end frame.";
    } else {
      prompt = "";
      endPrompt = "";
      if (!reason) reason = type === "proof" ? "Uses a real proof file from the brand kit." : "Set in type. No generated picture.";
    }

    return {
      id: beat.id,
      beatId: beat.id,
      role: beat.role,
      type,
      onScreenText: (idea?.onScreenText || beat.onScreenText).trim(),
      spokenLine: (idea?.spokenLine || beat.spokenLine).trim(),
      durationSec: idea?.durationSec || beat.durationSec,
      prompt,
      endPrompt,
      reason,
      proofId,
      claim: beat.claim,
    };
  });

  fitDurations(shots);
  return { template: "proof-reel", shots };
}
