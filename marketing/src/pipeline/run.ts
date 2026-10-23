import { writeFile } from "node:fs/promises";
import path from "node:path";
import { artDirect } from "./art-director";
import { loadBrand } from "./brand";
import { critique } from "./critic";
import { direct } from "./director";
import { enforceArt } from "./enforce";
import { drawFrames, ensureProofs, produceMedia, redrawFrame, regenerateShot, respeak } from "./generate";
import { reelProps, renderReel } from "./render";
import { requireEnv } from "./llm";
import { appendTrace, failRun, finishStage, readStatus, readText, runDir, saveJson, setStage, writeStatus } from "./store";
import { captionText } from "./text";
import { STAGES, type ArtOutput, type AssetManifest, type Brand, type DirectorOutput, type Notes, type Repair, type StageName, type TimelineStep } from "./types";

const active = new Set<string>();

async function say(id: string, stage: StageName, step: TimelineStep, text: string): Promise<void> {
  await setStage(id, stage, text);
  await appendTrace(id, step, text);
}

function repairMatters(art: ArtOutput, repair: Repair): boolean {
  const shot = art.shots.find((item) => item.id === repair.shotId);
  if (!shot) return false;
  if (repair.action === "regenerate") return shot.type === "generate" && repair.prompt.trim() !== shot.prompt;
  if (repair.action === "switch-to-type") return shot.type !== "type";
  const nextScreen = repair.onScreenText.trim();
  const nextSpoken = repair.spokenLine.trim();
  return (Boolean(nextScreen) && nextScreen !== shot.onScreenText) || (Boolean(nextSpoken) && nextSpoken !== shot.spokenLine);
}

async function applyRepair(
  id: string,
  brand: Brand,
  art: ArtOutput,
  manifest: AssetManifest,
  repair: Repair,
  onDetail: (detail: string) => Promise<void>,
): Promise<void> {
  const shot = art.shots.find((item) => item.id === repair.shotId) ?? art.shots[0];
  if (!shot) return;

  if (repair.action === "regenerate" && shot.type === "generate") {
    if (repair.prompt.trim()) shot.prompt = repair.prompt.trim();
    await onDetail(`Regenerating ${shot.id}`);
    await regenerateShot(id, brand, shot, manifest);
    return;
  }

  if (repair.action === "switch-to-type") {
    shot.type = "type";
    shot.prompt = "";
    shot.endPrompt = "";
    shot.proofId = null;
    return;
  }

  const nextScreen = repair.onScreenText.trim();
  const nextSpoken = repair.spokenLine.trim();
  const spokenChanged = Boolean(nextSpoken) && nextSpoken !== shot.spokenLine;
  if (nextScreen) shot.onScreenText = nextScreen;
  if (nextSpoken) shot.spokenLine = nextSpoken;
  if (spokenChanged) {
    await onDetail("Re-recording the voiceover");
    manifest.voice = await respeak(id, brand, art);
  }
}

function withWarnings(notes: Notes, warnings: string[]): Notes {
  if (warnings.length === 0) return notes;
  return { ...notes, issues: [...warnings, ...notes.issues.filter((issue) => !warnings.includes(issue))] };
}

async function readJson<T>(id: string, name: string): Promise<T> {
  const raw = await readText(id, name);
  if (!raw) throw new Error(`Missing ${name}.`);
  return JSON.parse(raw) as T;
}

