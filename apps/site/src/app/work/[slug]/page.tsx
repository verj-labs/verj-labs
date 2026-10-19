import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import PageHead from "@/components/site/PageHead";
import SecHead from "@/components/site/SecHead";
import { WORK, caseBySlug } from "@/lib/work";
import { CAL_URL } from "@/lib/site";

export const dynamicParams = false;

export function generateStaticParams() {
  return WORK.map((w) => ({ slug: w.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const w = caseBySlug(slug);
  return w ? { title: `${w.name} case study`, description: w.summary } : {};
}

export default async function CaseStudy({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const w = caseBySlug(slug);
  if (!w) notFound();
  const i = WORK.findIndex((x) => x.slug === slug);
  const next = WORK[(i + 1) % WORK.length];

  return (
    <>
      <PageHead code={`Case study / ${w.id}`} title={w.name} lead={w.tagline} />

      <section className="vh-sec" aria-label="At a glance">
        <dl className="vh-facts vh-facts-top">
          <div>
            <dt className="vh-mono">Industry</dt>
            <dd>{w.industry}</dd>
          </div>
          <div>
            <dt className="vh-mono">What we did</dt>
            <dd>{w.did}</dd>
          </div>
          <div>
            <dt className="vh-mono">Status</dt>
            <dd data-status={w.status} className="vh-status-dd">
              {w.status}
            </dd>
          </div>
        </dl>
      </section>

      {w.img && (
        <section className="vh-case-shot" aria-label="Screenshot">
          <figure>
            <Image src={w.img} alt={`${w.name} home screen`} width={1440} height={900} sizes="(max-width: 1000px) 94vw, 90vw" priority />
            <figcaption className="vh-mono">
              {w.status === "No longer live" ? "Archived screenshot" : "Screenshot"} / {w.name}
            </figcaption>
          </figure>
        </section>
      )}

      <section className="vh-sec" aria-label="Challenge and solution">
        <SecHead no="01" title="The problem" note={w.industry} />
        <p className="vh-lead">{w.challenge}</p>
      </section>

      <section className="vh-sec" aria-label="What we built">
        <SecHead no="02" title="What we built" note={w.did} />
        <ul className="vh-case-list">
          {w.built.map((b, n) => (
            <li key={b}>
              <span className="vh-mono">{String(n + 1).padStart(2, "0")}</span>
              <span>{b}</span>
            </li>
          ))}
        </ul>
        {w.url && (
          <p className="vh-more">
            <a href={w.url} target="_blank" rel="noopener noreferrer" className="vh-btn">
              Visit {w.label}
            </a>
          </p>
        )}
      </section>

      <section className="vh-sec vh-bandcta" aria-label="Next steps">
        <h2 className="vh-head">Want something like this?</h2>
        <div className="vh-hero-actions">
          <Link href="/contact" className="vh-btn">
            Start a project
          </Link>
          <a href={CAL_URL} target="_blank" rel="noopener noreferrer" className="vh-btn vh-btn-ghost">
            Book a call
          </a>
        </div>
        <Link href={`/work/${next.slug}`} className="vh-mono vh-nextcase">
          Next case study: {next.name} &rarr;
        </Link>
      </section>
    </>
  );
}
