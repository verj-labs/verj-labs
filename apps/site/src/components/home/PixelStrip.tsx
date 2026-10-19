"use client";

import { useEffect, useRef } from "react";

const CELL = 6;
const ROWS = 8;

/** A thin, full-width ticker of lime squares. It scrolls like a data stream. */
export default function PixelStrip({ className }: { className?: string }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let cols = 0;
    let visible = true;
    let raf = 0;
    let last = 0;
    let offset = 0;

    // A column's height is deterministic from its index, so the pattern scrolls as it moves left.
    const height = (i: number) => {
      const a = Math.sin(i * 0.9) + Math.sin(i * 0.37 + 1.3) + Math.sin(i * 0.11);
      const h = Math.round(((a + 3) / 6) * ROWS);
      return Math.min(ROWS, Math.max(i % 7 === 0 ? 0 : 1, h));
    };

    const resize = () => {
      const r = canvas.getBoundingClientRect();
      canvas.width = Math.max(1, Math.floor(r.width));
      canvas.height = CELL * ROWS;
      cols = Math.ceil(canvas.width / CELL);
    };

    const draw = () => {
      ctx.fillStyle = "#0A0A0A";
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      for (let x = 0; x < cols; x++) {
        const h = height(x + offset);
        for (let r = 0; r < h; r++) {
          ctx.fillStyle = r === h - 1 ? "#D4F53C" : "#8FB10A";
          ctx.fillRect(x * CELL, (ROWS - 1 - r) * CELL, CELL - 1, CELL - 1);
        }
      }
    };

    const loop = (now: number) => {
      raf = requestAnimationFrame(loop);
      if (!visible || now - last < 1000 / 14) return;
      last = now;
      offset += 1;
      draw();
    };

    resize();
    draw();
    const ro = new ResizeObserver(() => {
      resize();
      draw();
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
  }, []);

  return <canvas ref={ref} className={className} aria-hidden="true" />;
}
