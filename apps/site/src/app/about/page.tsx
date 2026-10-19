import type { Metadata } from "next";
import Link from "next/link";
import PageHead from "@/components/site/PageHead";
import Reveal from "@/components/home/Reveal";
import SecHead from "@/components/site/SecHead";
import { CAL_URL } from "@/lib/site";

export const metadata: Metadata = {
  title: "About",
  description: "Verj Labs is a senior-led Canadian software studio.",
};

const PRINCIPLES = [
  {
    code: "P-01",
    title: "Real software, shipped",
    text: "We measure ourselves by what goes live. We build products and see them through to launch and beyond.",
  },
  {
    code: "P-02",
    title: "Plain language",
    text: "You should always know what we are doing and why. We explain things simply and show you progress as we go.",
  },
  {
    code: "P-03",
    title: "Clear scope, clear timeline",
    text: "We agree what we are building and how long it takes before work starts, so there are no surprises later.",
  },
];

export default function About() {
  return (
    <>
      <PageHead
        code="About"
        title="A studio that ships"
        lead="Verj Labs is a senior-led software studio based in Canada. We design, build and launch products, websites, mobile apps and AI for businesses."
      />
      <section className="vh-sec" aria-label="Principles">
        <SecHead no="01" title="How we work" note="Three principles" />
        <div className="vh-svc-grid vh-grid-3">
          {PRINCIPLES.map((p, i) => (
            <Reveal key={p.code} delay={i * 70} className="vh-svc">
              <span className="vh-mono">{p.code}</span>
              <h3>{p.title}</h3>
              <p>{p.text}</p>
            </Reveal>
          ))}
        </div>
      </section>
      <section className="vh-sec" aria-label="Verj Labs">
        <SecHead no="02" title="The studio" note="Verj Labs Inc." />
        <dl className="vh-facts">
          <div>
            <dt className="vh-mono">Projects delivered</dt>
            <dd>25+</dd>
          </div>
          <div>
            <dt className="vh-mono">Based in</dt>
            <dd>Canada</dd>
          </div>
          <div>
            <dt className="vh-mono">What we build</dt>
            <dd>Products, websites, apps and AI</dd>
          </div>
        </dl>
      </section>
      <section className="vh-sec vh-bandcta" aria-label="Start a project">
        <h2 className="vh-head">Let&apos;s talk about your project.</h2>
        <div className="vh-hero-actions">
          <Link href="/contact" className="vh-btn">
            Start a project
          </Link>
          <a href={CAL_URL} target="_blank" rel="noopener noreferrer" className="vh-btn vh-btn-ghost">
            Book a call
          </a>
        </div>
      </section>
    </>
  );
}
