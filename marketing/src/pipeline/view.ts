import { access } from "node:fs/promises";
import path from "node:path";
import { readStatus, readText, runDir, runPath } from "./store";
import type { ArtOutput, AssetManifest, DirectorOutput, Notes, RunShot, RunView, TraceLine } from "./types";

function mediaUrl(id: string, relative: string | null | undefined, version: string): string | null {
  if (!relative) return null;
  const base = path.basename(relative);
  if (base !== relative.replace(/^assets\//, "") || !/^[\w.-]+$/.test(base)) return null;
  return `/api/runs/${id}/media/${encodeURIComponent(base)}?v=${encodeURIComponent(version)}`;
}

function readDirector(raw: string | null): RunView["director"] {
  if (!raw) return null;
  try {
    const director = JSON.parse(raw) as Partial<DirectorOutput>;
    if (!director.beats?.length) return null;
    return {
      kind: director.kind ?? "",
      rationale: director.rationale ?? "",
      beats: director.beats,
    };
  } catch {
    return null;
  }
}

function readShots(id: string, version: string, artRaw: string | null, assetsRaw: string | null): RunShot[] | null {
  if (!artRaw) return null;
  try {
    const art = JSON.parse(artRaw) as ArtOutput;
    if (!art.shots?.length) return null;
    let manifest: AssetManifest | null = null;
    if (assetsRaw) {
      try {
        manifest = JSON.parse(assetsRaw) as AssetManifest;
      } catch {
        manifest = null;
      }
    }
    return art.shots.map((shot) => {
      const files = manifest?.shots?.[shot.id];
      return {
        ...shot,
        endPrompt: shot.endPrompt ?? "",
        reason: shot.reason ?? "",
        stillUrl: mediaUrl(id, files?.still, version),
        endStillUrl: mediaUrl(id, files?.endStill, version),
        clipUrl: mediaUrl(id, files?.clip, version),
        proofUrl: mediaUrl(id, files?.proof, version),
      };
    });
  } catch {
    return null;
  }
}

function readTrace(raw: string | null): TraceLine[] {
  if (!raw) return [];
  try {
    const trace = JSON.parse(raw) as TraceLine[];
    return Array.isArray(trace) ? trace.filter((line) => line && typeof line.text === "string" && typeof line.step === "string") : [];
  } catch {
    return [];
  }
}

function readNotes(raw: string | null): Notes | null {
  if (!raw) return null;
  try {
    return JSON.parse(raw) as Notes;
  } catch {
    return null;
  }
}

function readWarnings(raw: string | null): string[] {
  if (!raw) return [];
  try {
    const manifest = JSON.parse(raw) as AssetManifest;
    return Array.isArray(manifest.warnings) ? manifest.warnings : [];
  } catch {
    return [];
  }
}

export async function loadRunView(id: string): Promise<RunView> {
  const status = await readStatus(id);
  const [directorRaw, artRaw, assetsRaw, traceRaw, notesRaw, caption] = await Promise.all([
    readText(id, "director.json"),
    readText(id, "art.json"),
    readText(id, "assets.json"),
    readText(id, "trace.json"),
    readText(id, "notes.json"),
    readText(id, "caption.txt"),
  ]);
  let videoUrl: string | null = null;
  try {
    await access(path.join(runDir(id), "render.mp4"));
    videoUrl = `/api/runs/${id}/video?v=${encodeURIComponent(status.updatedAt)}`;
  } catch {
    videoUrl = null;
  }
  let manifest: AssetManifest | null = null;
  if (assetsRaw) {
    try {
      manifest = JSON.parse(assetsRaw) as AssetManifest;
    } catch {
      manifest = null;
    }
  }
  return {
    ...status,
    runPath: runPath(id),
    director: readDirector(directorRaw),
    shots: readShots(id, status.updatedAt, artRaw, assetsRaw),
    voiceUrl: mediaUrl(id, manifest?.voice, status.updatedAt),
    musicUrl: mediaUrl(id, manifest?.music, status.updatedAt),
    warnings: readWarnings(assetsRaw),
    trace: readTrace(traceRaw),
    caption,
    notes: readNotes(notesRaw),
    videoUrl,
  };
}
