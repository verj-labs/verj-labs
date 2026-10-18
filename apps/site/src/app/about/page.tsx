import Link from "next/link";
import { FadeUp, StaggerGrid, StaggerItem } from "@/components/motion";
import {
  TbCode, TbDeviceMobile, TbBrain, TbCloud,
  TbRocket, TbHeart, TbArrowRight,
} from "react-icons/tb";

const capabilities = [
  {
    icon: <TbCode size={26} />,
    title: "Full-Stack Web",
    desc: "React, Next.js, Node.js, NestJS — from design systems to API design. We build the whole stack.",
  },
  {
    icon: <TbDeviceMobile size={26} />,
    title: "Mobile Development",
    desc: "React Native for cross-platform iOS and Android. One codebase, native feel.",
  },
  {
    icon: <TbBrain size={26} />,
    title: "AI & Machine Learning",
    desc: "OpenAI, Claude, RAG pipelines, and custom model integration. AI that works in production.",
  },
  {
    icon: <TbCloud size={26} />,
    title: "Cloud & Infrastructure",
    desc: "AWS, Vercel, Docker, and CI/CD pipelines. Built to scale from day one.",
  },
];

export default function About() {
  return (
    <div className="min-h-screen">
      {/* Hero */}
      <section className="relative py-24 overflow-hidden px-6">
        <div className="mesh-orb-lime absolute w-96 h-96 -top-24 -left-24 pointer-events-none" aria-hidden="true" />
        <div className="mesh-orb-purple absolute w-80 h-80 top-0 right-0 pointer-events-none" aria-hidden="true" />

        <div className="max-w-4xl mx-auto text-center relative z-10">
          <FadeUp>
            <p className="eyebrow mb-4">Who we are</p>
            <h1 className="text-scale-1 font-bricolage text-off-white mb-5">
              About Verj Labs
            </h1>
            <p className="text-[1.05rem] text-off-white/45 leading-[1.75] max-w-[540px] mx-auto font-light">
              A senior-led digital studio that builds SaaS products and custom client solutions.
              We build lean, we build fast, we ship.
            </p>
          </FadeUp>
        </div>
      </section>

      {/* Studio + Philosophy */}
      <section className="pb-16">
        <div className="max-w-7xl mx-auto px-6">
          <StaggerGrid className="grid md:grid-cols-2 gap-5" staggerDelay={0.1}>
            <StaggerItem>
              <div className="card-dark h-full">
                <div className="p-3 bg-lime/10 rounded-xl w-fit mb-5">
                  <TbRocket size={26} className="text-lime" />
                </div>
                <h2 className="font-bricolage font-bold text-[1.3rem] text-off-white mb-4" style={{ letterSpacing: "-0.02em" }}>
                  What We Are
                </h2>
                <p className="text-[0.88rem] text-off-white/42 leading-[1.7] font-light">
                  Verj Labs is a senior-led studio that ships SaaS products and builds client solutions. We own
                  products — DealrDash, Zavara Studio, Halal Compass — and we take on client work that fits our
                  stack and standards. No generalist agencies, no junior-heavy teams.
                </p>
              </div>
            </StaggerItem>

            <StaggerItem>
              <div className="card-dark h-full">
                <div className="p-3 bg-teal/10 rounded-xl w-fit mb-5">
                  <TbHeart size={26} className="text-teal" />
                </div>
                <h2 className="font-bricolage font-bold text-[1.3rem] text-off-white mb-4" style={{ letterSpacing: "-0.02em" }}>
                  How We Work
                </h2>
                <p className="text-[0.88rem] text-off-white/42 leading-[1.7] font-light">
                  We build lean and we build fast — but never at the expense of quality. No bloat, no unnecessary
                  features, no six-week discovery phases. You get a scoped proposal, a real timeline, and a team
                  that ships.
                </p>
              </div>
            </StaggerItem>
          </StaggerGrid>
        </div>
      </section>

      {/* Team blurb */}
      <section className="pb-16">
        <div className="max-w-7xl mx-auto px-6">
          <FadeUp>
            <div className="card-dark">
              <div className="max-w-2xl">
                <p className="eyebrow mb-4">Our Team</p>
                <p className="text-[1.05rem] text-off-white/55 leading-[1.75] font-light">
                  A lean team of senior engineers and builders. No bloat, no juniors on critical work.
                  The people scoping your project are the same people building it. Experience across
                  product companies and enterprise software — shipped to real users, at scale.
                </p>
                <p className="text-[0.72rem] text-off-white/22 font-outfit mt-5">Verj Labs Inc. · Incorporated in Canada · Remote-first</p>
              </div>
            </div>
          </FadeUp>
        </div>
      </section>

      {/* Capabilities */}
      <section className="pb-16">
        <div className="max-w-7xl mx-auto px-6">
          <FadeUp className="mb-10">
            <p className="eyebrow mb-3">Capabilities</p>
            <h2 className="text-scale-2 font-bricolage text-off-white">The full stack.</h2>
          </FadeUp>

          <StaggerGrid className="grid sm:grid-cols-2 lg:grid-cols-4 gap-5" staggerDelay={0.09}>
            {capabilities.map((cap) => (
              <StaggerItem key={cap.title}>
                <div className="card-dark h-full text-center flex flex-col items-center">
                  <div className="p-4 bg-lime/10 rounded-2xl mb-4 text-lime">
                    {cap.icon}
                  </div>
                  <h3 className="font-bricolage font-bold text-[1rem] text-off-white mb-3" style={{ letterSpacing: "-0.01em" }}>
                    {cap.title}
                  </h3>
                  <p className="text-[0.8rem] text-off-white/38 leading-[1.65] font-light">{cap.desc}</p>
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
                Ready to work together?
              </h2>
              <p className="text-[0.9rem] text-bg/55 font-outfit">
                Tell us what you&apos;re building. We&apos;ll tell you if we&apos;re the right fit.
              </p>
            </div>
            <div className="flex gap-3 flex-wrap">
              <Link href="/contact" className="btn-lime-inv">
                Get in Touch &rarr;
              </Link>
              <Link href="/portfolio" className="bg-white/15 text-bg font-outfit font-semibold text-sm px-6 py-3.5 rounded-full hover:bg-white/25 transition-colors inline-flex items-center gap-2">
                See Our Work <TbArrowRight size={16} />
              </Link>
            </div>
          </div>
        </div>
      </FadeUp>
    </div>
  );
}
