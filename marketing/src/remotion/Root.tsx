import React from "react";
import { Composition } from "remotion";
import type { ReelProps } from "../pipeline/props";
import { ProofReel } from "./ProofReel";

const sample: ReelProps = {
  brandName: "Verj Labs",
  colors: { bg: "#0a0a0a", fg: "#f4f4f0", accent: "#d4f53c", muted: "#333333" },
  displayFont: "Archivo Black",
  bodyFont: "Archivo",
  monoFont: "JetBrains Mono",
  logoSrc: null,
  voiceSrc: null,
  musicSrc: null,
  shots: [
    {
      id: "hook",
      role: "hook",
      type: "type",
      onScreenText: "Jewelry visuals in minutes",
      spokenLine: "Jewelers wait days for a product video.",
      durationSec: 2.5,
      src: null,
      media: null,
    },
    {
      id: "beat-1",
      role: "beat",
      type: "type",
      onScreenText: "One studio for the piece",
      spokenLine: "Zavara Studio makes the renders, photos, and video in minutes.",
      durationSec: 4,
      src: null,
      media: null,
    },
    {
      id: "beat-2",
      role: "beat",
      type: "type",
      onScreenText: "Orders in the same place",
      spokenLine: "Clients and orders sit next to the catalog.",
      durationSec: 4,
      src: null,
      media: null,
    },
    {
      id: "cta",
      role: "cta",
      type: "type",
      onScreenText: "Book a call",
      spokenLine: "Book a call.",
      durationSec: 3,
      src: null,
      media: null,
    },
  ],
};

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="ProofReel"
      component={ProofReel}
      width={1080}
      height={1920}
      fps={30}
      durationInFrames={450}
      defaultProps={sample}
      calculateMetadata={({ props }) => {
        const durationInFrames = props.shots.reduce(
          (sum, shot) => sum + Math.max(1, Math.round(shot.durationSec * 30)),
          0,
        );
        return { durationInFrames: Math.max(durationInFrames, 1) };
      }}
    />
  );
};
