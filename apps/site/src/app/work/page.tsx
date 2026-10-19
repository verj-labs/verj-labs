import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import PageHead from "@/components/site/PageHead";
import Reveal from "@/components/home/Reveal";
import { WORK } from "@/lib/work";
import { CAL_URL } from "@/lib/site";

export const metadata: Metadata = {
  title: "Work",
  description: "Case studies from Verj Labs: software products, AI platforms and websites we have built.",
};

export default function WorkPage() {
  return (
    <>
      <PageHead
        code="Work"
        title="Case studies"
        lead="How we built a few of the 25+ projects we have delivered. Each one starts with a real problem."
      />
      <section className="vh-sec vh-prods" aria-label="Case studies">
        {WORK.map((w, i) => (
          <Reveal key={w.slug} className="vh-prod" delay={i * 40}>
            <div className="vh-prod-shot">
              {w.img ? (
                <Image src={w.img} alt={`${w.name} home screen`} width={960} height={600} sizes="(max-width: 1000px) 92vw, 50vw" />
              ) : (
                <div className="vh-work-none">
                  <p className="vh-mono">No public site</p>
                  <p>Built for clients in automotive and jewellery.</p>
                </div>
              )}
            </div>
            <div className="vh-prod-text">
              <p className="vh-mono">
                {w.id} / {w.industry}
              </p>
              <h2>{w.name}</h2>
              <p className="vh-prod-tag">{w.tagline}</p>
              <p>{w.summary}</p>
              <p className="vh-mono vh-status" data-status={w.status}>
                {w.status}
              </p>
              <Link href={`/work/${w.slug}`} className="vh-btn">
                Read the case study
              </Link>
            </div>
          </Reveal>
        ))}
      </section>
      <section className="vh-sec vh-bandcta" aria-label="Start a project">
        <h2 className="vh-head">Have something in mind?</h2>
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