async function finishCut(
  id: string,
  brand: Brand,
  director: DirectorOutput,
  art: ArtOutput,
  manifest: AssetManifest,
): Promise<void> {
  await say(id, "render", "render", "Rendering the video");
  await renderReel(id, reelProps(id, brand, art, manifest));
  await finishStage(id, "render");

  await say(id, "critic", "video", "Checking the cut");
  const first = await critique(brand, art);
  let notes = first.notes;
  if (!first.notes.passed && first.repair && repairMatters(art, first.repair)) {
    await applyRepair(id, brand, art, manifest, first.repair, (detail) => say(id, "generation", "generate", detail));
    art = enforceArt(
      {
        shots: art.shots.map((shot) => ({
          beatId: shot.beatId,
          type: shot.type,
          onScreenText: shot.onScreenText,
          spokenLine: shot.spokenLine,
          durationSec: shot.durationSec,
          prompt: shot.prompt,
          endPrompt: shot.endPrompt,
          reason: shot.reason,
          proofId: shot.proofId,
        })),
      },
      director,
      brand,
    );
    await ensureProofs(id, brand, art, manifest);
    await saveJson(id, "art.json", art);
    await saveJson(id, "assets.json", manifest);
    await finishStage(id, "generation");
    await say(id, "render", "render", "Rendering the repair");
    await renderReel(id, reelProps(id, brand, art, manifest));
    await finishStage(id, "render");
    const second = await critique(brand, art);
    notes = {
      passed: second.notes.passed,
      repaired: true,
      issues: [...first.notes.issues, ...second.notes.issues.filter((issue) => !first.notes.issues.includes(issue))],
      repair: first.notes.repair,
    };
  }
  notes = withWarnings(notes, manifest.warnings);
  await saveJson(id, "notes.json", notes);
  const lines = art.shots.map((shot) => shot.spokenLine);
  await writeFile(path.join(runDir(id), "caption.txt"), captionText(lines, brand.cta));
  await finishStage(id, "critic");

  const status = await readStatus(id);
  status.stage = "done";
  status.hold = null;
  status.detail = "";
  await writeStatus(status);
}

async function deliver(
  id: string,
  brand: Brand,
  director: DirectorOutput,
  art: ArtOutput,
  manifest: AssetManifest,
): Promise<void> {
  await produceMedia(id, brand, art, manifest, (detail) => say(id, "generation", "generate", detail));
  await saveJson(id, "assets.json", manifest);
  await finishStage(id, "generation");
  await finishCut(id, brand, director, art, manifest);
}

async function pauseForFrames(id: string): Promise<void> {
  await appendTrace(id, "art", "Waiting for approval before any video is made.");
  const status = await readStatus(id);
  status.stage = "awaiting";
  status.hold = "frames";
  status.detail = "Waiting for you to approve the frames";
  await writeStatus(status);
}

function stageIndex(stage: StageName): number {
  return STAGES.indexOf(stage);
}

export async function executeRun(id: string, from: StageName = "intake"): Promise<void> {
  try {
    const initial = await readStatus(id);
    const brand = await loadBrand(initial.brandId);
    requireEnv("AI_GATEWAY_API_KEY", "AI_GATEWAY_KEY");
    if (stageIndex(from) <= stageIndex("generation")) requireEnv("FAL_KEY", "FAL_AI_KEY");
    const start = stageIndex(from);

    let director: DirectorOutput;
    if (start <= stageIndex("director")) {
      if (start <= stageIndex("intake")) {
        await say(id, "intake", "idea", "Reading the brief");
        await finishStage(id, "intake");
      }
      await say(id, "director", "idea", "Writing the idea and the script");
      director = await direct(brand, initial.brief);
      await saveJson(id, "director.json", director);
      await appendTrace(id, "idea", `Decided on a ${director.kind} reel.`);
      await finishStage(id, "director");
    } else {
      director = await readJson<DirectorOutput>(id, "director.json");
    }

    if (start <= stageIndex("art")) {
      await say(id, "art", "art", "Choosing the shots");
      const art = enforceArt(await artDirect(brand, director), director, brand);
      await saveJson(id, "art.json", art);
      const generated = art.shots.filter((shot) => shot.type === "generate").length;
      const proof = art.shots.filter((shot) => shot.type === "proof").length;
      await appendTrace(id, "art", `${art.shots.length} shots. ${generated} generated, ${proof} from proof, the rest set in type.`);
      const manifest = await drawFrames(id, brand, art, (detail) => say(id, "art", "art", detail));
      await finishStage(id, "art");
      if (!initial.auto && generated > 0) {
        await pauseForFrames(id);
        return;
      }
      if (!initial.auto && generated === 0) {
        await appendTrace(id, "art", "No generated frames in this cut, so nothing to approve.");
      }
      await deliver(id, brand, director, art, manifest);
      return;
    }

    const art = await readJson<ArtOutput>(id, "art.json");
    const manifest = await readJson<AssetManifest>(id, "assets.json");
    manifest.warnings = manifest.warnings ?? [];
    if (start <= stageIndex("generation")) {
      await deliver(id, brand, director, art, manifest);
      return;
    }
    await finishCut(id, brand, director, art, manifest);
  } catch (error) {
    await failRun(id, error);
  }
}

