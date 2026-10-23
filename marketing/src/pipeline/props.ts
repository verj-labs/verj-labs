export type ShotRole = "hook" | "beat" | "cta";
export type ShotType = "type" | "proof" | "generate";

export type ReelShot = {
  id: string;
  role: ShotRole;
  type: ShotType;
  onScreenText: string;
  spokenLine: string;
  durationSec: number;
  src: string | null;
  media: "image" | "video" | null;
};

export type ReelProps = {
  brandName: string;
  colors: { bg: string; fg: string; accent: string; muted: string };
  displayFont: string;
  bodyFont: string;
  monoFont: string;
  logoSrc: string | null;
  voiceSrc: string | null;
  musicSrc: string | null;
  shots: ReelShot[];
};
