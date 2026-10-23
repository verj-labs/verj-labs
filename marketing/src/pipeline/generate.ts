import { fal } from "@fal-ai/client";
import { access, copyFile, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { brandAsset } from "./brand";
import { requireEnv } from "./llm";
import { runDir, saveJson } from "./store";
import { voiceScript } from "./text";
import type { ArtOutput, ArtShot, AssetManifest, Brand } from "./types";

const STILL = "fal-ai/flux-2-pro";
const CLIP = "fal-ai/kling-video/v3/pro/image-to-video";
const VOICE = "elevenlabs/tts/eleven-v4";
const MUSIC = "fal-ai/stable-audio";

function configureFal(): void {
  fal.config({ credentials: requireEnv("FAL_KEY", "FAL_AI_KEY") });
}

function mediaUrl(data: unknown): string {
  if (!data || typeof data !== "object") throw new Error("fal returned no media.");
  const record = data as Record<string, unknown>;
  const urlOf = (value: unknown): string | null => {
    if (!value || typeof value !== "object") return null;
    const url = (value as { url?: unknown }).url;
    return typeof url === "string" && url.length > 0 ? url : null;
  };
  const direct = urlOf(record.video) ?? urlOf(record.audio) ?? urlOf(record.audio_file);
  if (direct) return direct;
  if (Array.isArray(record.images)) {
    const url = urlOf(record.images[0]);
    if (url) return url;
  }
  throw new Error("fal response had no media url.");
}

async function falRun(endpoint: string, input: Record<string, unknown>, timeout: number): Promise<string> {
  try {
    const result = await fal.subscribe(endpoint, { input, timeout });
    return mediaUrl(result.data);
  } catch (error) {
    const message = error instanceof Error ? error.message : "request failed";
    throw new Error(`${endpoint} failed: ${message}`);
  }
}

async function download(url: string, dest: string): Promise<void> {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Could not download media (${response.status}).`);
  await writeFile(dest, Buffer.from(await response.arrayBuffer()));
}

async function uploadStill(filePath: string): Promise<string> {
  const bytes = await readFile(filePath);
  const file = new File([new Uint8Array(bytes)], path.basename(filePath), { type: "image/jpeg" });
  return fal.storage.upload(file);
}

function rel(name: string): string {
  return `assets/${name}`;
}

function abs(id: string, relative: string): string {
  return path.join(runDir(id), relative);
}

async function writeVoice(id: string, brand: Brand, shots: ArtShot[]): Promise<string> {
  const relative = rel("voice.mp3");
  const url = await falRun(
    VOICE,
    {
      text: voiceScript(shots.map((shot) => shot.spokenLine)),
      voice: brand.speechVoice,
      stability: 0.6,
    },
    600_000,
  );
  await download(url, abs(id, relative));
  return relative;
}

async function writeMusic(id: string, brand: Brand): Promise<string> {
  const relative = rel("music.mp3");
  const url = await falRun(
    MUSIC,
    {
      prompt: `${brand.musicMood} Instrumental only. No vocals. No lyrics. A bed under a voiceover.`,
      seconds_total: 30,
      steps: 50,
    },
    600_000,
  );
  await download(url, abs(id, relative));
  return relative;
}

function fileId(id: string): string {
  const clean = id.replace(/[^a-zA-Z0-9_-]/g, "");
  if (!clean) throw new Error("Shot id is not a safe file name.");
  return clean;
}

function stillName(shotId: string, frame: "start" | "end"): string {
  const base = fileId(shotId);
  return frame === "start" ? `${base}.jpg` : `${base}-end.jpg`;
}

async function writeStill(id: string, brand: Brand, shot: ArtShot, frame: "start" | "end"): Promise<string> {
  const relative = rel(stillName(shot.id, frame));
  const prompt = frame === "start" ? shot.prompt : shot.endPrompt;
  const avoid = brand.bannedLooks.join(", ");
  const url = await falRun(
    STILL,
    {
      prompt: `${prompt} Vertical photograph, no text, no watermark, no logo. Avoid: ${avoid}.`,
      image_size: "portrait_16_9",
      output_format: "jpeg",
    },
    600_000,
  );
  await download(url, abs(id, relative));
  return relative;
}

async function writeClip(
  id: string,
  brand: Brand,
  shot: ArtShot,
  stillRelative: string,
  endRelative: string | null,
): Promise<string> {
  const relative = rel(`${fileId(shot.id)}.mp4`);
  const imageUrl = await uploadStill(abs(id, stillRelative));
  const input: Record<string, unknown> = {
    start_image_url: imageUrl,
    prompt: shot.prompt,
    duration: "5",
    generate_audio: false,
    negative_prompt: brand.bannedLooks.join(", "),
  };
  if (endRelative) input.end_image_url = await uploadStill(abs(id, endRelative));
  const url = await falRun(CLIP, input, 600_000);
  await download(url, abs(id, relative));
  return relative;
}

async function copyProof(id: string, brand: Brand, shot: ArtShot): Promise<string> {
  const proof = brand.proof.find((item) => item.id === shot.proofId);
  if (!proof) throw new Error(`Missing proof asset for ${shot.id}.`);
  const ext = path.extname(proof.file) || ".jpg";
  const relative = rel(`${shot.id}${ext}`);
  await copyFile(brandAsset(brand, proof.file), abs(id, relative));
  return relative;
}

async function copyLogo(id: string, brand: Brand): Promise<string | null> {
  if (!brand.logo) return null;
  const ext = path.extname(brand.logo) || ".svg";
  const relative = rel(`logo${ext}`);
  await copyFile(brandAsset(brand, brand.logo), abs(id, relative));
  return relative;
}

async function persist(id: string, manifest: AssetManifest): Promise<void> {
  await saveJson(id, "assets.json", manifest);
}

export async function drawFrames(
  id: string,
  brand: Brand,
  art: ArtOutput,
  onDetail: (detail: string) => Promise<void>,
): Promise<AssetManifest> {
  configureFal();
  const manifest: AssetManifest = { voice: null, music: null, logo: null, warnings: [], shots: {} };
  manifest.logo = await copyLogo(id, brand);
  for (const shot of art.shots.filter((item) => item.type === "proof")) {
    const proof = await copyProof(id, brand, shot);
    manifest.shots[shot.id] = { proof };
  }
  await persist(id, manifest);

  for (const shot of art.shots.filter((item) => item.type === "generate")) {
    await onDetail(`Drawing the start frame for ${shot.id}`);
    const still = await writeStill(id, brand, shot, "start");
    manifest.shots[shot.id] = { ...manifest.shots[shot.id], still };
    await persist(id, manifest);
    await onDetail(`Drawing the end frame for ${shot.id}`);
    const endStill = await writeStill(id, brand, shot, "end");
    manifest.shots[shot.id] = { ...manifest.shots[shot.id], still, endStill };
    await persist(id, manifest);
  }

  return manifest;
}

async function fileExists(file: string): Promise<boolean> {
  try {
    await access(file);
    return true;
  } catch {
    return false;
  }
}

export async function produceMedia(
  id: string,
  brand: Brand,
  art: ArtOutput,
  manifest: AssetManifest,
  onDetail: (detail: string) => Promise<void>,
): Promise<void> {
  configureFal();
  const voiceReady = Boolean(manifest.voice) && (await fileExists(abs(id, manifest.voice as string)));
  const musicReady = Boolean(manifest.music) && (await fileExists(abs(id, manifest.music as string)));
  if (!voiceReady || !musicReady) {
    await onDetail(voiceReady ? "Writing the music bed" : musicReady ? "Recording the voiceover" : "Recording the voiceover and the music bed");
  }
  if (!voiceReady) manifest.voice = await writeVoice(id, brand, art.shots);
  if (!musicReady) {
    try {
      manifest.music = await writeMusic(id, brand);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Music bed failed.";
      if (!manifest.warnings.includes(message)) manifest.warnings.push(message);
      manifest.music = null;
      await onDetail(message);
    }
  }
  await persist(id, manifest);

  const generated = art.shots.filter((shot) => shot.type === "generate");
  for (let index = 0; index < generated.length; index += 1) {
    const shot = generated[index];
    const files = manifest.shots[shot.id] ?? {};
    if (files.clip && (await fileExists(abs(id, files.clip)))) continue;
    if (!files.still) throw new Error(`Missing the start frame for ${shot.id}.`);
    await onDetail(`Animating clip ${index + 1} of ${generated.length}`);
    const clip = await writeClip(id, brand, shot, files.still, files.endStill ?? null);
    manifest.shots[shot.id] = { ...files, clip };
    await persist(id, manifest);
  }
}

export async function redrawFrame(id: string, brand: Brand, shot: ArtShot, frame: "start" | "end"): Promise<string> {
  configureFal();
  return writeStill(id, brand, shot, frame);
}

export async function ensureProofs(id: string, brand: Brand, art: ArtOutput, manifest: AssetManifest): Promise<void> {
  for (const shot of art.shots) {
    if (shot.type !== "proof" || manifest.shots[shot.id]?.proof) continue;
    const proof = await copyProof(id, brand, shot);
    manifest.shots[shot.id] = { ...manifest.shots[shot.id], proof };
  }
}

export async function respeak(id: string, brand: Brand, art: ArtOutput): Promise<string> {
  configureFal();
  return writeVoice(id, brand, art.shots);
}

export async function regenerateShot(id: string, brand: Brand, shot: ArtShot, manifest: AssetManifest): Promise<void> {
  configureFal();
  const still = await writeStill(id, brand, shot, "start");
  const endStill = shot.endPrompt ? await writeStill(id, brand, shot, "end") : manifest.shots[shot.id]?.endStill;
  const clip = await writeClip(id, brand, shot, still, endStill ?? null);
  manifest.shots[shot.id] = { ...manifest.shots[shot.id], still, endStill, clip };
}
