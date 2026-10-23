import { loadFont as loadBody } from "@remotion/google-fonts/Archivo";
import { loadFont as loadDisplay } from "@remotion/google-fonts/ArchivoBlack";
import { loadFont as loadMono } from "@remotion/google-fonts/JetBrainsMono";
import React from "react";
import { AbsoluteFill, Audio, Img, OffthreadVideo, Sequence, interpolate, useCurrentFrame } from "remotion";
import type { ReelProps, ReelShot } from "../pipeline/props";

const displayFamily = loadDisplay().fontFamily;
const bodyFamily = loadBody("normal", { weights: ["500", "700"], subsets: ["latin"] }).fontFamily;
const monoFamily = loadMono("normal", { weights: ["500"], subsets: ["latin"] }).fontFamily;

function family(name: string, fallback: string): string {
  if (name === "Archivo Black") return displayFamily;
  if (name === "Archivo") return bodyFamily;
  if (name === "JetBrains Mono") return monoFamily;
  return fallback;
}

function useShotEnter(): React.CSSProperties {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 8], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const y = interpolate(frame, [0, 8], [16, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return { opacity, transform: `translateY(${y}px)` };
}

function Caption({ shot, font, color }: { shot: ReelShot; font: string; color: string }) {
  const same = shot.spokenLine.trim().toLowerCase() === shot.onScreenText.trim().toLowerCase();
  if (!shot.spokenLine.trim() || (same && shot.type === "type")) return null;
  return (
    <div
      style={{
        position: "absolute",
        left: 72,
        right: 120,
        bottom: 300,
        fontFamily: font,
        fontWeight: 500,
        fontSize: 34,
        lineHeight: 1.25,
        color,
      }}
    >
      {shot.spokenLine}
    </div>
  );
}

function TypeCard({
  shot,
  props,
  display,
  body,
  mono,
}: {
  shot: ReelShot;
  props: ReelProps;
  display: string;
  body: string;
  mono: string;
}) {
  const motion = useShotEnter();
  const cta = shot.role === "cta";
  return (
    <AbsoluteFill style={{ background: props.colors.bg, color: props.colors.fg, padding: "200px 80px 320px" }}>
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 10, background: props.colors.accent }} />
      <div style={motion}>
        <div style={{ fontFamily: mono, letterSpacing: "0.08em", textTransform: "uppercase", fontSize: 22, color: props.colors.accent }}>
          {cta ? props.brandName : shot.role === "hook" ? "Watch" : props.brandName}
        </div>
        {cta && props.logoSrc ? (
          <Img src={props.logoSrc} style={{ width: 640, height: "auto", marginTop: 48, objectFit: "contain" }} />
        ) : null}
        <div
          style={{
            marginTop: 28,
            fontFamily: display,
            fontSize: cta ? 92 : shot.role === "hook" ? 108 : 84,
            lineHeight: 0.92,
            letterSpacing: "-0.035em",
            textTransform: "uppercase",
            maxWidth: 900,
          }}
        >
          {shot.onScreenText}
        </div>
      </div>
      <Caption shot={shot} font={body} color={props.colors.fg} />
    </AbsoluteFill>
  );
}

function MediaCard({
  shot,
  props,
  display,
  body,
  mono,
}: {
  shot: ReelShot;
  props: ReelProps;
  display: string;
  body: string;
  mono: string;
}) {
  const motion = useShotEnter();
  return (
    <AbsoluteFill style={{ background: props.colors.bg }}>
      {shot.src && shot.media === "video" ? (
        <OffthreadVideo src={shot.src} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      ) : null}
      {shot.src && shot.media === "image" ? (
        <Img src={shot.src} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      ) : null}
      <AbsoluteFill
        style={{
          background: "linear-gradient(to top, rgba(0,0,0,0.78) 0%, rgba(0,0,0,0.2) 42%, rgba(0,0,0,0.28) 100%)",
        }}
      />
      <div style={{ position: "absolute", left: 72, right: 120, bottom: 390, ...motion }}>
        <div style={{ fontFamily: mono, letterSpacing: "0.08em", textTransform: "uppercase", fontSize: 22, color: props.colors.accent }}>
          {props.brandName}
        </div>
        <div
          style={{
            marginTop: 16,
            fontFamily: display,
            fontSize: 72,
            lineHeight: 0.94,
            letterSpacing: "-0.035em",
            textTransform: "uppercase",
            color: props.colors.fg,
          }}
        >
          {shot.onScreenText}
        </div>
      </div>
      <Caption shot={shot} font={body} color={props.colors.fg} />
    </AbsoluteFill>
  );
}

export const ProofReel: React.FC<ReelProps> = (props) => {
  const display = family(props.displayFont, displayFamily);
  const body = family(props.bodyFont, bodyFamily);
  const mono = family(props.monoFont, monoFamily);
  let cursor = 0;
  const shots = props.shots.map((shot) => {
    const durationInFrames = Math.max(1, Math.round(shot.durationSec * 30));
    const from = cursor;
    cursor += durationInFrames;
    return { shot, from, durationInFrames };
  });

  return (
    <AbsoluteFill style={{ background: props.colors.bg }}>
      {shots.map(({ shot, from, durationInFrames }) => (
        <Sequence key={shot.id} from={from} durationInFrames={durationInFrames}>
          {shot.type === "type" || !shot.src ? (
            <TypeCard shot={shot} props={props} display={display} body={body} mono={mono} />
          ) : (
            <MediaCard shot={shot} props={props} display={display} body={body} mono={mono} />
          )}
        </Sequence>
      ))}
      {props.voiceSrc ? <Audio src={props.voiceSrc} /> : null}
      {props.musicSrc ? <Audio src={props.musicSrc} volume={0.12} /> : null}
    </AbsoluteFill>
  );
};
