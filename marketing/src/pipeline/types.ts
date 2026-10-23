import { z } from "zod";
import type { ShotRole, ShotType } from "./props";

export const STAGES = ["intake", "director", "art", "generation", "render", "critic"] as const;
export type StageName = (typeof STAGES)[number];
export type StageState = "pending" | "running" | "done" | "error";

export const brandSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  voice: z.string().min(1),
  audience: z.string().min(1),
  cta: z.string().min(1),
  colors: z.object({
    bg: z.string(),
    fg: z.string(),
    accent: z.string(),
    muted: z.string(),
  }),
  type: z.object({
    display: z.string(),
    body: z.string(),
    mono: z.string(),
  }),
  bannedPhrases: z.array(z.string()),
  bannedLooks: z.array(z.string()),
  speechVoice: z.string().min(1),
  musicMood: z.string().min(1),
  logo: z.string().nullable(),
  proof: z.array(
    z.object({
      id: z.string().min(1),
      file: z.string().min(1),
      caption: z.string(),
    }),
  ),
  facts: z.array(
    z.object({
      id: z.string(),
      title: z.string(),
      text: z.string(),
    }),
  ),
});

export type Brand = z.infer<typeof brandSchema>;

export const TIMELINE_STEPS = ["idea", "art", "generate", "render", "video"] as const;
export type TimelineStep = (typeof TIMELINE_STEPS)[number];

export type TraceLine = {
  step: TimelineStep;
  text: string;
  at: string;
};

export const directorSchema = z.object({
  kind: z.enum(["case-study", "service", "opinion"]),
  rationale: z.string().min(1),
  beats: z
    .array(
      z.object({
        id: z.string(),
        role: z.enum(["hook", "beat", "cta"]),
        onScreenText: z.string(),
        spokenLine: z.string(),
        claim: z.boolean(),
        visualIntent: z.string(),
        durationSec: z.number(),
      }),
    )
    .min(4)
    .max(6),
});

export type DirectorDraft = z.infer<typeof directorSchema>;

export type Beat = {
  id: string;
  role: ShotRole;
  onScreenText: string;
  spokenLine: string;
  claim: boolean;
  visualIntent: string;
  durationSec: number;
};

export type DirectorOutput = {
  kind: DirectorDraft["kind"];
  rationale: string;
  beats: Beat[];
};

export const artSchema = z.object({
  shots: z.array(
    z.object({
      beatId: z.string(),
      type: z.enum(["type", "proof", "generate"]),
      onScreenText: z.string(),
      spokenLine: z.string(),
      durationSec: z.number(),
      prompt: z.string(),
      endPrompt: z.string(),
      reason: z.string(),
      proofId: z.string().nullable(),
    }),
  ),
});

export type ArtDraft = z.infer<typeof artSchema>;

export type ArtShot = {
  id: string;
  beatId: string;
  role: ShotRole;
  type: ShotType;
  onScreenText: string;
  spokenLine: string;
  durationSec: number;
  prompt: string;
  endPrompt: string;
  reason: string;
  proofId: string | null;
  claim: boolean;
};

export type ArtOutput = {
  template: "proof-reel";
  shots: ArtShot[];
};

export type AssetManifest = {
  voice: string | null;
  music: string | null;
  logo: string | null;
  warnings: string[];
  shots: Record<string, { still?: string; endStill?: string; clip?: string; proof?: string }>;
};

export const criticSchema = z.object({
  passed: z.boolean(),
  issues: z.array(z.string()),
  repair: z
    .object({
      shotId: z.string(),
      action: z.enum(["regenerate", "switch-to-type", "rewrite"]),
      prompt: z.string(),
      onScreenText: z.string(),
      spokenLine: z.string(),
    })
    .nullable(),
});

export type Repair = NonNullable<z.infer<typeof criticSchema>["repair"]>;

export type Notes = {
  passed: boolean;
  repaired: boolean;
  issues: string[];
  repair: { shotId: string; action: Repair["action"]; detail: string } | null;
};

export type RunStatus = {
  id: string;
  brandId: string;
  brief: string;
  auto: boolean;
  hold: "frames" | null;
  stage: StageName | "done" | "error" | "awaiting";
  detail: string;
  error?: string;
  stages: Record<StageName, StageState>;
  createdAt: string;
  updatedAt: string;
};

export type RunShot = ArtShot & {
  stillUrl: string | null;
  endStillUrl: string | null;
  clipUrl: string | null;
  proofUrl: string | null;
};

export type RunView = RunStatus & {
  runPath: string;
  director: { kind: string; rationale: string; beats: Beat[] } | null;
  shots: RunShot[] | null;
  voiceUrl: string | null;
  musicUrl: string | null;
  warnings: string[];
  trace: TraceLine[];
  caption: string | null;
  notes: Notes | null;
  videoUrl: string | null;
};
