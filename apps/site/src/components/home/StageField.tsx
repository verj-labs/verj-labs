"use client";

import { useEffect, useRef } from "react";

// Tones from black through darker greens to lime.
const TONES: [number, number, number][] = [
  [10, 10, 10],
  [18, 26, 6],
  [30, 44, 4],
  [61, 82, 0],
  [110, 140, 8],
  [150, 185, 16],
  [190, 224, 40],
  [212, 245, 60],
];

const smooth = (a: number, b: number, v: number) => {
  const t = Math.min(Math.max((v - a) / (b - a), 0), 1);
  return t * t * (3 - 2 * t);
};
const hash = (x: number, y: number, k: number) => {
  const n = Math.sin(x * 127.1 + y * 311.7 + k * 74.7) * 43758.5453;
  return n - Math.floor(n);
};

/** The scroll stage field. Starts mostly black with a few green pixels; scroll progress
 *  lights more of them, from the bottom up, in a spread of greens until it is mostly lime. */
export default function StageField({ progress, className }: { progress: React.MutableRefObject<number>; className?: string }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let cols = 1;
    let rows = 1;
    let img: ImageData | null = null;
    let visible = true;
    let raf = 0;
    let last = 0;
    const t0 = performance.now();

    const resize = () => {
      const r = canvas.getBoundingClientRect();
      const cell = r.width < 800 ? 6 : 8;
      cols = Math.max(1, Math.ceil(r.width / cell));
      rows = Math.max(1, Math.ceil(r.height / cell));
      canvas.width = cols;
      canvas.height = rows;
      img = ctx.createImageData(cols, rows);
    };

    const draw = (now: number) => {
      if (!img) return;
      const d = img.data;
      const t = reduce ? 0 : (now - t0) / 1000;
      const p = progress.current;
      const base = 0.05 + 1.3 * smooth(0.03, 0.42, p);
      const tick = Math.floor(t * 6);
      for (let y = 0; y < rows; y++) {
        const fy = y / (rows - 1 || 1);
        // a slow band that travels with the scroll
        const sweep = Math.sin(y * 0.06 - p * 18) * 0.06;
        for (let x = 0; x < cols; x++) {
          const h = hash(x, y, 0);
          const th = 0.55 * h + 0.45 * (1 - fy);
          const heat = base + sweep - th;
          let c = TONES[0];
          if (heat > 0) {
            const k = Math.min(TONES.length - 1, 2 + Math.floor(heat * 9));
            c = TONES[k];
            // Once lit, the field keeps live: black and dark-green pixels flicker through it in drifting bands.
            const band = 0.5 + 0.5 * Math.sin(y * 0.045 - t * 0.9 + x * 0.02 + p * 6);
            const dens = 0.025 + band * 0.1;
            const f = hash(x, y, tick + 11);
            if (f < dens * 0.45) c = TONES[0];
            else if (f < dens * 0.8) c = TONES[2];
            else if (f < dens) c = TONES[3];
          } else {
            const f = hash(x, y, tick + 3);
            if (f < 0.018) c = TONES[1];
            else if (f < 0.022) c = TONES[3];
          }
          const o = (y * cols + x) * 4;
          d[o] = c[0];
          d[o + 1] = c[1];
          d[o + 2] = c[2];
          d[o + 3] = 255;
        }
      }
      ctx.putImageData(img, 0, 0);
    };

    const loop = (now: number) => {
      raf = requestAnimationFrame(loop);
      if (!visible || now - last < 1000 / 24) return;
      last = now;
      draw(now);
    };

    resize();
    draw(performance.now());
    const ro = new ResizeObserver(() => {
      resize();
      draw(performance.now());
    });
    ro.observe(canvas);
    const io = new IntersectionObserver(([e]) => {
      visible = e.isIntersecting;
    });
    io.observe(canvas);
    if (!reduce) raf = requestAnimationFrame(loop);
    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
      io.disconnect();
    };
  }, [progress]);

  return <canvas ref={ref} className={className} aria-hidden="true" />;
}
