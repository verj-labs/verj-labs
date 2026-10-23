"use client";

import { useEffect, useState } from "react";
import type { RunShot, RunView, TimelineStep } from "@/pipeline/types";

const STEPS: { id: TimelineStep; title: string }[] = [
  { id: "idea", title: "Idea" },
  { id: "art", title: "Art direction" },
  { id: "generate", title: "Generation" },
  { id: "render", title: "Render" },
  { id: "video", title: "Video" },
];

type StepState = "pending" | "running" | "done" | "error" | "awaiting";

const STATE_LABEL: Record<StepState, string> = {
  pending: "Pending",
  running: "Thinking",
  awaiting: "Waiting",
  done: "Done",
  error: "Error",
};

const KIND: Record<string, string> = {
  "case-study": "Case study",
  service: "Service",
  opinion: "Opinion",
};

function stepStates(run: RunView): Record<TimelineStep, StepState> {
  const stages = run.stages;
  const idea: StepState =
    stages.director === "done"
      ? "done"
      : stages.director === "error" || stages.intake === "error"
        ? "error"
        : stages.intake === "running" || stages.director === "running" || run.stage === "intake"
          ? "running"
          : "pending";
  const art: StepState =
    stages.art === "error"
      ? "error"
      : run.hold === "frames" || run.stage === "awaiting"
        ? "awaiting"
        : stages.art === "running"
          ? "running"
          : stages.art === "done"
            ? "done"
            : "pending";
  const generate: StepState =
    stages.generation === "error" ? "error" : stages.generation === "running" ? "running" : stages.generation === "done" ? "done" : "pending";
  const render: StepState =
    stages.render === "error" ? "error" : stages.render === "running" ? "running" : stages.render === "done" ? "done" : "pending";
  const video: StepState =
    stages.critic === "error"
      ? "error"
      : stages.critic === "running"
        ? "running"
        : run.stage === "done" || run.videoUrl
          ? "done"
          : "pending";
  return { idea, art, generate, render, video };
}

function activeStep(run: RunView, states: Record<TimelineStep, StepState>): TimelineStep {
  if (run.stage === "done") return "video";
  return STEPS.find((step) => states[step.id] === "running" || states[step.id] === "awaiting" || states[step.id] === "error")?.id ?? "idea";
}

function FrameEditor({
  shot,
  label,
  imageUrl,
  prompt,
  waiting,
  busy,
  onPrompt,
  onRedraw,
}: {
  shot: RunShot;
  label: string;
  imageUrl: string | null;
  prompt: string;
  waiting: boolean;
  busy: boolean;
  onPrompt: (value: string) => void;
  onRedraw: () => void;
}) {
  return (
    <div className="frame">
      <span className="mono">{label}</span>
      {imageUrl ? <img src={imageUrl} alt={`${label} frame for ${shot.id}`} /> : <div className="empty-frame">Not drawn yet</div>}
      {waiting ? (
        <>
          <textarea className="prompt" value={prompt} onChange={(event) => onPrompt(event.target.value)} disabled={busy} />
          <button type="button" className="ghost" onClick={onRedraw} disabled={busy || !prompt.trim()}>
            {busy ? "Redrawing" : "Redraw"}
          </button>
        </>
      ) : null}
    </div>
  );
}

