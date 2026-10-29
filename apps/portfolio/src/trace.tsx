import { useEffect, useRef } from "react";
import { hopsOf, type Trace } from "./content";

type Props = {
  trace: Trace;
  hop: number;
  playing: boolean;
  run: number;
  onHop: (index: number) => void;
  onDone: () => void;
};

export function TraceCanvas({ trace, hop, playing, run, onHop, onDone }: Props) {
  const ref = useRef<HTMLCanvasElement>(null);
  const traceRef = useRef(trace);
  const hopRef = useRef(hop);
  const playingRef = useRef(playing);
  const onHopRef = useRef(onHop);
  const onDoneRef = useRef(onDone);
  const kick = useRef<() => void>(() => {});
  traceRef.current = trace;
  hopRef.current = hop;
  playingRef.current = playing;
  onHopRef.current = onHop;
  onDoneRef.current = onDone;

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let raf = 0;
    let started = performance.now();
    let fromHop = hopRef.current;
    let lastIndex = fromHop;
    let finished = false;

    const paint = (now: number) => {
      const hops = hopsOf(traceRef.current);
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const rect = canvas.getBoundingClientRect();
      const w = Math.max(1, rect.width);
      const h = Math.max(1, rect.height);
      const bw = Math.floor(w * dpr);
      const bh = Math.floor(h * dpr);
      if (canvas.width !== bw || canvas.height !== bh) {
        canvas.width = bw;
        canvas.height = bh;
      }
      const ctx = canvas.getContext("2d");
      if (!ctx) return;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, w, h);

      const n = Math.max(hops.length, 1);
      const vertical = w < 640;
      const boxes = hops.map((_, i) => {
        if (vertical) {
          const gap = (h - 48) / n;
          return { x: 28, y: 28 + gap * i + gap / 2, w: w - 56, h: Math.min(64, gap - 16) };
        }
        const gap = (w - 48) / n;
        return { x: 24 + gap * i, y: h * 0.42, w: Math.min(160, gap - 18), h: 72 };
      });

      ctx.lineWidth = 8;
      ctx.strokeStyle = "#dedad3";
      ctx.lineCap = "butt";
      ctx.beginPath();
      boxes.forEach((b, i) => {
        const cx = b.x + (vertical ? 0 : b.w / 2);
        const cy = vertical ? b.y : b.y + b.h / 2;
        if (i === 0) ctx.moveTo(cx, cy);
        else ctx.lineTo(cx, cy);
      });
      ctx.stroke();

      let travel = hopRef.current;
      if (playingRef.current && !reduced) {
        travel = Math.min(n - 1, fromHop + (now - started) / 900);
      }
      const index = Math.min(n - 1, Math.floor(travel + 0.001));
      if (playingRef.current && index !== lastIndex) {
        lastIndex = index;
        onHopRef.current(index);
      }
      if (playingRef.current && !finished && travel >= n - 1) {
        finished = true;
        onDoneRef.current();
      }

      const seg = Math.min(n - 2, Math.floor(travel));
      const local = n === 1 ? 0 : travel - seg;
      const a = boxes[Math.max(0, seg)];
      const b = boxes[Math.min(boxes.length - 1, seg + 1)];
      const ax = a.x + (vertical ? 8 : a.w / 2);
      const ay = vertical ? a.y : a.y + a.h / 2;
      const bx = b.x + (vertical ? 8 : b.w / 2);
      const by = vertical ? b.y : b.y + b.h / 2;
      const px = ax + (bx - ax) * local;
      const py = ay + (by - ay) * local;

      ctx.font = '500 16px "Cabinet Grotesk", sans-serif';
      ctx.textBaseline = "middle";
      boxes.forEach((b, i) => {
        const on = i === index;
        ctx.fillStyle = on ? "#256f82" : i < index ? "#0a0a0a" : "#dedad3";
        ctx.fillRect(b.x, vertical ? b.y - b.h / 2 : b.y, vertical ? b.w : b.w, b.h);
        ctx.fillStyle = on || i < index ? "#ffffff" : "#0a0a0a";
        const label = hops[i]?.short ?? "";
        ctx.fillText(label, b.x + 12, (vertical ? b.y : b.y + b.h / 2));
      });

      ctx.fillStyle = "#0a0a0a";
      ctx.fillRect(px - 8, py - 8, 16, 16);

      if (playingRef.current && !reduced && travel < n - 1) raf = requestAnimationFrame(paint);
    };

    const start = (reset: boolean) => {
      cancelAnimationFrame(raf);
      if (reset) {
        fromHop = hopRef.current;
        lastIndex = fromHop;
        started = performance.now();
        finished = false;
      }
      raf = requestAnimationFrame(paint);
    };

    kick.current = () => start(playingRef.current);
    document.fonts.ready.then(() => start(false)).catch(() => start(false));
    const onResize = () => start(false);
    window.addEventListener("resize", onResize);

    const onClick = (event: MouseEvent) => {
      const rect = canvas.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const y = event.clientY - rect.top;
      const hops = hopsOf(traceRef.current);
      const n = hops.length;
      const vertical = rect.width < 640;
      let hit = 0;
      if (vertical) hit = Math.min(n - 1, Math.max(0, Math.floor((y / rect.height) * n)));
      else hit = Math.min(n - 1, Math.max(0, Math.floor((x / rect.width) * n)));
      onHopRef.current(hit);
      void x;
    };
    canvas.addEventListener("click", onClick);

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", onResize);
      canvas.removeEventListener("click", onClick);
    };
  }, []);

  useEffect(() => {
    kick.current();
  }, [trace.id, hop, playing, run]);

  return <canvas ref={ref} className="trace-canvas" aria-hidden="true" />;
}
