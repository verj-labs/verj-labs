import Link from "next/link";
import { FadeUp, StaggerGrid, StaggerItem } from "@/components/motion";
import {
  TbCompass, TbLayoutDashboard, TbDiamond,
  TbMapPin, TbStar, TbUsers, TbBell,
  TbArrowUpRight, TbArrowRight,
} from "react-icons/tb";

const products = [
  {
    name: "DealrDash",
    url: "https://www.dealrdash.com",
    urlLabel: "dealrdash.com",
    tagline: "Dealer management software, built for scale.",
    desc: "Multi-tenant DMS for car dealerships. A B2B platform covering inventory management, lead tracking, and sales reporting — all under one roof, accessible from anywhere.",
    features: [
      { icon: <TbLayoutDashboard size={15} className="text-purple" />, label: "Multi-tenant inventory management" },
      { icon: <TbUsers size={15} className="text-purple" />, label: "Lead tracking and CRM" },
      { icon: <TbStar size={15} className="text-purple" />, label: "Sales reporting and analytics" },
      { icon: <TbBell size={15} className="text-purple" />, label: "Multi-location support" },
    ],
    stack: ["Next.js", "NestJS", "PostgreSQL", "TypeScript"],
    glassVariant: "card-glass card-glass-purple",
    iconColor: "text-purple",
    iconBg: "bg-purple/10",
    accentIcon: <TbLayoutDashboard size={32} />,
    badge: "badge-purple",
    badgeLabel: "B2B SaaS",
  },
  {
    name: "Zavara Studio",
    url: "https://www.zavarastudio.com",
    urlLabel: "zavarastudio.com",
    tagline: "AI-powered tools for jewelry businesses.",
    desc: "AI-first SaaS built for jewelers who are tired of writing product descriptions and managing catalog data manually. Zavara handles it — AI-generated copy, automated client comms, and catalog sync.",
    features: [
      { icon: <TbStar size={15} className="text-lime" />, label: "AI product description generation" },
      { icon: <TbDiamond size={15} className="text-lime" />, label: "Jewelry catalog management" },
      { icon: <TbUsers size={15} className="text-lime" />, label: "Automated client communications" },
      { icon: <TbBell size={15} className="text-lime" />, label: "AI-native from the ground up" },
    ],
    stack: ["Next.js", "AI/ML", "TypeScript", "Node.js"],
    glassVariant: "card-glass card-glass-lime",
    iconColor: "text-lime",
    iconBg: "bg-lime/10",
    accentIcon: <TbDiamond size={32} />,
    badge: "badge-lime",
    badgeLabel: "B2B SaaS",
  },
  {
    name: "The Halal Compass",
    url: "https://www.thehalalcompass.com",
    urlLabel: "thehalalcompass.com",
    tagline: "Find everything halal — near you.",
    desc: "A one-stop consumer platform for the Muslim community. Discover halal restaurants, grocery stores, mosques, events, and gift shops through interactive maps, curated listings, and community-driven reviews.",
    features: [
      { icon: <TbMapPin size={15} className="text-teal" />, label: "Location-based discovery with maps" },
      { icon: <TbStar size={15} className="text-teal" />, label: "Curated listings and community reviews" },
      { icon: <TbUsers size={15} className="text-teal" />, label: "Community-driven recommendations" },
      { icon: <TbBell size={15} className="text-teal" />, label: "Event notifications and updates" },
    ],
    stack: ["Next.js", "NestJS", "React Native", "PostgreSQL"],
    glassVariant: "card-glass card-glass-teal",
    iconColor: "text-teal",
    iconBg: "bg-teal/10",
    accentIcon: <TbCompass size={32} />,
    badge: "badge-teal",
    badgeLabel: "Consumer App",
  },
];

