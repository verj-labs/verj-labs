import HeroSection from "@/components/landing/HeroSection";
import Link from "next/link";
import { FadeUp, StaggerGrid, StaggerItem } from "@/components/motion";
import {
  TbRocket, TbCode, TbBrain, TbDeviceMobile,
  TbArrowUpRight, TbArrowRight,
} from "react-icons/tb";

const techStack = [
  "React", "Next.js", "TypeScript", "Node.js", "NestJS",
  "PostgreSQL", "AWS", "React Native", "Python", "OpenAI",
  "Tailwind CSS", "Docker", "Vercel", "Prisma", "DynamoDB",
  "GraphQL", "Redis", "Stripe", "Supabase", "Expo",
  "Claude AI", "LangChain", "Terraform", "GitHub Actions", "tRPC",
];

const workCards = [
  {
    variant: "card-glass card-glass-purple",
    badge: "badge-purple",
    badgeLabel: "B2B SaaS",
    name: "DealrDash",
    desc: "Multi-tenant Dealer Management System for car dealerships across Canada and the US. Complex B2B workflows, multi-location support, real-time inventory.",
    chips: ["Next.js", "Vercel", "Multi-tenant", "B2B"],
    url: "https://www.dealrdash.com",
    urlLabel: "dealrdash.com",
    shine: "bg-[radial-gradient(circle,rgba(140,90,255,0.08)_0%,transparent_70%)]",
  },
  {
    variant: "card-glass card-glass-lime",
    badge: "badge-lime",
    badgeLabel: "B2B SaaS",
    name: "Zavara Studio",
    desc: "AI-first platform for jewelers — project management, client workflows, and AI-powered content generation. Built for the jewellery trade.",
    chips: ["Next.js", "AI Models", "Vercel", "OpenAI"],
    url: "https://www.zavarastudio.com",
    urlLabel: "zavarastudio.com",
    shine: "bg-[radial-gradient(circle,rgba(212,245,60,0.07)_0%,transparent_70%)]",
  },
  {
    variant: "card-glass card-glass-teal",
    badge: "badge-teal",
    badgeLabel: "Consumer App",
    name: "Halal Compass",
    desc: "Full-ecosystem consumer platform for discovering halal restaurants and businesses. Web, mobile, and internal tooling — all in one build.",
    chips: ["NestJS", "Next.js", "React Native", "Maps"],
    url: "https://www.thehalalcompass.com",
    urlLabel: "thehalalcompass.com",
    shine: "bg-[radial-gradient(circle,rgba(29,210,160,0.08)_0%,transparent_70%)]",
  },
  {
    variant: "card-glass card-glass-amber",
    badge: "badge-amber",
    badgeLabel: "Client Work",
    name: "Industry Sites",
    desc: "Custom CMS-backed websites for automotive and jewellery sector clients. Fast, SEO-optimised, and easy for clients to manage themselves.",
    chips: ["Next.js", "Sanity CMS", "Custom Design"],
    url: null,
    urlLabel: null,
    shine: "bg-[radial-gradient(circle,rgba(250,180,50,0.07)_0%,transparent_70%)]",
  },
];

const services = [
  { icon: <TbRocket size={22} className="text-lime" />, name: "Product Development", desc: "Idea to live SaaS. Architecture, design, build, and launch — fully owned." },
  { icon: <TbCode size={22} className="text-lime" />, name: "Client Builds", desc: "Websites, CMS platforms, and internal tools. Fixed scope, clear timelines." },
  { icon: <TbBrain size={22} className="text-lime" />, name: "AI Integration", desc: "RAG pipelines, content generation, smart automation — actually shipping." },
  { icon: <TbDeviceMobile size={22} className="text-lime" />, name: "Mobile Apps", desc: "React Native for iOS and Android. Cross-platform, performant, production-ready." },
];

