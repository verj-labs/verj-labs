"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { FadeUp } from "@/components/motion";
import {
  TbLayoutDashboard, TbDiamond, TbCompass, TbWorld,
  TbUsers, TbSchool, TbArrowUpRight,
} from "react-icons/tb";

type Category = "All" | "SaaS Products" | "Client Work" | "Past Projects";

interface Project {
  name: string;
  url?: string;
  urlLabel?: string;
  category: Exclude<Category, "All">;
  tagline: string;
  story: string;
  stack: string[];
  glassVariant: string;
  badgeClass: string;
  badgeLabel: string;
  icon: React.ReactNode;
  shine: string;
}

const projects: Project[] = [
  {
    name: "DealrDash",
    url: "https://www.dealrdash.com",
    urlLabel: "dealrdash.com",
    category: "SaaS Products",
    tagline: "Multi-tenant DMS for car dealerships.",
    story: "B2B platform built for automotive dealerships to manage inventory, track leads, and generate sales reports — all under one roof. Multi-tenant architecture supports multiple dealership locations from a single dashboard.",
    stack: ["Next.js", "NestJS", "PostgreSQL", "TypeScript", "Vercel"],
    glassVariant: "card-glass card-glass-purple",
    badgeClass: "badge-purple",
    badgeLabel: "B2B SaaS",
    icon: <TbLayoutDashboard size={22} className="text-purple" />,
    shine: "bg-[radial-gradient(circle,rgba(140,90,255,0.08)_0%,transparent_70%)]",
  },
  {
    name: "Zavara Studio",
    url: "https://www.zavarastudio.com",
    urlLabel: "zavarastudio.com",
    category: "SaaS Products",
    tagline: "AI-first SaaS for jewelry businesses.",
    story: "Built for jewelers who need AI to handle repetitive work — generating product descriptions, drafting client communications, and keeping catalog data organized. AI-native from day one, not bolted on.",
    stack: ["Next.js", "OpenAI", "TypeScript", "Node.js", "Vercel"],
    glassVariant: "card-glass card-glass-lime",
    badgeClass: "badge-lime",
    badgeLabel: "B2B SaaS",
    icon: <TbDiamond size={22} className="text-lime" />,
    shine: "bg-[radial-gradient(circle,rgba(212,245,60,0.07)_0%,transparent_70%)]",
  },
  {
    name: "Halal Compass",
    url: "https://www.thehalalcompass.com",
    urlLabel: "thehalalcompass.com",
    category: "SaaS Products",
    tagline: "Consumer app for halal discovery.",
    story: "Location-based platform for discovering halal restaurants, grocery stores, mosques, and events. Built with a cross-platform mobile app (React Native) and a web dashboard backed by NestJS APIs.",
    stack: ["Next.js", "NestJS", "React Native", "PostgreSQL", "Maps"],
    glassVariant: "card-glass card-glass-teal",
    badgeClass: "badge-teal",
    badgeLabel: "Consumer App",
    icon: <TbCompass size={22} className="text-teal" />,
    shine: "bg-[radial-gradient(circle,rgba(29,210,160,0.08)_0%,transparent_70%)]",
  },
  {
    name: "SF Legacy Motors",
    url: "https://www.sflegacymotors.com",
    urlLabel: "sflegacymotors.com",
    category: "Client Work",
    tagline: "Custom web presence + CMS for an automotive dealership.",
    story: "Full website build for a car dealership client — custom inventory display, lead capture forms, and a Sanity CMS backend so the client can manage listings without touching code.",
    stack: ["Next.js", "Sanity CMS", "TypeScript", "Tailwind"],
    glassVariant: "card-glass",
    badgeClass: "badge-amber",
    badgeLabel: "Client Work",
    icon: <TbWorld size={22} className="text-amber" />,
    shine: "bg-[radial-gradient(circle,rgba(250,180,50,0.07)_0%,transparent_70%)]",
  },
  {
    name: "Zebaish",
    url: "https://www.zebaish.ca",
    urlLabel: "zebaish.ca",
    category: "Client Work",
    tagline: "Bespoke showcase site for a jewellery client.",
    story: "High-end showcase and e-commerce site for a jewellery business. Sanity CMS backend lets the client update collections independently. Custom design focused on product photography presentation.",
    stack: ["Next.js", "Sanity CMS", "TypeScript", "Tailwind"],
    glassVariant: "card-glass",
    badgeClass: "badge-amber",
    badgeLabel: "Client Work",
    icon: <TbDiamond size={22} className="text-amber" />,
    shine: "bg-[radial-gradient(circle,rgba(250,180,50,0.07)_0%,transparent_70%)]",
  },
  {
    name: "Trakart",
    category: "Past Projects",
    tagline: "LinkedIn for creatives — a portfolio social network.",
    story: "Startup project: a social platform where creatives could showcase work, follow peers, and get discovered by studios. Full AWS infrastructure, React frontend, and a custom matching algorithm for creator discovery.",
    stack: ["React", "AWS", "Node.js", "DynamoDB"],
    glassVariant: "card-glass",
    badgeClass: "badge-purple",
    badgeLabel: "Past Project",
    icon: <TbUsers size={22} className="text-purple" />,
    shine: "bg-[radial-gradient(circle,rgba(140,90,255,0.06)_0%,transparent_70%)]",
  },
  {
    name: "Virtual TA",
    category: "Past Projects",
    tagline: "AI teaching assistant with RAG for university courses.",
    story: "AI-powered teaching assistant that answered student questions by retrieving context from course materials using RAG. Reduced TA workload and gave students instant, accurate answers grounded in actual course content.",
    stack: ["Next.js", "OpenAI", "RAG", "Python", "PostgreSQL"],
    glassVariant: "card-glass",
    badgeClass: "badge-teal",
    badgeLabel: "Past Project",
    icon: <TbSchool size={22} className="text-teal" />,
    shine: "bg-[radial-gradient(circle,rgba(29,210,160,0.06)_0%,transparent_70%)]",
  },
];