export default function Products() {
  return (
    <div className="min-h-screen">
      {/* Hero */}
      <section className="relative py-24 overflow-hidden px-6">
        <div className="mesh-orb-lime absolute w-96 h-96 -top-24 -left-24 pointer-events-none" aria-hidden="true" />
        <div className="mesh-orb-teal absolute w-80 h-80 top-10 right-0 pointer-events-none" aria-hidden="true" />

        <div className="max-w-4xl mx-auto text-center relative z-10">
          <FadeUp>
            <p className="eyebrow mb-4">Built by Verj Labs</p>
            <h1 className="text-scale-1 font-bricolage text-off-white mb-5">Our Products</h1>
            <p className="text-[1.05rem] text-off-white/45 leading-[1.75] max-w-[500px] mx-auto font-light">
              We don&apos;t just build for clients — we build for the world. Three live products, solving real problems.
            </p>
          </FadeUp>
        </div>
      </section>

      {/* Products */}
      <section className="pb-16">
        <div className="max-w-7xl mx-auto px-6">
          <StaggerGrid className="grid gap-6" staggerDelay={0.12}>
            {products.map((p) => (
              <StaggerItem key={p.name}>
                <div className={`${p.glassVariant} grid lg:grid-cols-2 gap-10 items-center`}>
                  {/* Info */}
                  <div>
                    <span className={`${p.badge} mb-4 inline-flex`}>{p.badgeLabel}</span>

                    <div className="flex items-center gap-3 mb-4">
                      <div className={`p-2.5 rounded-xl ${p.iconBg} ${p.iconColor}`}>
                        {p.accentIcon}
                      </div>
                      <div>
                        <h2 className="font-bricolage font-extrabold text-[1.5rem] text-off-white" style={{ letterSpacing: "-0.025em" }}>
                          {p.name}
                        </h2>
                        <p className="text-[0.78rem] text-off-white/40 font-outfit">{p.tagline}</p>
                      </div>
                    </div>

                    <p className="text-[0.9rem] text-off-white/45 leading-[1.7] mb-6 font-light">{p.desc}</p>

                    <ul className="space-y-2.5 mb-6">
                      {p.features.map((f) => (
                        <li key={f.label} className="flex items-center gap-2.5">
                          {f.icon}
                          <span className="text-[0.82rem] text-off-white/55 font-light">{f.label}</span>
                        </li>
                      ))}
                    </ul>

                    <div className="flex flex-wrap gap-2 mb-6">
                      {p.stack.map((t) => (
                        <span key={t} className="tech-pill">{t}</span>
                      ))}
                    </div>

                    <a
                      href={p.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="btn-primary inline-flex items-center gap-2 text-sm"
                    >
                      Visit {p.name} <TbArrowUpRight size={16} />
                    </a>
                  </div>

                  {/* Visual preview */}
                  <div className="bg-[#07070C]/80 rounded-2xl p-5 border border-white/[0.06]">
                    <div className="flex items-center justify-between mb-4">
                      <div className="flex items-center gap-2">
                        <div className={`${p.iconColor} opacity-80`}>{p.accentIcon}</div>
                        <span className="text-[0.72rem] text-off-white/50 font-outfit font-medium">{p.name}</span>
                      </div>
                      <div className="w-1.5 h-1.5 rounded-full bg-lime animate-pulse-slow" />
                    </div>
                    <div className="space-y-2">
                      {p.features.map((f, i) => (
                        <div key={i} className="flex items-center justify-between p-2.5 rounded-xl bg-white/[0.03] border border-white/[0.04]">
                          <div className="flex items-center gap-2">
                            {f.icon}
                            <span className="text-[0.75rem] text-off-white/50 font-outfit">{f.label}</span>
                          </div>
                          <div className="w-1 h-1 rounded-full bg-lime/40" />
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </StaggerItem>
            ))}
          </StaggerGrid>
        </div>
      </section>

      {/* Client work note */}
      <section className="pb-16">
        <div className="max-w-7xl mx-auto px-6">
          <FadeUp>
            <div className="card-dark flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div>
                <h3 className="font-bricolage font-bold text-[1.1rem] text-off-white mb-1" style={{ letterSpacing: "-0.015em" }}>
                  Looking for client work?
                </h3>
                <p className="text-[0.82rem] text-off-white/38 font-light">
                  The above are products Verj Labs owns. For client websites and custom builds, visit the portfolio.
                </p>
              </div>
              <Link href="/portfolio" className="btn-secondary flex-shrink-0 inline-flex items-center gap-2 text-sm">
                View Portfolio <TbArrowRight size={15} />
              </Link>
            </div>
          </FadeUp>
        </div>
      </section>
    </div>
  );
}
