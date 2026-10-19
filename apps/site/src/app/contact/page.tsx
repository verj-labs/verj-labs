import type { Metadata } from "next";
import PageHead from "@/components/site/PageHead";
import Wizard from "@/components/home/Wizard";
import { CAL_URL, EMAIL } from "@/lib/site";

export const metadata: Metadata = {
  title: "Contact",
  description: "Tell Verj Labs what you want to build, or book a call.",
};

export default async function Contact({ searchParams }: { searchParams: Promise<{ need?: string }> }) {
  const { need } = await searchParams;
  return (
    <>
      <PageHead code="Contact" title="Start a project" lead="Answer three quick questions, or book a call if you would rather talk." />
      <section className="vh-sec" aria-label="Contact">
        <div className="vh-contact">
          <div className="vh-cta-body">
            <Wizard initialNeed={need} />
          </div>
          <aside className="vh-contact-side">
            <p className="vh-mono">Prefer to talk?</p>
            <a href={CAL_URL} target="_blank" rel="noopener noreferrer" className="vh-btn">
              Book a call
            </a>
            <p className="vh-mono">Or email</p>
            <a href={`mailto:${EMAIL}`} className="vh-contact-mail">
              {EMAIL}
            </a>
            <p className="vh-mono">Verj Labs Inc. / Canada</p>
          </aside>
        </div>
      </section>
    </>
  );
}
