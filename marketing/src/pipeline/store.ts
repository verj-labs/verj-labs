import { mkdir, readdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { STAGES, type RunStatus, type StageName, type TimelineStep, type TraceLine } from "./types";

const RUN_ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function runsDir(): string {
  return path.join(process.cwd(), "runs");
}

export function isRunId(id: string): boolean {
  return RUN_ID.test(id);
}

export function runDir(id: string): string {
  if (!isRunId(id)) throw new Error("Unknown run.");
  return path.join(runsDir(), id);
}

export function runPath(id: string): string {
  return `marketing/runs/${id}`;
}

async function writeJson(file: string, data: unknown): Promise<void> {
  await writeFile(file, `${JSON.stringify(data, null, 2)}\n`);
}

export async function createRun(brandId: string, brief: string, auto: boolean): Promise<RunStatus> {
  const id = crypto.randomUUID();
  const dir = path.join(runsDir(), id);
  await mkdir(path.join(dir, "assets"), { recursive: true });
  const now = new Date().toISOString();
  const stages = Object.fromEntries(STAGES.map((stage) => [stage, "pending"])) as RunStatus["stages"];
  const status: RunStatus = {
    id,
    brandId,
    brief,
    auto,
    hold: null,
    stage: "intake",
    detail: "Queued",
    stages,
    createdAt: now,
    updatedAt: now,
  };
  await writeJson(path.join(dir, "brief.json"), { id, brandId, text: brief, auto, createdAt: now });
  await writeStatus(status);
  return status;
}

export async function listRuns(): Promise<RunStatus[]> {
  let names: string[] = [];
  try {
    names = await readdir(runsDir());
  } catch {
    return [];
  }
  const runs: RunStatus[] = [];
  for (const name of names) {
    if (!isRunId(name)) continue;
    try {
      runs.push(await readStatus(name));
    } catch {
      continue;
    }
  }
  runs.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  return runs;
}

export async function readStatus(id: string): Promise<RunStatus> {
  try {
    const status = JSON.parse(await readFile(path.join(runDir(id), "status.json"), "utf8")) as RunStatus;
    return { ...status, auto: status.auto ?? true, hold: status.hold ?? null };
  } catch {
    throw new Error("Unknown run.");
  }
}

export async function writeStatus(status: RunStatus): Promise<void> {
  status.updatedAt = new Date().toISOString();
  await writeJson(path.join(runDir(status.id), "status.json"), status);
}

export async function setStage(id: string, stage: StageName, detail: string): Promise<void> {
  const status = await readStatus(id);
  status.stage = stage;
  status.detail = detail;
  status.stages[stage] = "running";
  await writeStatus(status);
}

export async function finishStage(id: string, stage: StageName): Promise<void> {
  const status = await readStatus(id);
  status.stages[stage] = "done";
  status.detail = "";
  await writeStatus(status);
}

export async function failRun(id: string, error: unknown): Promise<void> {
  const status = await readStatus(id);
  const message = error instanceof Error ? error.message : "The run failed.";
  status.stage = "error";
  status.error = message;
  status.detail = "";
  const current = STAGES.find((stage) => status.stages[stage] === "running") ?? STAGES.find((stage) => status.stages[stage] === "pending");
  if (current) status.stages[current] = "error";
  await writeStatus(status);
}

export async function saveJson(id: string, name: string, data: unknown): Promise<void> {
  if (!/^[a-z0-9.-]+$/i.test(name)) throw new Error("Bad file name.");
  await writeJson(path.join(runDir(id), name), data);
}

export async function appendTrace(id: string, step: TimelineStep, text: string): Promise<void> {
  const raw = await readText(id, "trace.json");
  const trace: TraceLine[] = raw ? (JSON.parse(raw) as TraceLine[]) : [];
  trace.push({ step, text, at: new Date().toISOString() });
  await saveJson(id, "trace.json", trace);
}

export async function readText(id: string, name: string): Promise<string | null> {
  try {
    return await readFile(path.join(runDir(id), name), "utf8");
  } catch {
    return null;
  }
}
