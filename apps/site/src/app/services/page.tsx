import type { Metadata } from "next";
import Link from "next/link";
import PageHead from "@/components/site/PageHead";
import PixelIcon from "@/components/site/PixelIcon";
import Reveal from "@/components/home/Reveal";
import Process from "@/components/home/Process";
import SecHead from "@/components/site/SecHead";
import { SERVICES } from "@/lib/services";
import { NEEDS, timeLabel } from "@/lib/site";

export const metadata: Metadata = {
  title: "Services",
  description: "AI, software products, websites and mobile apps, built end to end by Verj Labs.",
};

export default function Services() {
  return (
    <>
      <PageHead
        code="Services"
        title="What we build"
        lead="Seven things, done end to end. Tell us what you need and we will take it from idea to launch."
      />
      <section className="vh-sec" aria-label="Services">
        {SERVICES.map((s, i) => (
          <Reveal key={s.id} className="vh-service" delay={i * 40}>
            <div id={s.id} className="vh-service-anchor" />
            <div className="vh-service-main">
              <div className="vh-svc-top">
                <span className="vh-mono">{s.code}</span>
                <PixelIcon rows={NEEDS.find((n) => n.id === s.id)!.icon} />
              </div>
              <h2>{s.title}</h2>
              <p className="vh-svc-lead">{s.lead}</p>
              <p className="vh-mono vh-svc-time">{timeLabel(s.time)}</p>
              <Link href={`/contact?need=${s.id}`} className="vh-btn">
                Start this project
              </Link>
            </div>
            <div className="vh-service-side">
              {s.examples && (
                <>
                  <p className="vh-mono">Ways we use AI</p>
                  <ul>
                    {s.examples.map((e) => (
                      <li key={e}>{e}</li>
                    ))}
                  </ul>
                </>
              )}
              <p className="vh-mono">What you get</p>
              <ul>
                {s.gets.map((g) => (
                  <li key={g}>{g}</li>
                ))}
              </ul>
            </div>
          </Reveal>
        ))}
      </section>
      <section className="vh-sec" aria-label="How it works">
        <SecHead no="05" title="How it works" note="Four steps" />
        <Process />
      </section>
    </>
  );
}