export default function Home() {
  return (
    <div className="min-h-screen">
      <HeroSection />

      {/* Stack strip — marquee */}
      <div className="stack-strip overflow-hidden">
        <span className="stack-lbl flex-shrink-0">Stack</span>
        <div className="flex-1 overflow-hidden relative">
          <div className="flex items-center gap-2 animate-marquee whitespace-nowrap w-max">
            {[...techStack, ...techStack].map((t, i) => (
              <span key={`${t}-${i}`} className="tech-pill">{t}</span>
            ))}
          </div>
        </div>
      </div>

      {/* Work section */}
      <section className="spacing-section">
        <div className="max-w-7xl mx-auto px-6">
          <FadeUp>
            <p className="eyebrow mb-3">What we&apos;ve shipped</p>
            <h2 className="text-scale-2 font-bricolage text-off-white mb-3">Products &amp; Client Work</h2>
            <p className="text-[0.9rem] text-off-white/40 max-w-[480px] leading-relaxed mb-10 font-light">
              Not mock-ups. Not prototypes. Real products with real users, shipped and running in production.
            </p>
          </FadeUp>

          <StaggerGrid className="grid md:grid-cols-2 gap-5" staggerDelay={0.09}>
            {workCards.map((card) => (
              <StaggerItem key={card.name}>
                <div className={`${card.variant} h-full flex flex-col`}>
                  {/* shine orb */}
                  <div className={`absolute -top-14 -right-14 w-40 h-40 rounded-full pointer-events-none ${card.shine}`} />
                  <span className={card.badge} style={{ fontSize: "0.62rem" }}>{card.badgeLabel}</span>
                  <div className="mt-5 font-bricolage font-extrabold text-[1.3rem] text-off-white mb-2" style={{ letterSpacing: "-0.02em" }}>
                    {card.name}
                  </div>
                  <p className="text-[0.82rem] text-off-white/42 leading-[1.65] mb-5 font-light flex-1">{card.desc}</p>
                  <div className="flex flex-wrap gap-1.5 mb-5">
                    {card.chips.map((c) => (
                      <span key={c} className="tech-pill">{c}</span>
                    ))}
                  </div>
                  {card.url ? (
                    <a
                      href={card.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1 text-[0.78rem] text-lime/70 font-outfit font-medium hover:text-lime transition-colors"
                    >
                      {card.urlLabel} <TbArrowUpRight size={13} />
                    </a>
                  ) : (
                    <Link href="/portfolio" className="inline-flex items-center gap-1 text-[0.78rem] text-off-white/30 font-outfit hover:text-off-white/60 transition-colors">
                      View in portfolio <TbArrowUpRight size={13} />
                    </Link>
                  )}
                </div>
              </StaggerItem>
            ))}
          </StaggerGrid>
        </div>
      </section>

      {/* Services preview */}
      <section className="spacing-section border-t border-white/05">
        <div className="max-w-7xl mx-auto px-6">
          <FadeUp>
            <p className="eyebrow mb-3">What we do</p>
            <h2 className="text-scale-2 font-bricolage text-off-white mb-3">Services</h2>
            <p className="text-[0.9rem] text-off-white/40 max-w-[480px] leading-relaxed mb-10 font-light">
              Senior engineering, end-to-end. We don&apos;t hand things off — we own them.
            </p>
          </FadeUp>

          <FadeUp delay={0.1}>
            <div className="services-grid">
              {services.map((s) => (
                <div key={s.name} className="services-grid-item">
                  <div className="mb-4 opacity-85">{s.icon}</div>
                  <div className="font-bricolage font-bold text-[1rem] text-off-white mb-1.5" style={{ letterSpacing: "-0.01em" }}>
                    {s.name}
                  </div>
                  <p className="text-[0.78rem] text-off-white/38 leading-[1.6] font-light">{s.desc}</p>
                </div>
              ))}
            </div>
          </FadeUp>

          <FadeUp delay={0.15} className="mt-8">
            <Link href="/services" className="btn-secondary inline-flex items-center gap-2">
              <span>All Services</span>
              <TbArrowRight size={16} />
            </Link>
          </FadeUp>
        </div>
      </section>

      {/* CTA band */}
      <FadeUp>
        <div className="max-w-7xl mx-auto px-6 pb-24">
          <div className="cta-band">
            <div>
              <h2 className="font-bricolage font-extrabold text-[clamp(1.6rem,3.5vw,2.4rem)] text-bg mb-1.5" style={{ letterSpacing: "-0.03em" }}>
                Got an idea? Let&apos;s build it.
              </h2>
              <p className="text-[0.9rem] text-bg/55 font-outfit">
                Discovery call &rarr; Proposal &rarr; Build &rarr; Launch
              </p>
            </div>
            <Link href="mailto:hello@verjlabs.com" className="btn-lime-inv whitespace-nowrap">
              hello@verjlabs.com &rarr;
            </Link>
          </div>
        </div>
      </FadeUp>
    </div>
  );
}
