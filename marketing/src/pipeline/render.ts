import { copyFile, mkdir } from "node:fs/promises";
import path from "node:path";
import { bundle } from "@remotion/bundler";
import { renderMedia, selectComposition } from "@remotion/renderer";
import type { ReelProps, ReelShot } from "./props";
import { runDir } from "./store";
import type { ArtOutput, AssetManifest, Brand } from "./types";

const REMOTION_PORT = 3211;
let bundlePromise: Promise<string> | null = null;

function serveUrl(): Promise<string> {
  if (!bundlePromise) {
    bundlePromise = bundle({
      entryPoint: path.join(process.cwd(), "src/remotion/index.ts"),
    }).catch((error: unknown) => {
      bundlePromise = null;
      throw error;
    });
  }
  return bundlePromise;
}

function shotMedia(
  id: string,
  artShot: ArtOutput["shots"][number],
  manifest: AssetManifest,
): { src: string | null; media: ReelShot["media"] } {
  const files = manifest.shots[artShot.id];
  if (artShot.type === "proof" && files?.proof) return { src: path.join(runDir(id), files.proof), media: "image" };
  if (artShot.type === "generate" && files?.clip) return { src: path.join(runDir(id), files.clip), media: "video" };
  if (artShot.type === "generate" && files?.still) return { src: path.join(runDir(id), files.still), media: "image" };
  return { src: null, media: null };
}

export function reelProps(id: string, brand: Brand, art: ArtOutput, manifest: AssetManifest): ReelProps {
  const shots: ReelShot[] = art.shots.map((shot) => ({
    id: shot.id,
    role: shot.role,
    type: shot.type,
    onScreenText: shot.onScreenText,
    spokenLine: shot.spokenLine,
    durationSec: shot.durationSec,
    ...shotMedia(id, shot, manifest),
  }));
  return {
    brandName: brand.name,
    colors: brand.colors,
    displayFont: brand.type.display,
    bodyFont: brand.type.body,
    monoFont: brand.type.mono,
    logoSrc: manifest.logo ? path.join(runDir(id), manifest.logo) : null,
    voiceSrc: manifest.voice ? path.join(runDir(id), manifest.voice) : null,
    musicSrc: manifest.music ? path.join(runDir(id), manifest.music) : null,
    shots,
  };
}

async function publish(bundleDir: string, id: string, absolute: string | null): Promise<string | null> {
  if (!absolute) return null;
  const base = path.basename(absolute);
  if (!/^[\w.-]+$/.test(base)) throw new Error(`Cannot render ${base}.`);
  const dir = path.join(bundleDir, "runs", id);
  await mkdir(dir, { recursive: true });
  await copyFile(absolute, path.join(dir, base));
  return `/runs/${id}/${base}`;
}

async function publishedProps(bundleDir: string, id: string, props: ReelProps): Promise<ReelProps> {
  const shots = await Promise.all(
    props.shots.map(async (shot) => ({
      ...shot,
      src: await publish(bundleDir, id, shot.src),
    })),
  );
  return {
    ...props,
    logoSrc: await publish(bundleDir, id, props.logoSrc),
    voiceSrc: await publish(bundleDir, id, props.voiceSrc),
    musicSrc: await publish(bundleDir, id, props.musicSrc),
    shots,
  };
}

export async function renderReel(id: string, props: ReelProps): Promise<void> {
  const bundled = await serveUrl();
  const inputProps = await publishedProps(bundled, id, props);
  const composition = await selectComposition({
    serveUrl: bundled,
    id: "ProofReel",
    inputProps,
    port: REMOTION_PORT,
  });
  await renderMedia({
    composition,
    serveUrl: bundled,
    codec: "h264",
    outputLocation: path.join(runDir(id), "render.mp4"),
    inputProps,
    port: REMOTION_PORT,
  });
}
