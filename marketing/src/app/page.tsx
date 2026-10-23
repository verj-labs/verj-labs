"use client";

import { useEffect, useState } from "react";
import { Timeline } from "./timeline";
import type { RunStatus, RunView } from "@/pipeline/types";

type BrandOption = { id: string; name: string };

function runLabel(run: RunStatus): string {
  if (run.hold === "frames" || run.stage === "awaiting") return "Waiting";
  if (run.stage === "done") return "Done";
  if (run.stage === "error") return "Error";
  return "Running";
}

export default function HomePage() {
  const [brands, setBrands] = useState<BrandOption[]>([]);
  const [brandId, setBrandId] = useState("");
  const [brief, setBrief] = useState("");
  const [auto, setAuto] = useState(false);
  const [runs, setRuns] = useState<RunStatus[]>([]);
  const [run, setRun] = useState<RunView | null>(null);
  const [error, setError] = useState("");
  const [starting, setStarting] = useState(false);

  useEffect(() => {
    let cancelled = false;
    fetch("/api/brands")
      .then(async (response) => {
        const body = (await response.json()) as { brands?: BrandOption[]; error?: string };
        if (!response.ok) throw new Error(body.error || "Could not load brands.");
        return body.brands ?? [];
      })
      .then((next) => {
        if (cancelled) return;
        setBrands(next);
        setBrandId((current) => current || next[0]?.id || "");
      })
      .catch((cause: unknown) => {
        if (!cancelled) setError(cause instanceof Error ? cause.message : "Could not load brands.");
      });
    return () => {
      cancelled = true;
    };
  }, []);

  async function refreshRuns() {
    const response = await fetch("/api/runs");
    if (!response.ok) return;
    const body = (await response.json()) as { runs?: RunStatus[] };
    setRuns(body.runs ?? []);
  }

  useEffect(() => {
    void refreshRuns();
  }, []);

  async function openRun(id: string) {
    const response = await fetch(`/api/runs/${id}`);
    if (!response.ok) return;
    setRun((await response.json()) as RunView);
  }

  const runId = run?.id;
  const runStage = run?.stage;
  useEffect(() => {
    if (!runId || runStage === "done" || runStage === "error" || runStage === "awaiting") return;
    const timer = setInterval(() => {
      void openRun(runId);
    }, 2000);
    return () => clearInterval(timer);
  }, [runId, runStage]);

  useEffect(() => {
    if (!runStage) return;
    if (runStage === "done" || runStage === "error" || runStage === "awaiting") void refreshRuns();
  }, [runId, runStage]);

  const running = Boolean(run && run.stage !== "done" && run.stage !== "error" && run.stage !== "awaiting");

  async function onSubmit(event: React.FormEvent) {
    event.preventDefault();
    setError("");
    setStarting(true);
    try {
      const response = await fetch("/api/runs", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ brandId, brief, auto }),
      });
      const body = (await response.json()) as { id?: string; error?: string };
      if (!response.ok || !body.id) throw new Error(body.error || "Could not start the run.");
      await openRun(body.id);
      await refreshRuns();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Could not start the run.");
    } finally {
      setStarting(false);
    }
  }

  return (
    <main className="page">
      <div className="top mono">
        <span>Marketing</span>
        <span>9:16</span>
      </div>
      <h1>Content pipeline</h1>
      <p className="lede">Pick a brand, write a brief, and follow the run down the timeline.</p>
      <form onSubmit={onSubmit}>
        <label>
          <span className="mono">Brand</span>
          <select value={brandId} onChange={(event) => setBrandId(event.target.value)} disabled={running || starting}>
            {brands.length === 0 ? <option value="">No brands</option> : null}
            {brands.map((brand) => (
              <option key={brand.id} value={brand.id}>
                {brand.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          <span className="mono">Brief</span>
          <textarea
            value={brief}
            onChange={(event) => setBrief(event.target.value)}
            placeholder="30 second Reel on Zavara Studio: jewelry visuals in minutes, not days."
            disabled={running || starting}
          />
        </label>
        <div className="actions">
          <label className="switch">
            <input type="checkbox" checked={auto} onChange={(event) => setAuto(event.target.checked)} disabled={running || starting} />
            <span className="track" aria-hidden="true" />
            <span>
              <span className="mono">Auto</span>
              <span className="note">On runs straight through. Off waits after the frames.</span>
            </span>
          </label>
          <button className="primary" type="submit" disabled={running || starting || !brandId || !brief.trim()}>
            {running || starting ? "Running" : "Run"}
          </button>
        </div>
      </form>
      {error ? <p className="error">{error}</p> : null}
      {runs.length > 0 ? (
        <section className="history">
          <p className="mono">Runs</p>
          <div className="history-list">
            {runs.map((item) => (
              <button
                key={item.id}
                type="button"
                className="row"
                data-current={item.id === run?.id}
                onClick={() => void openRun(item.id)}
              >
                <span className="brief">{item.brief}</span>
                <span className="mono">{runLabel(item)}</span>
              </button>
            ))}
          </div>
        </section>
      ) : null}
      {run ? <Timeline key={run.id} run={run} onRefresh={openRun} /> : null}
    </main>
  );
}
