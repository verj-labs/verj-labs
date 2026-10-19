"use client";

import { useEffect, useRef } from "react";

// A ramp from black to lime. Neighbouring tones are dithered into each other,
// so the gradient is made of hard-edged squares but reads as a smooth ramp.
const RAMP: [number, number, number][] = [
  [10, 10, 10],
  [24, 34, 6],
  [45, 62, 2],
  [82, 106, 4],
  [130, 160, 10],
  [176, 206, 30],
  [212, 245, 60],
];
const N = 8;
const BAYER: number[] = (() => {
  let m = [[0]];
  for (let s = 1; s < N; s *= 2) {
    const next: number[][] = [];
    for (let y = 0; y < s * 2; y++) {
      next.push([]);
      for (let x = 0; x < s * 2; x++) {
        next[y].push(m[y % s][x % s] * 4 + [0, 2, 3, 1][(y >= s ? 2 : 0) + (x >= s ? 1 : 0)]);
      }
    }
    m = next;
  }
  return m.flat();
})();

const smooth = (a: number, b: number, v: number) => {
  const t = Math.min(Math.max((v - a) / (b - a), 0), 1);
  return t * t * (3 - 2 * t);
};
type Props = {
  /** Where, from the top (0 to 1), the lime starts to creep in. */
  start?: number;
  className?: string;
};

export default function PixelCanvas({ start = 0.4, className }: Props) {
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
      const cell = r.width < 800 ? 4 : 5;
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
      for (let y = 0; y < rows; y++) {
        const fy = y / (rows - 1 || 1);
        const base = smooth(start, 1, fy);
        for (let x = 0; x < cols; x++) {
          let c: [number, number, number];
          {
            const wave = Math.sin(x * 0.11 + t * 0.9) * 0.03 + Math.sin(x * 0.037 - t * 0.5) * 0.025;
            const v = Math.min(Math.max(base + wave * base * 3, 0), 1);
            const th = (BAYER[(y % N) * N + (x % N)] + 0.5) / (N * N);
            const s = v * (RAMP.length - 1);
            const i = Math.floor(s);
            c = RAMP[Math.min(RAMP.length - 1, i + (s - i > th ? 1 : 0))];
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
      const gap = 1000 / 10;
      if (!visible || now - last < gap) return;
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
  }, [start]);

  return <canvas ref={ref} className={className} aria-hidden="true" />;
}