const RETRY_STEP: Record<StageName, TimelineStep> = {
  intake: "idea",
  director: "idea",
  art: "art",
  generation: "generate",
  render: "render",
  critic: "video",
};

export async function markRetry(id: string): Promise<void> {
  if (active.has(id)) throw new Error("This run is busy.");
  const status = await readStatus(id);
  if (status.stage !== "error") throw new Error("This run did not fail.");
  const failed = STAGES.find((stage) => status.stages[stage] === "error");
  if (!failed) throw new Error("This run did not fail.");
  status.stages[failed] = "pending";
  status.stage = failed;
  status.detail = "Trying again";
  delete status.error;
  await writeStatus(status);
  await appendTrace(id, RETRY_STEP[failed], "Trying again.");
}

export async function resumeRun(id: string): Promise<void> {
  try {
    const status = await readStatus(id);
    if (status.hold !== "frames") return;
    status.hold = null;
    status.stage = "generation";
    status.detail = "Continuing into video";
    await writeStatus(status);

    const brand = await loadBrand(status.brandId);
    const director = await readJson<DirectorOutput>(id, "director.json");
    const art = await readJson<ArtOutput>(id, "art.json");
    const manifest = await readJson<AssetManifest>(id, "assets.json");
    manifest.warnings = manifest.warnings ?? [];
    await appendTrace(id, "art", "Frames approved. Making the voice, music, and clips.");
    await deliver(id, brand, director, art, manifest);
  } catch (error) {
    await failRun(id, error);
  }
}

export async function redraw(id: string, shotId: string, frame: "start" | "end", prompt: string): Promise<void> {
  if (active.has(id)) throw new Error("This run is busy.");
  const next = prompt.trim();
  if (!next) throw new Error("Write a prompt for the frame.");
  if (next.length > 2000) throw new Error("Keep the prompt under 2000 characters.");

  active.add(id);
  try {
    const status = await readStatus(id);
    if (status.hold !== "frames") throw new Error("Frames can be redrawn while the run is waiting.");
    const brand = await loadBrand(status.brandId);
    const art = await readJson<ArtOutput>(id, "art.json");
    const shot = art.shots.find((item) => item.id === shotId);
    if (!shot || shot.type !== "generate") throw new Error("That shot has no frame to redraw.");
    if (frame === "start") shot.prompt = next;
    else shot.endPrompt = next;
    await saveJson(id, "art.json", art);

    const manifest = await readJson<AssetManifest>(id, "assets.json");
    const relative = await redrawFrame(id, brand, shot, frame);
    const files = manifest.shots[shot.id] ?? {};
    manifest.shots[shot.id] = frame === "start" ? { ...files, still: relative } : { ...files, endStill: relative };
    await saveJson(id, "assets.json", manifest);
    await appendTrace(id, "art", `Redrew the ${frame} frame for ${shot.id}.`);
    status.detail = `Redrew the ${frame} frame for ${shot.id}`;
    await writeStatus(status);
  } finally {
    active.delete(id);
  }
}

export function startRun(id: string): void {
  if (active.has(id)) return;
  active.add(id);
  const job = executeRun(id).finally(() => active.delete(id));
  void job;
}

export function startContinue(id: string): boolean {
  if (active.has(id)) return false;
  active.add(id);
  const job = resumeRun(id).finally(() => active.delete(id));
  void job;
  return true;
}

export function startRetry(id: string): boolean {
  if (active.has(id)) return false;
  active.add(id);
  const job = readStatus(id)
    .then((status) => {
      if (status.stage === "done" || status.stage === "error" || status.stage === "awaiting") return;
      return executeRun(id, status.stage);
    })
    .finally(() => active.delete(id));
  void job;
  return true;
}
