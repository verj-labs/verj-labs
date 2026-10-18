"use client";

import Link from "next/link";
import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";
import { TbArrowUpRight, TbCode, TbDatabase, TbBrandReact, TbCloud } from "react-icons/tb";

const HeroSection = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: containerRef, offset: ["start start", "end start"] });
  const limeOrbY = useTransform(scrollYProgress, [0, 1], ["0%", "35%"]);
  const purpleOrbY = useTransform(scrollYProgress, [0, 1], ["0%", "20%"]);

  return (
    <section
      ref={containerRef}
      className="relative min-h-[100svh] flex flex-col justify-center overflow-hidden px-6 pt-20 pb-12"
    >
      {/* ── Mesh orbs (parallax) ─────────────────────── */}
      <motion.div
        className="mesh-orb-lime"
        style={{
          width: 600,
          height: 600,
          top: -120,
          left: -80,
          y: limeOrbY,
        }}
        aria-hidden="true"
      />
      <motion.div
        className="mesh-orb-purple"
        style={{
          width: 500,
          height: 500,
          top: 40,
          right: -120,
          y: purpleOrbY,
        }}
        aria-hidden="true"
      />

      {/* ── Content ──────────────────────────────────── */}
      <div className="max-w-7xl mx-auto w-full relative z-10 grid lg:grid-cols-2 gap-16 items-center">
        {/* Left */}
        <div>
          {/* Badge */}
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
          >
            <span className="badge-lime mb-8 inline-flex">
              <span className="w-[5px] h-[5px] rounded-full bg-lime animate-blink" />
              Verj Labs Inc. &mdash; Canada
            </span>
          </motion.div>

          {/* Headline */}
          <motion.h1
            className="text-scale-1 font-bricolage text-off-white mb-6"
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.1, ease: [0.22, 1, 0.36, 1] }}
          >
            We build<br />
            products that<br />
            <span className="gradient-text">actually ship.</span>
          </motion.h1>

          {/* Sub */}
          <motion.p
            className="text-[1.05rem] text-off-white/50 leading-[1.75] max-w-[480px] mb-10 font-light"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.55, delay: 0.2, ease: [0.22, 1, 0.36, 1] }}
          >
            A senior-led digital studio turning bold ideas into{" "}
            <strong className="text-off-white/85 font-medium">live SaaS products</strong> and
            client solutions. From architecture to deployment — we own the full stack.
          </motion.p>

          {/* CTAs */}
          <motion.div
            className="flex gap-3 flex-wrap mb-14"
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3, ease: [0.22, 1, 0.36, 1] }}
          >
            <Link href="/portfolio" className="btn-primary">
              See Our Work &rarr;
            </Link>
            <Link href="/contact" className="btn-secondary">
              Book a Discovery Call
            </Link>
          </motion.div>

          {/* Stats */}
          <motion.div
            className="flex gap-8 flex-wrap border-t border-white/06 pt-8"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.45 }}
          >
            {[
              { num: "2", label: "Live SaaS Products" },
              // { num: "3", label: "Live SaaS Products" },
              { num: "5+", label: "Client Builds" },
              { num: "B2B", label: "& Consumer" },
              // { num: "Senior", label: "Engineers only" },
            ].map((s) => (
              <div key={s.label}>
                <div className="font-bricolage font-extrabold text-[2rem] text-lime leading-none tracking-tight" style={{ letterSpacing: "-0.03em" }}>
                  {s.num}
                </div>
                <div className="text-[0.72rem] text-off-white/35 mt-1 font-outfit" style={{ letterSpacing: "0.02em" }}>
                  {s.label}
                </div>
              </div>
            ))}
          </motion.div>
        </div>

        {/* Right — composite visual */}
        <motion.div
          className="relative hidden lg:block"
          initial={{ opacity: 0, x: 32 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.7, delay: 0.25, ease: [0.22, 1, 0.36, 1] }}
        >
          {/* Main glass panel */}
          <div className="card-glass card-glass-lime rounded-[24px] p-6">
            {/* Window chrome */}
            <div className="flex items-center gap-2 mb-5">
              <div className="w-3 h-3 rounded-full bg-[#FF6058]" />
              <div className="w-3 h-3 rounded-full bg-[#FFBD2E]" />
              <div className="w-3 h-3 rounded-full bg-[#28CA40]" />
              <div className="ml-auto flex items-center gap-1.5">
                <div className="w-1.5 h-1.5 rounded-full bg-lime animate-pulse-slow" />
                <span className="text-[0.65rem] text-off-white/30 font-outfit">live</span>
              </div>
            </div>

            {/* Code preview lines */}
            <div className="bg-[#070709] rounded-xl p-4 mb-4 font-mono text-[0.7rem] leading-relaxed border border-white/[0.06]">
              <div className="text-lime/60">{"// verj-labs / dealrdash"}</div>
              <div className="text-purple/70 mt-1">export async <span className="text-off-white/50">function</span> <span className="text-lime/80">getInventory</span><span className="text-off-white/40">(tenantId)</span> {"{"}</div>
              <div className="text-off-white/35 ml-4">const data = await <span className="text-teal/70">db.inventory</span></div>
              <div className="text-off-white/35 ml-6">.findMany{"({ where: { tenantId } })"}</div>
              <div className="text-off-white/35">{"  return data"}</div>
              <div className="text-off-white/40">{"}"}</div>
            </div>

            {/* Live metrics strip */}
            <div className="grid grid-cols-2 gap-3 mb-4">
              {[
                { icon: <TbBrandReact size={14} className="text-teal" />, label: "React", val: "18.3" },
                { icon: <TbDatabase size={14} className="text-purple" />, label: "PostgreSQL", val: "16" },
                { icon: <TbCode size={14} className="text-lime" />, label: "NestJS", val: "10.x" },
                { icon: <TbCloud size={14} className="text-amber" />, label: "AWS", val: "deployed" },
              ].map((item) => (
                <div
                  key={item.label}
                  className="flex items-center gap-2.5 bg-white/[0.03] rounded-lg px-3 py-2.5 border border-white/[0.05]"
                >
                  {item.icon}
                  <div>
                    <div className="text-[0.62rem] text-off-white/40 font-outfit">{item.label}</div>
                    <div className="text-[0.68rem] text-off-white/65 font-outfit font-medium">{item.val}</div>
                  </div>
                </div>
              ))}
            </div>

            {/* Deploy status */}
            <div className="flex items-center justify-between bg-lime/5 rounded-xl px-4 py-3 border border-lime/15">
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 rounded-full bg-lime animate-pulse-slow" />
                <span className="text-[0.72rem] text-off-white/55 font-outfit">Deploy successful</span>
              </div>
              <span className="text-[0.68rem] text-lime/70 font-outfit font-medium flex items-center gap-1">
                dealrdash.com <TbArrowUpRight size={11} />
              </span>
            </div>
          </div>

          {/* Floating secondary card */}
          <motion.div
            className="absolute -bottom-10 -left-8 card-glass card-glass-purple rounded-2xl px-4 py-3 w-48"
            animate={{ y: [0, -8, 0] }}
            transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
          >
            <div className="text-[0.6rem] text-off-white/30 font-outfit mb-1 uppercase tracking-widest">Zavara Studio</div>
            <div className="text-[0.75rem] text-purple font-outfit font-medium">AI descriptions ✓</div>
            <div className="text-[0.68rem] text-off-white/35 font-outfit">680 products synced</div>
          </motion.div>

          {/* Floating teal card */}
          <motion.div
            className="absolute -top-6 -right-6 card-glass card-glass-teal rounded-2xl px-4 py-3 w-44"
            animate={{ y: [0, -6, 0] }}
            transition={{ duration: 3.5, repeat: Infinity, ease: "easeInOut", delay: 1 }}
          >
            <div className="text-[0.6rem] text-off-white/30 font-outfit mb-1 uppercase tracking-widest">Halal Compass</div>
            <div className="text-[0.75rem] text-teal font-outfit font-medium">12 restaurants</div>
            <div className="text-[0.68rem] text-off-white/35 font-outfit">near you · live now</div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
};

export default HeroSection;
