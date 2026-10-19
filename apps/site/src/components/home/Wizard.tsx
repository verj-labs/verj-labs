"use client";

import { useEffect, useState } from "react";
import { CAL_URL, EMAIL, NEED_EVENT, NEEDS, needById } from "@/lib/site";

const WHEN = [
  { id: "asap", label: "As soon as possible" },
  { id: "1-3m", label: "In the next 1 to 3 months" },
  { id: "later", label: "Later this year" },
  { id: "exploring", label: "Just exploring for now" },
];

type Status = "idle" | "sending" | "done" | "error";

export default function Wizard({ initialNeed }: { initialNeed?: string }) {
  const [step, setStep] = useState(initialNeed && needById(initialNeed) ? 1 : 0);
  const [need, setNeed] = useState(initialNeed && needById(initialNeed) ? initialNeed : "");
  const [when, setWhen] = useState("");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [message, setMessage] = useState("");
  const [trap, setTrap] = useState("");
  const [status, setStatus] = useState<Status>("idle");
  const [error, setError] = useState("");

  useEffect(() => {
    const on = (e: Event) => {
      const id = (e as CustomEvent<string>).detail;
      if (needById(id)) {
        setNeed(id);
        setStep(1);
      }
    };
    window.addEventListener(NEED_EVENT, on);
    return () => window.removeEventListener(NEED_EVENT, on);
  }, []);

  const pickNeed = (id: string) => {
    setNeed(id);
    setStep(1);
  };
  const pickWhen = (id: string) => {
    setWhen(id);
    setStep(2);
  };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus("sending");
    setError("");
    try {
      const res = await fetch("/api/lead", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ need, when, name, email, phone, message, website: trap }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok || !data.ok) throw new Error(data.error || "Something went wrong.");
      setStatus("done");
    } catch (err) {
      setStatus("error");
      setError(err instanceof Error ? err.message : "Something went wrong.");
    }
  };

  if (status === "done") {
    return (
      <div className="vh-wiz vh-wiz-done" role="status">
        <p className="vh-mono">Received</p>
        <h3 className="vh-wiz-q">Thanks{name ? `, ${name.split(" ")[0]}` : ""}. We have your enquiry.</h3>
        <p>We have sent a confirmation to {email}. We will read your enquiry and reply with next steps.</p>
        <p>Want to speed things up? Pick a time that suits you.</p>
        <a className="vh-btn" href={CAL_URL} target="_blank" rel="noopener noreferrer">
          Book a call
        </a>
      </div>
    );
  }

  const chosen = needById(need);

  return (
    <div className="vh-wiz">
      <div className="vh-wiz-top">
        <p className="vh-mono">Step {step + 1} of 3</p>
        <div className="vh-wiz-bar" aria-hidden="true">
          {[0, 1, 2].map((i) => (
            <span key={i} data-on={i <= step ? "true" : "false"} />
          ))}
        </div>
      </div>

      {step === 0 && (
        <div className="vh-wiz-step">
          <h3 className="vh-wiz-q">What do you need?</h3>
          <div className="vh-wiz-options">
            {NEEDS.map((n) => (
              <button key={n.id} type="button" className="vh-opt" data-on={need === n.id ? "true" : "false"} onClick={() => pickNeed(n.id)}>
                {n.label}
              </button>
            ))}
            <button type="button" className="vh-opt" data-on={need === "unsure" ? "true" : "false"} onClick={() => pickNeed("unsure")}>
              Not sure yet
            </button>
          </div>
        </div>
      )}

      {step === 1 && (
        <div className="vh-wiz-step">
          <h3 className="vh-wiz-q">When would you like to start?</h3>
          <div className="vh-wiz-options">
            {WHEN.map((w) => (
              <button key={w.id} type="button" className="vh-opt" data-on={when === w.id ? "true" : "false"} onClick={() => pickWhen(w.id)}>
                {w.label}
              </button>
            ))}
          </div>
          <button type="button" className="vh-link" onClick={() => setStep(0)}>
            Back
          </button>
        </div>
      )}

      {step === 2 && (
        <form className="vh-wiz-step" onSubmit={submit}>
          <h3 className="vh-wiz-q">Where should we reply?</h3>
          <p className="vh-mono vh-wiz-sum">
            {chosen ? chosen.label : "Not sure yet"} / {WHEN.find((w) => w.id === when)?.label ?? "No date yet"}
          </p>
          <div className="vh-fields">
            <label>
              <span className="vh-mono">Your name</span>
              <input name="name" required maxLength={120} autoComplete="name" value={name} onChange={(e) => setName(e.target.value)} />
            </label>
            <label>
              <span className="vh-mono">Email</span>
              <input name="email" type="email" required maxLength={200} autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} />
            </label>
            <label>
              <span className="vh-mono">Phone (optional)</span>
              <input name="phone" type="tel" maxLength={40} autoComplete="tel" value={phone} onChange={(e) => setPhone(e.target.value)} />
            </label>
            <label className="vh-field-wide">
              <span className="vh-mono">Anything we should know? (optional)</span>
              <textarea name="message" rows={3} maxLength={2000} value={message} onChange={(e) => setMessage(e.target.value)} />
            </label>
            <label className="vh-trap" aria-hidden="true">
              Website
              <input tabIndex={-1} autoComplete="off" value={trap} onChange={(e) => setTrap(e.target.value)} />
            </label>
          </div>
          {status === "error" && (
            <p className="vh-wiz-error" role="alert">
              {error} You can also email us at <a href={`mailto:${EMAIL}`}>{EMAIL}</a>.
            </p>
          )}
          <div className="vh-wiz-actions">
            <button type="submit" className="vh-btn" disabled={status === "sending"}>
              {status === "sending" ? "Sending..." : "Send my enquiry"}
            </button>
            <button type="button" className="vh-link" onClick={() => setStep(1)}>
              Back
            </button>
          </div>
          <p className="vh-wiz-note">We only use your details to reply to this enquiry.</p>
        </form>
      )}

      <p className="vh-wiz-alt">
        Prefer to talk it through?{" "}
        <a href={CAL_URL} target="_blank" rel="noopener noreferrer">
          Book a call
        </a>
      </p>
    </div>
  );
}
