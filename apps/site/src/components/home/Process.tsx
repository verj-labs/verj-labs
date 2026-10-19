"use client";

import { useState } from "react";
import { CAL_URL, NEED_EVENT, NEEDS, NeedId } from "@/lib/site";

const STEPS = [
  {
    name: "Plan",
    title: "We plan it with you",
    text: "We start by understanding what you need and who it is for. You get a clear plan, a fixed scope and a timeline before any building starts.",
    gets: ["A clear plan and scope", "A timeline you can plan around", "No surprises later"],
  },
  {
    name: "Design",
    title: "We design it first",
    text: "We design how it will look and work, and show you before anything is built. You review it and approve it.",
    gets: ["A design you review and approve", "Changes while they are still cheap"],
  },
  {
    name: "Build",
    title: "We build it in the open",
    text: "We build in short cycles so you can see progress and test along the way. No long silences and no big reveal at the end.",
    gets: ["Regular progress you can see", "Testing as we go"],
  },
  {
    name: "Launch",
    title: "We launch it and stay on",
    text: "We put it live, check that it works for real users and keep improving it after launch. When you want to run it yourselves, we hand everything over with documentation.",
    gets: ["Launch support", "Improvements after launch", "A full handoff with documentation"],
  },
];

const DETAIL: Record<NeedId, string[]> = {
  ai: [
    "We find the tasks where AI saves you the most time.",
    "We design how your team will use it day to day.",
    "We connect AI to your own documents and tools.",
    "We measure the quality of the answers and keep tuning it.",
  ],
  product: [
    "We turn your idea into a clear plan and a first version.",
    "We design the product and its main journeys.",
    "We build and test the full product.",
    "We put it live and keep improving it.",
  ],
  web: [
    "We plan the pages, the content and what you want to edit yourself.",
    "We design the site and its page templates.",
    "We build it with an editor you can use without code.",
    "We launch it and hand it over with documentation.",
  ],
  mobile: [
    "We plan the app, its screens and what ships first.",
    "We design it for both iPhone and Android.",
    "We build one app that runs on both.",
    "We get it ready for the app stores.",
  ],
  tools: [
    "We learn how your team works today and where time is lost.",
    "We design the screens your team will use every day.",
    "We build the tool and test it with the people who will use it.",
    "We roll it out and hand it over with documentation.",
  ],
  store: [
    "We plan your catalog, checkout and what you want to manage yourself.",
    "We design the storefront around your products.",
    "We build the store with an editor you can use without code.",
    "We launch it and hand it over with documentation.",
  ],
  rebuild: [
    "We review what you have today and what is holding you back.",
    "We design the improved version and how to move over safely.",
    "We rebuild it step by step so your team can keep working.",
    "We switch over, check everything works and hand it over.",
  ],
};

