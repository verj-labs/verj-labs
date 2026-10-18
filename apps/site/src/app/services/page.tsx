import Link from "next/link";
import { FadeUp, StaggerGrid, StaggerItem } from "@/components/motion";
import {
  TbRocket, TbCode, TbBrain, TbDeviceMobile,
  TbCheck, TbClock, TbArrowRight,
} from "react-icons/tb";

const services = [
  {
    icon: <TbRocket size={28} />,
    iconColor: "text-lime",
    iconBg: "bg-lime/10",
    label: "Product Development",
    headline: "Idea → MVP → full product.",
    desc: "You have a problem worth solving. We take it from architecture and design to a shipped, deployed product — no hand-holding required.",
    includes: [
      "Product architecture and technical planning",
      "Full-stack development (React, Next.js, NestJS)",
      "Cloud deployment and CI/CD setup",
      "Mobile-first responsive design",
      "Ongoing iterations post-launch",
    ],
    timeline: "6–16 weeks",
  },
  {
    icon: <TbCode size={28} />,
    iconColor: "text-purple",
    iconBg: "bg-purple/10",
    label: "Client Builds",
    headline: "Custom sites, platforms & tools.",
    desc: "Fixed scope, fixed timeline, no surprises. We build custom websites, CMS-backed platforms, and internal tools — and hand them off properly.",
    includes: [
      "Custom web design and development",
      "CMS integration (Sanity, headless)",
      "E-commerce and lead capture",
      "Internal dashboards and admin tools",
      "Full handoff with documentation",
    ],
    timeline: "4–8 weeks",
  },
  {
    icon: <TbBrain size={28} />,
    iconColor: "text-teal",
    iconBg: "bg-teal/10",
    label: "AI Integration",
    headline: "Add AI where it actually helps.",
    desc: "RAG pipelines, LLM APIs, and intelligent automation — implemented properly, not bolted on. We integrate AI into existing products or build AI-first from scratch.",
    includes: [
      "Model selection and prompt engineering",
      "RAG pipeline design and implementation",
      "OpenAI, Claude, and custom model APIs",
      "AI feature integration into existing apps",
      "Evaluation and quality benchmarking",
    ],
    timeline: "2–6 weeks",
  },
  {
    icon: <TbDeviceMobile size={28} />,
    iconColor: "text-amber",
    iconBg: "bg-amber/10",
    label: "Mobile Apps",
    headline: "React Native — iOS & Android.",
    desc: "Cross-platform mobile apps that feel native. One codebase, full feature parity, deployed to both stores. We've done it for our own products — we can do it for yours.",
    includes: [
      "React Native cross-platform development",
      "App Store and Google Play deployment",
      "Deep linking and push notifications",
      "Maps, location services, and sensors",
      "Backend API design and integration",
    ],
    timeline: "6–14 weeks",
  },
];

export default function Services() {
  return (
    <div className="min-h-screen">
      {/* Hero */}
      <section className="relative py-24 overflow-hidden px-6">
        {/* mesh */}
        <div className="mesh-orb-lime absolute w-96 h-96 -top-24 -left-24 pointer-events-none" aria-hidden="true" />
        <div className="mesh-orb-purple absolute w-80 h-80 top-10 right-0 pointer-events-none" aria-hidden="true" />

        <div className="max-w-4xl mx-auto text-center relative z-10">
          <FadeUp>
            <p className="eyebrow mb-4">What we do</p>
            <h1 className="text-scale-1 font-bricolage text-off-white mb-5">
              Services
            </h1>
            <p className="text-[1.05rem] text-off-white/45 leading-[1.75] max-w-[520px] mx-auto font-light">
              Senior engineering, end-to-end. Three focused offerings — no generalist agencies, no junior-heavy teams.
            </p>
          </FadeUp>
        </div>
      </section>

      {/* Services bento */}
      <section className="pb-24">
        <div className="max-w-7xl mx-auto px-6">
          <StaggerGrid className="grid md:grid-cols-2 gap-5" staggerDelay={0.1}>
            {services.map((svc) => (
              <StaggerItem key={svc.label}>
                <div className="card-dark h-full flex flex-col gap-6">
                  {/* Icon + label */}
                  <div className="flex items-start gap-4">
                    <div className={`p-3 rounded-xl ${svc.iconBg} ${svc.iconColor} flex-shrink-0`}>
                      {svc.icon}
                    </div>
                    <div>
                      <div className="text-[0.65rem] text-off-white/30 font-outfit uppercase tracking-widest mb-1">{svc.label}</div>
                      <h2 className="font-bricolage font-bold text-[1.25rem] text-off-white" style={{ letterSpacing: "-0.02em" }}>
                        {svc.headline}
                      </h2>
                    </div>
                  </div>

                  <p className="text-[0.88rem] text-off-white/40 leading-[1.7] font-light">{svc.desc}</p>

                  {/* Includes */}
                  <div>
                    <div className="text-[0.6rem] text-off-white/25 font-outfit uppercase tracking-[0.12em] mb-3">Includes</div>
                    <ul className="space-y-2.5">
                      {svc.includes.map((item) => (
                        <li key={item} className="flex items-start gap-2.5">
                          <TbCheck size={14} className="text-lime mt-0.5 flex-shrink-0" />
                          <span className="text-[0.82rem] text-off-white/60 font-light">{item}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  {/* Timeline */}
                  <div className="flex items-center gap-2 mt-auto pt-4 border-t border-white/[0.06]">
                    <TbClock size={14} className="text-off-white/30" />
                    <span className="text-[0.75rem] text-off-white/30 font-outfit">Typically {svc.timeline}</span>
                  </div>
                </div>
              </StaggerItem>
            ))}
          </StaggerGrid>
        </div>
      </section>

      {/* CTA */}
      <FadeUp>
        <div className="max-w-7xl mx-auto px-6 pb-24">
          <div className="cta-band">
            <div>
              <h2 className="font-bricolage font-extrabold text-[clamp(1.6rem,3.5vw,2.4rem)] text-bg mb-1.5" style={{ letterSpacing: "-0.03em" }}>
                Not sure which fits?
              </h2>
              <p className="text-[0.9rem] text-bg/55 font-outfit">
                Tell us what you&apos;re building. We&apos;ll figure out the right approach.
              </p>
            </div>
            <div className="flex gap-3 flex-wrap">
              <Link href="/contact" className="btn-lime-inv">
                Book a Discovery Call &rarr;
              </Link>
              <Link href="/portfolio" className="bg-white/15 text-bg font-outfit font-semibold text-sm px-6 py-3.5 rounded-full hover:bg-white/25 transition-colors inline-flex items-center gap-2">
                View Our Work <TbArrowRight size={16} />
              </Link>
            </div>
          </div>
        </div>
      </FadeUp>
    </div>
  );
}
