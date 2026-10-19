import Link from "next/link";
import PixelCanvas from "@/components/home/PixelCanvas";
import PixelStrip from "@/components/home/PixelStrip";
import ScrollStage from "@/components/home/ScrollStage";
import Reveal from "@/components/home/Reveal";
import Work from "@/components/home/Work";
import Process from "@/components/home/Process";
import Wizard from "@/components/home/Wizard";
import SecHead from "@/components/site/SecHead";
import PixelIcon from "@/components/site/PixelIcon";
import { SERVICES } from "@/lib/services";
import { NEEDS, CAL_URL, timeLabel } from "@/lib/site";

const FAQ = [
  {
    q: "How long does a project take?",
    a: "It depends on what you are building. A website usually takes 4 to 8 weeks, AI work 2 to 6, a mobile app 6 to 14 and a full product 6 to 16. We confirm the timeline when we plan the work with you.",
  },
  {
    q: "Do you work to a fixed scope?",
    a: "Website projects are fixed scope and fixed timeline, so you know what you are getting before work starts.",
  },
  {
    q: "Who will I work with?",
    a: "Verj Labs is a senior-led studio. We plan the work together first, so you know who does what before we start.",
  },
  {
    q: "Can you add AI to something we already have?",
    a: "Yes. We add AI to existing apps and tools, or build something new around it.",
  },
  {
    q: "What happens after launch?",
    a: "We keep improving it after release, and hand everything over with documentation when you want to run it yourselves.",
  },
  {
    q: "Where are you based?",
    a: "Verj Labs Inc. is a Canadian company.",
  },
];

export default function Home() {
  const ai = SERVICES[0];
  const rest = SERVICES.slice(1);
  return (
    <>
      <section className="vh-first" aria-labelledby="vh-h1">
        <PixelCanvas start={0.52} className="vh-first-bg" />
        <div className="vh-xhair vh-xhair-tl" aria-hidden="true" />
        <div className="vh-xhair vh-xhair-tr" aria-hidden="true" />

        <div className="vh-hero">
          <div className="vh-hero-meta vh-mono">
            <span>Verj Labs Inc.</span>
            <span>Software studio</span>
            <span>Canada</span>
          </div>

          <h1 id="vh-h1" className="vh-display">
            <span className="vh-line">
              <span className="vh-line-in" style={{ "--i": 0 } as React.CSSProperties}>
                We ship
              </span>
            </span>
            <span className="vh-line">
              <span className="vh-line-in" style={{ "--i": 1 } as React.CSSProperties}>
                real software
              </span>
            </span>
          </h1>

          <div className="vh-hero-cell">
            <p>We design, build and launch products, websites, mobile apps and AI for businesses, from first idea to launch.</p>
            <div className="vh-hero-actions">
              <a href="#start" className="vh-btn">
                Start a project
              </a>
              <a href={CAL_URL} target="_blank" rel="noopener noreferrer" className="vh-btn vh-btn-ghost">
                Book a call
              </a>
            </div>
          </div>
        </div>

        <p className="vh-first-foot vh-mono">Scroll</p>
        <PixelStrip className="vh-strip vh-strip-first" />
      </section>

      <ScrollStage>
        <div className="vh-stage-card">
          <p className="vh-mono">Verj Labs Inc. / Canada</p>
          <p className="vh-stage-num">25+</p>
          <p className="vh-mono">Projects delivered</p>
          <p className="vh-stage-text">
            We design, build and launch software for businesses: products, websites, mobile apps and AI. One team, from
            first idea to launch.
          </p>
          <a href="#work" className="vh-btn">
            See our work
          </a>
        </div>
      </ScrollStage>

      <section id="work" className="vh-sec" aria-label="Our work">
        <SecHead no="01" title="Our work" note="A few of 25+ projects" />
        <Reveal>
          <p className="vh-lead">A few recent projects, and how we built them.</p>
          <Work />
          <div className="vh-more">
            <Link href="/work" className="vh-btn">
              See all case studies
            </Link>
          </div>
        </Reveal>
      </section>

      <section id="services" className="vh-sec" aria-label="What we build">
        <SecHead no="02" title="What we build" note="Seven things" />
        <PixelStrip className="vh-strip" />
        <div className="vh-svc-grid">
          <Reveal className="vh-svc vh-svc-ai">
            <div className="vh-svc-top">
              <span className="vh-mono">{ai.code} / Featured</span>
              <PixelIcon rows={NEEDS[0].icon} />
            </div>
            <h3>{ai.title}</h3>
            <p className="vh-svc-lead">{ai.lead}</p>
            <ul className="vh-svc-examples">
              {ai.examples!.map((e) => (
                <li key={e}>{e}</li>
              ))}
            </ul>
            <p className="vh-mono vh-svc-time">{timeLabel(ai.time)}</p>
            <Link href="/services#ai" className="vh-btn vh-btn-ink">
              Explore AI
            </Link>
          </Reveal>
          {rest.map((s, i) => (
            <Reveal key={s.id} delay={(i + 1) * 70} className="vh-svc">
              <div className="vh-svc-top">
                <span className="vh-mono">{s.code}</span>
                <PixelIcon rows={NEEDS.find((n) => n.id === s.id)!.icon} />
              </div>
              <h3>{s.title}</h3>
              <p>{s.lead}</p>
              <p className="vh-mono vh-svc-time">{timeLabel(s.time)}</p>
              <Link href={`/services#${s.id}`} className="vh-link vh-svc-link">
                Learn more
              </Link>
            </Reveal>
          ))}
        </div>
      </section>

      <section id="process" className="vh-sec" aria-label="How it works">
        <SecHead no="03" title="How it works" note="Four steps" />
        <Process />
      </section>

      <section className="vh-sec vh-faq" aria-label="Questions">
        <SecHead no="04" title="Straight answers" note="Six questions" />
        <div className="vh-faq-list">
          {FAQ.map((f, i) => (
            <Reveal key={f.q} delay={i * 50}>
              <details>
                <summary>
                  <span className="vh-mono">Q.{String(i + 1).padStart(2, "0")}</span>
                  <span className="vh-faq-q">{f.q}</span>
                  <span className="vh-chev" aria-hidden="true" />
                </summary>
                <p>{f.a}</p>
              </details>
            </Reveal>
          ))}
        </div>
      </section>

      <section id="start" className="vh-sec vh-cta" aria-label="Start a project">
        <SecHead no="05" title="Start a project" note="Takes about a minute" />
        <PixelStrip className="vh-strip" />
        <div className="vh-cta-body">
          <Wizard />
        </div>
      </section>
    </>
  );
}