export default function Process() {
  const [need, setNeed] = useState<NeedId>("ai");
  const [step, setStep] = useState(0);
  const n = NEEDS.find((x) => x.id === need)!;
  const s = STEPS[step];

  const start = () => {
    window.dispatchEvent(new CustomEvent(NEED_EVENT, { detail: need }));
    const target = document.getElementById("start");
    if (target) target.scrollIntoView({ behavior: "smooth", block: "start" });
    else window.location.href = `/contact?need=${need}`;
  };

  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowRight") setStep((v) => Math.min(3, v + 1));
    if (e.key === "ArrowLeft") setStep((v) => Math.max(0, v - 1));
  };

  return (
    <div className="vh-proc">
      <div className="vh-proc-block">
        <p className="vh-mono vh-proc-label">1. What do you want to build?</p>
        <div className="vh-needs" role="radiogroup" aria-label="What do you want to build?">
          {NEEDS.map((x) => (
            <button
              key={x.id}
              type="button"
              role="radio"
              aria-checked={x.id === need}
              className="vh-need"
              onClick={() => {
                setNeed(x.id);
                setStep(0);
              }}
            >
              <svg viewBox="0 0 7 6" className="vh-need-icon" aria-hidden="true" shapeRendering="crispEdges">
                {x.icon.flatMap((r, y) =>
                  r.split("").map((c, i) => (c === "1" ? <rect key={`${i}-${y}`} x={i} y={y} width="1" height="1" /> : null)),
                )}
              </svg>
              <span className="vh-need-name">{x.label}</span>
              <span className="vh-mono vh-need-time">{x.time}</span>
            </button>
          ))}
          <a className="vh-need vh-need-other" href="/contact">
            <span className="vh-need-name">Something else?</span>
            <span className="vh-mono vh-need-time">Tell us what you need &rarr;</span>
          </a>
        </div>
      </div>

      <div className="vh-proc-block">
        <p className="vh-mono vh-proc-label">2. Here is how it runs</p>
        <div className="vh-stepper" onKeyDown={onKey} style={{ "--k": step / 3 } as React.CSSProperties}>
          <span className="vh-stepper-fill" aria-hidden="true" />
          <ol role="tablist" aria-label="Project steps">
            {STEPS.map((x, i) => (
              <li key={x.name}>
                <button
                  type="button"
                  role="tab"
                  aria-selected={i === step}
                  data-done={i < step ? "true" : "false"}
                  onClick={() => setStep(i)}
                >
                  <span className="vh-step-no">{i + 1}</span>
                  <span className="vh-step-name">{x.name}</span>
                </button>
              </li>
            ))}
          </ol>
        </div>

        <div className="vh-step-body" key={`${need}-${step}`}>
          <div className="vh-step-text">
            <h3>{s.title}</h3>
            <p className="vh-step-for">{DETAIL[need][step]}</p>
            <p>{s.text}</p>
            <ul>
              {s.gets.map((g) => (
                <li key={g}>{g}</li>
              ))}
            </ul>
          </div>
          <div className="vh-step-visual" data-ui>
            {step === 0 && (
              <div className="vh-visual-card">
                <p className="vh-mono">Timeline</p>
                <p className="vh-visual-big">{n.weeks}</p>
                <p className="vh-mono">Confirmed when we plan it</p>
              </div>
            )}
            {step === 1 && (
              <div className="vh-visual-card">
                <p className="vh-mono">You review the design</p>
                <svg viewBox="0 0 7 6" className="vh-visual-icon" aria-hidden="true" shapeRendering="crispEdges">
                  {n.icon.flatMap((r, y) =>
                    r.split("").map((c, i) => (c === "1" ? <rect key={`${i}-${y}`} x={i} y={y} width="1" height="1" /> : null)),
                  )}
                </svg>
                <p className="vh-mono">Before we build</p>
              </div>
            )}
            {step === 2 && (
              <div className="vh-visual-card">
                <p className="vh-mono">Built in short cycles</p>
                <div className="vh-bits" aria-hidden="true">
                  {Array.from({ length: 60 }).map((_, i) => (
                    <span key={i} style={{ "--i": i } as React.CSSProperties} />
                  ))}
                </div>
              </div>
            )}
            {step === 3 && (
              <div className="vh-visual-card">
                <p className="vh-mono">Status</p>
                <p className="vh-visual-big vh-live">Live</p>
                <p className="vh-mono">Now improving</p>
              </div>
            )}
          </div>
        </div>

        <div className="vh-proc-nav">
          <button type="button" className="vh-btn vh-btn-ghost" onClick={() => setStep((v) => Math.max(0, v - 1))} disabled={step === 0}>
            Back
          </button>
          {step < 3 ? (
            <button type="button" className="vh-btn" onClick={() => setStep((v) => Math.min(3, v + 1))}>
              Next: {STEPS[step + 1].name}
            </button>
          ) : (
            <button type="button" className="vh-btn" onClick={start}>
              Start my project
            </button>
          )}
        </div>
      </div>

      <div className="vh-proc-cta">
        <p className="vh-proc-cta-text">Ready to talk about {n.label.toLowerCase()}?</p>
        <div className="vh-proc-cta-actions">
          <button type="button" className="vh-btn" onClick={start}>
            Tell us what you need
          </button>
          <a className="vh-btn vh-btn-ghost" href={CAL_URL} target="_blank" rel="noopener noreferrer">
            Book a call
          </a>
        </div>
      </div>
    </div>
  );
}
