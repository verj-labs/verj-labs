import { useEffect, useRef } from "react";
import { ROUTE, cityById } from "./content";

type Props = {
  cityId: string;
  onPick: (id: string) => void;
  walking: boolean;
  onArrive: (id: string) => void;
  onDone: () => void;
};

const PAD = 44;

function project(lon: number, lat: number, w: number, h: number) {
  const minLon = -110;
  const maxLon = 170;
  const minLat = -50;
  const maxLat = 58;
  const x = ((lon - minLon) / (maxLon - minLon)) * (w - PAD * 2) + PAD;
  const y = ((maxLat - lat) / (maxLat - minLat)) * (h - PAD * 2) + PAD;
  return [x, y] as const;
}

function stations(w: number, h: number) {
  return ROUTE.map((id) => {
    const city = cityById(id);
    const [x, y] = project(city.lon, city.lat, w, h);
    return { city, x, y };
  });
}

export function RouteMap({ cityId, onPick, walking, onArrive, onDone }: Props) {
  const ref = useRef<HTMLCanvasElement>(null);
  const cityRef = useRef(cityId);
  const walkingRef = useRef(walking);
  const onPickRef = useRef(onPick);
  const onArriveRef = useRef(onArrive);
  const onDoneRef = useRef(onDone);
  const kick = useRef<() => void>(() => {});
  cityRef.current = cityId;
  walkingRef.current = walking;
  onPickRef.current = onPick;
  onArriveRef.current = onArrive;
  onDoneRef.current = onDone;

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let raf = 0;
    let started = performance.now();
    let fromIndex = Math.max(0, ROUTE.indexOf(cityRef.current));
    let lastHop = fromIndex;
    let finished = false;

    const paint = (now: number) => {
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

      const pts = stations(w, h);
      ctx.lineWidth = 8;
      ctx.lineJoin = "round";
      ctx.lineCap = "butt";
      ctx.strokeStyle = "#dedad3";
      ctx.beginPath();
      pts.forEach((p, i) => (i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y)));
      ctx.stroke();

      let travel = Math.max(0, ROUTE.indexOf(cityRef.current));
      if (walkingRef.current && !reduced) {
        travel = Math.min(ROUTE.length - 1, fromIndex + (now - started) / 1600);
      }
      const seg = Math.min(ROUTE.length - 2, Math.floor(travel));
      const local = travel - seg;
      const a = pts[Math.max(0, seg)];
      const b = pts[Math.min(pts.length - 1, seg + 1)];
      const px = a.x + (b.x - a.x) * local;
      const py = a.y + (b.y - a.y) * local;
      const hop = Math.min(ROUTE.length - 1, Math.floor(travel + 0.001));
      if (walkingRef.current && hop !== lastHop) {
        lastHop = hop;
        onArriveRef.current(ROUTE[hop]);
      }
      if (walkingRef.current && !finished && travel >= ROUTE.length - 1) {
        finished = true;
        onDoneRef.current();
      }

      const active = walkingRef.current ? ROUTE[hop] : cityRef.current;
      pts.forEach((p) => {
        const on = p.city.id === active;
        const size = on ? 18 : 12;
        ctx.fillStyle = on ? "#256f82" : "#dedad3";
        ctx.fillRect(p.x - size / 2, p.y - size / 2, size, size);
      });

      ctx.fillStyle = "#ffffff";
      ctx.fillRect(px - 7, py - 7, 14, 14);

      if (walkingRef.current && !reduced && travel < ROUTE.length - 1) {
        raf = requestAnimationFrame(paint);
      }
    };

    const start = (resetClock: boolean) => {
      cancelAnimationFrame(raf);
      if (resetClock) {
        fromIndex = Math.max(0, ROUTE.indexOf(cityRef.current));
        lastHop = fromIndex;
        started = performance.now();
        finished = false;
      }
      raf = requestAnimationFrame(paint);
    };

    kick.current = () => start(walkingRef.current);
    document.fonts.ready.then(() => start(false)).catch(() => start(false));

    const onResize = () => start(false);
    window.addEventListener("resize", onResize);

    const onClick = (event: MouseEvent) => {
      const rect = canvas.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const y = event.clientY - rect.top;
      const hit = stations(rect.width, rect.height)
        .map((p) => ({ id: p.city.id, d: Math.hypot(p.x - x, p.y - y) }))
        .sort((p, q) => p.d - q.d)[0];
      if (hit && hit.d < 40) onPickRef.current(hit.id);
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
  }, [cityId, walking]);

  return <canvas ref={ref} className="route" aria-hidden="true" />;
}