const categories: Category[] = ["All", "SaaS Products", "Client Work", "Past Projects"];

export default function Portfolio() {
  const [active, setActive] = useState<Category>("All");

  const filtered = active === "All" ? projects : projects.filter((p) => p.category === active);

  return (
    <div className="min-h-screen">
      {/* Hero */}
      <section className="relative py-24 overflow-hidden px-6">
        <div className="mesh-orb-lime absolute w-96 h-96 -top-24 -left-24 pointer-events-none" aria-hidden="true" />
        <div className="mesh-orb-purple absolute w-80 h-80 top-10 right-0 pointer-events-none" aria-hidden="true" />

        <div className="max-w-4xl mx-auto text-center relative z-10">
          <FadeUp>
            <p className="eyebrow mb-4">Real work. Real results.</p>
            <h1 className="text-scale-1 font-bricolage text-off-white mb-5">Our Work</h1>
            <p className="text-[1.05rem] text-off-white/45 leading-[1.75] max-w-[500px] mx-auto font-light">
              SaaS products we own, client builds we shipped, and past projects that shaped how we build.
            </p>
          </FadeUp>
        </div>
      </section>

      {/* Filter tabs */}
      <section className="pb-4">
        <div className="max-w-7xl mx-auto px-6">
          <FadeUp>
            <div className="flex flex-wrap gap-2 mb-10">
              {categories.map((cat) => (
                <button
                  key={cat}
                  onClick={() => setActive(cat)}
                  className={`px-4 py-2 rounded-full text-[0.78rem] font-outfit font-medium transition-all duration-200 ${
                    active === cat
                      ? "bg-lime text-bg"
                      : "bg-surface text-off-white/40 border border-white/07 hover:border-white/20 hover:text-off-white/70"
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>
          </FadeUp>

          {/* Grid */}
          <motion.div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5" layout>
            <AnimatePresence mode="popLayout">
              {filtered.map((p) => (
                <motion.div
                  key={p.name}
                  layout
                  initial={{ opacity: 0, scale: 0.96, y: 12 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.94, y: -8 }}
                  transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
                >
                  <div className={`${p.glassVariant} h-full flex flex-col`}>
                    {/* shine */}
                    <div className={`absolute -top-10 -right-10 w-32 h-32 rounded-full pointer-events-none ${p.shine}`} />

                    {/* Header */}
                    <div className="flex items-center gap-3 mb-4">
                      <div className="p-2 bg-white/[0.04] rounded-xl border border-white/[0.06]">
                        {p.icon}
                      </div>
                      <span className={p.badgeClass}>{p.badgeLabel}</span>
                    </div>

                    <h3 className="font-bricolage font-extrabold text-[1.25rem] text-off-white mb-1" style={{ letterSpacing: "-0.02em" }}>
                      {p.name}
                    </h3>
                    <p className="text-[0.78rem] text-lime/60 font-outfit font-medium mb-3">{p.tagline}</p>
                    <p className="text-[0.82rem] text-off-white/38 leading-[1.65] font-light flex-1 mb-4">{p.story}</p>

                    <div className="flex flex-wrap gap-1.5 mb-4">
                      {p.stack.map((t) => (
                        <span key={t} className="tech-pill">{t}</span>
                      ))}
                    </div>

                    {p.url ? (
                      <a
                        href={p.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-[0.78rem] text-lime/65 font-outfit font-medium hover:text-lime transition-colors mt-auto"
                      >
                        {p.urlLabel} <TbArrowUpRight size={13} />
                      </a>
                    ) : (
                      <span className="text-[0.72rem] text-off-white/25 font-outfit mt-auto">Past Project</span>
                    )}
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
          </motion.div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <FadeUp>
            <div className="card-dark">
              <h2 className="font-bricolage font-extrabold text-[1.8rem] text-off-white mb-3" style={{ letterSpacing: "-0.03em" }}>
                Want to see what we can build for you?
              </h2>
              <p className="text-[0.88rem] text-off-white/38 mb-6 font-light">Let&apos;s talk about your project.</p>
              <a href="/contact" className="btn-primary">
                Start a Conversation
              </a>
            </div>
          </FadeUp>
        </div>
      </section>
    </div>
  );
}
