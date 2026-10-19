"use client";

import { useEffect, useRef } from "react";
import StageField from "./StageField";
import PixelLogo from "./PixelLogo";

const ease = (t: number) => (t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2);
const clamp = (v: number) => Math.min(Math.max(v, 0), 1);

/** A pinned screen. VERJ starts large in the middle, drifts to the bottom right as you scroll,
 *  and the content arrives in the centre. Without script or with reduced motion it shows the end state. */
export default function ScrollStage({ children }: { children: React.ReactNode }) {
  const wrap = useRef<HTMLElement>(null);
  const progress = useRef(1);

  useEffect(() => {
    const el = wrap.current;
    if (!el) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    el.classList.add("is-live");
    let raf = 0;

    const update = () => {
      raf = 0;
      const r = el.getBoundingClientRect();
      const total = r.height - window.innerHeight;
      const p = total > 0 ? clamp(-r.top / total) : 1;
      progress.current = p;
      // 1: the field fills and VERJ turns black, still centred. 2: VERJ travels down and right. 3: the card arrives.
      el.style.setProperty("--e", String(ease(clamp((p - 0.4) / 0.35))));
      el.style.setProperty("--g", String(ease(clamp((p - 0.08) / 0.3))));
      const c = ease(clamp((p - 0.72) / 0.22));
      el.style.setProperty("--c", String(c));
      el.style.setProperty("--vis", c > 0.05 ? "visible" : "hidden");
    };
    const onScroll = () => {
      if (!raf) raf = requestAnimationFrame(update);
    };
    update();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);
    return () => {
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
      if (raf) cancelAnimationFrame(raf);
    };
  }, []);

  return (
    <section ref={wrap} className="vh-stage" aria-label="About Verj Labs">
      <div className="vh-stage-pin">
        <StageField progress={progress} className="vh-stage-bg" />
        <div className="vh-stage-panel">{children}</div>
        <PixelLogo className="vh-stage-logo" title="Verj" />
      </div>
    </section>
  );
}