export function Timeline({ run, onRefresh }: { run: RunView; onRefresh: (id: string) => Promise<void> }) {
  const states = stepStates(run);
  const active = activeStep(run, states);
  const [opened, setOpened] = useState<Partial<Record<TimelineStep, boolean>>>({});
  const [prompts, setPrompts] = useState<Record<string, string>>({});
  const [busyFrame, setBusyFrame] = useState("");
  const [actionError, setActionError] = useState("");
  const [continuing, setContinuing] = useState(false);
  const [retrying, setRetrying] = useState(false);

  useEffect(() => {
    setOpened((current) => ({ ...current, [active]: true }));
  }, [active]);

  function isOpen(step: TimelineStep): boolean {
    return opened[step] ?? step === active;
  }

  async function redraw(shot: RunShot, frame: "start" | "end") {
    const key = `${shot.id}:${frame}`;
    const prompt = prompts[key] ?? (frame === "start" ? shot.prompt : shot.endPrompt);
    setActionError("");
    setBusyFrame(key);
    try {
      const response = await fetch(`/api/runs/${run.id}/frames`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ shotId: shot.id, frame, prompt }),
      });
      const body = (await response.json()) as { error?: string };
      if (!response.ok) throw new Error(body.error || "Could not redraw the frame.");
      await onRefresh(run.id);
    } catch (cause) {
      setActionError(cause instanceof Error ? cause.message : "Could not redraw the frame.");
    } finally {
      setBusyFrame("");
    }
  }

  async function retryRun() {
    setActionError("");
    setRetrying(true);
    try {
      const response = await fetch(`/api/runs/${run.id}/retry`, { method: "POST" });
      const body = (await response.json()) as { error?: string };
      if (!response.ok) throw new Error(body.error || "Could not try again.");
      await onRefresh(run.id);
    } catch (cause) {
      setActionError(cause instanceof Error ? cause.message : "Could not try again.");
    } finally {
      setRetrying(false);
    }
  }

  async function continueRun() {
    setActionError("");
    setContinuing(true);
    try {
      const response = await fetch(`/api/runs/${run.id}/continue`, { method: "POST" });
      const body = (await response.json()) as { error?: string };
      if (!response.ok) throw new Error(body.error || "Could not continue.");
      await onRefresh(run.id);
    } catch (cause) {
      setActionError(cause instanceof Error ? cause.message : "Could not continue.");
    } finally {
      setContinuing(false);
    }
  }

  return (
    <section className="timeline-wrap" aria-live="polite">
      <header className="run-head">
        <p className="mono">{run.auto ? "Auto" : "Review frames"}</p>
        <p>{run.brief}</p>
        <p className="path">{run.runPath}</p>
        {run.stage === "error" ? (
          <button type="button" className="primary" onClick={() => void retryRun()} disabled={retrying}>
            {retrying ? "Trying again" : "Try again"}
          </button>
        ) : null}
        {actionError ? <p className="error">{actionError}</p> : null}
        {run.error ? <p className="error">{run.error}</p> : null}
      </header>
      <ol className="timeline">
        {STEPS.map((step) => {
          const state = states[step.id];
          const lines = run.trace.filter((line) => line.step === step.id);
          const showLive = (state === "running" || state === "awaiting") && Boolean(run.detail) && lines.at(-1)?.text !== run.detail;
          return (
            <li key={step.id} className="step" data-state={state}>
              <div className="rail" aria-hidden="true">
                <span className="dot" />
                <span className="stem" />
              </div>
              <details
                className="panel"
                open={isOpen(step.id)}
                onToggle={(event) => {
                  const next = event.currentTarget.open;
                  setOpened((current) => (current[step.id] === next ? current : { ...current, [step.id]: next }));
                }}
              >
                <summary>
                  <span>{step.title}</span>
                  <span className="mono">{STATE_LABEL[state]}</span>
                </summary>
                <div className="body">
                  {lines.length > 0 ? (
                    <ul className="trace">
                      {lines.map((line) => (
                        <li key={`${line.at}-${line.text}`}>{line.text}</li>
                      ))}
                    </ul>
                  ) : null}
                  {showLive ? (
                    <p className="live">
                      <span className="pulse" />
                      {run.detail}
                    </p>
                  ) : null}
                  {state === "error" && run.error ? <p className="error">{run.error}</p> : null}
                  {step.id === "idea" ? <Idea run={run} /> : null}
                  {step.id === "art" ? (
                    <Art
                      run={run}
                      waiting={state === "awaiting"}
                      prompts={prompts}
                      busyFrame={busyFrame}
                      continuing={continuing}
                      actionError={actionError}
                      onPrompt={(key, value) => setPrompts((current) => ({ ...current, [key]: value }))}
                      onRedraw={redraw}
                      onContinue={continueRun}
                    />
                  ) : null}
                  {step.id === "generate" ? <Generation run={run} /> : null}
                  {step.id === "render" ? <Render state={state} /> : null}
                  {step.id === "video" ? <Video run={run} /> : null}
                </div>
              </details>
            </li>
          );
        })}
      </ol>
    </section>
  );
}

function Idea({ run }: { run: RunView }) {
  if (!run.director) return null;
  return (
    <div className="stack">
      {run.director.rationale ? <p className="decision">{run.director.rationale}</p> : null}
      {run.director.kind ? <p className="mono">{KIND[run.director.kind] ?? run.director.kind}</p> : null}
      <ol className="script">
        {run.director.beats.map((beat) => (
          <li key={beat.id}>
            <span className="mono">
              {beat.role} · {beat.durationSec}s
            </span>
            <p className="screen">{beat.onScreenText}</p>
            <p>{beat.spokenLine}</p>
            {beat.visualIntent ? <p className="note">{beat.visualIntent}</p> : null}
          </li>
        ))}
      </ol>
    </div>
  );
}

