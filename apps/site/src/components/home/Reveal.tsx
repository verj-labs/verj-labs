"use client";

import { useEffect, useRef } from "react";

type Props = {
  children: React.ReactNode;
  as?: "div" | "section" | "li" | "p";
  className?: string;
  delay?: number;
};

/** Entrance on scroll. Content is visible until script runs, and only
 *  elements below the fold are hidden, so nothing is lost without JS. */
export default function Reveal({ children, as: Tag = "div", className = "", delay = 0 }: Props) {
  const ref = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    if (el.getBoundingClientRect().top < window.innerHeight * 0.9) return;
    el.classList.add("rv");
    const io = new IntersectionObserver(
      ([e]) => {
        if (e.isIntersecting) {
          el.classList.add("rv-in");
          io.disconnect();
        }
      },
      { threshold: 0.15 },
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);

  const Comp = Tag as React.ElementType;
  return (
    <Comp ref={ref} className={className} style={{ "--d": `${delay}ms` } as React.CSSProperties}>
      {children}
    </Comp>
  );
}