function Art({
  run,
  waiting,
  prompts,
  busyFrame,
  continuing,
  actionError,
  onPrompt,
  onRedraw,
  onContinue,
}: {
  run: RunView;
  waiting: boolean;
  prompts: Record<string, string>;
  busyFrame: string;
  continuing: boolean;
  actionError: string;
  onPrompt: (key: string, value: string) => void;
  onRedraw: (shot: RunShot, frame: "start" | "end") => void;
  onContinue: () => void;
}) {
  if (!run.shots) return null;
  return (
    <div className="stack">
      {waiting ? <p className="note">Edit a prompt and redraw that frame. Video starts when you continue.</p> : null}
      {run.shots.map((shot) => (
        <article key={shot.id} className="shot">
          <span className="mono">
            {shot.role} · {shot.type} · {shot.durationSec}s
          </span>
          {shot.reason ? <p>{shot.reason}</p> : null}
          <p className="screen">{shot.onScreenText}</p>
          <p>{shot.spokenLine}</p>
          {shot.type === "proof" && shot.proofUrl ? <img className="proof" src={shot.proofUrl} alt={shot.onScreenText} /> : null}
          {shot.type === "generate" ? (
            <div className="pair">
              <FrameEditor
                shot={shot}
                label="Start"
                imageUrl={shot.stillUrl}
                prompt={prompts[`${shot.id}:start`] ?? shot.prompt}
                waiting={waiting}
                busy={busyFrame === `${shot.id}:start`}
                onPrompt={(value) => onPrompt(`${shot.id}:start`, value)}
                onRedraw={() => onRedraw(shot, "start")}
              />
              <FrameEditor
                shot={shot}
                label="End"
                imageUrl={shot.endStillUrl}
                prompt={prompts[`${shot.id}:end`] ?? shot.endPrompt}
                waiting={waiting}
                busy={busyFrame === `${shot.id}:end`}
                onPrompt={(value) => onPrompt(`${shot.id}:end`, value)}
                onRedraw={() => onRedraw(shot, "end")}
              />
            </div>
          ) : null}
        </article>
      ))}
      {waiting ? (
        <div className="stack">
          {actionError ? <p className="error">{actionError}</p> : null}
          <button type="button" className="primary" onClick={onContinue} disabled={continuing || Boolean(busyFrame)}>
            {continuing ? "Starting video" : "Make the videos"}
          </button>
        </div>
      ) : null}
    </div>
  );
}

function Generation({ run }: { run: RunView }) {
  const shots = (run.shots ?? []).filter((shot) => shot.stillUrl || shot.endStillUrl || shot.clipUrl || shot.proofUrl);
  if (!run.voiceUrl && !run.musicUrl && shots.length === 0 && run.warnings.length === 0) return null;
  return (
    <div className="stack">
      {run.warnings.map((warning) => (
        <p key={warning} className="error">
          {warning}
        </p>
      ))}
      {run.voiceUrl ? (
        <figure>
          <figcaption className="mono">Voiceover</figcaption>
          <audio src={run.voiceUrl} controls />
        </figure>
      ) : null}
      {run.musicUrl ? (
        <figure>
          <figcaption className="mono">Music</figcaption>
          <audio src={run.musicUrl} controls />
        </figure>
      ) : null}
      {shots.length > 0 ? (
        <div className="media">
          {shots.map((shot) => (
            <div key={shot.id} className="media-shot">
              <span className="mono">{shot.id}</span>
              <div className="pair">
                {shot.stillUrl ? (
                  <figure>
                    <figcaption className="mono">Start</figcaption>
                    <img src={shot.stillUrl} alt={`Start frame ${shot.id}`} />
                  </figure>
                ) : null}
                {shot.endStillUrl ? (
                  <figure>
                    <figcaption className="mono">End</figcaption>
                    <img src={shot.endStillUrl} alt={`End frame ${shot.id}`} />
                  </figure>
                ) : null}
                {shot.proofUrl ? (
                  <figure>
                    <figcaption className="mono">Proof</figcaption>
                    <img src={shot.proofUrl} alt={shot.onScreenText} />
                  </figure>
                ) : null}
                {shot.clipUrl ? (
                  <figure>
                    <figcaption className="mono">Clip</figcaption>
                    <video src={shot.clipUrl} controls playsInline />
                  </figure>
                ) : null}
              </div>
            </div>
          ))}
        </div>
      ) : null}
    </div>
  );
}

function Render({ state }: { state: StepState }) {
  if (state === "running") {
    return (
      <div className="wave" aria-hidden="true">
        {Array.from({ length: 16 }, (_, index) => (
          <span key={index} style={{ animationDelay: `${index * 0.08}s` }} />
        ))}
      </div>
    );
  }
  if (state === "done") return <p>The cut is rendered.</p>;
  return null;
}

function Video({ run }: { run: RunView }) {
  if (!run.videoUrl && !run.caption && !run.notes) return null;
  return (
    <div className="stack">
      {run.videoUrl ? <video className="final" src={run.videoUrl} controls playsInline /> : null}
      {run.caption ? (
        <div>
          <p className="mono">Caption</p>
          <pre className="caption">{run.caption}</pre>
        </div>
      ) : null}
      {run.notes ? (
        <div>
          <p className="mono">
            {run.notes.passed ? "Critic passed" : "Critic notes"}
            {run.notes.repaired ? " · repaired once" : ""}
          </p>
          {run.notes.issues.length > 0 ? <pre className="notes">{run.notes.issues.join("\n")}</pre> : null}
        </div>
      ) : null}
    </div>
  );
}
