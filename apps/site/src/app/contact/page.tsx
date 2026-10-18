import Link from "next/link";
import { FadeUp, StaggerGrid, StaggerItem } from "@/components/motion";
import {
  TbMail, TbMapPin, TbClock, TbSend,
  TbPhone, TbMessageCircle, TbCheck, TbArrowRight,
} from "react-icons/tb";

const steps = [
  { num: "01", title: "Discovery Call", desc: "We learn your idea, constraints, and timeline. No pitch, just conversation.", icon: <TbPhone size={18} className="text-lime" /> },
  { num: "02", title: "Proposal", desc: "Clear scope, timeline, and cost. No surprises, no vague estimates.", icon: <TbMessageCircle size={18} className="text-purple" /> },
  { num: "03", title: "Build", desc: "Senior-led execution with regular updates. You're always in the loop.", icon: <TbCheck size={18} className="text-teal" /> },
  { num: "04", title: "Launch", desc: "We ship, you go live. Support and iteration available post-launch.", icon: <TbArrowRight size={18} className="text-amber" /> },
];

export default function Contact() {
  return (
    <div className="min-h-screen">
      {/* Hero */}
      <section className="relative py-24 overflow-hidden px-6">
        <div className="mesh-orb-lime absolute w-96 h-96 -top-24 -left-24 pointer-events-none" aria-hidden="true" />
        <div className="mesh-orb-purple absolute w-80 h-80 top-10 right-0 pointer-events-none" aria-hidden="true" />

        <div className="max-w-4xl mx-auto text-center relative z-10">
          <FadeUp>
            <p className="eyebrow mb-4">Let&apos;s build together</p>
            <h1 className="text-scale-1 font-bricolage text-off-white mb-5">Get in Touch</h1>
            <p className="text-[1.05rem] text-off-white/45 leading-[1.75] max-w-[480px] mx-auto font-light">
              Tell us what you&apos;re building. We&apos;ll tell you if we&apos;re the right fit — and if we are, we move fast.
            </p>
          </FadeUp>
        </div>
      </section>

      {/* How it works */}
      <section className="pb-16">
        <div className="max-w-7xl mx-auto px-6">
          <FadeUp className="mb-8">
            <p className="eyebrow mb-3">How it works</p>
            <h2 className="text-scale-2 font-bricolage text-off-white">Simple, clear process.</h2>
          </FadeUp>
          <StaggerGrid className="grid sm:grid-cols-2 lg:grid-cols-4 gap-5" staggerDelay={0.09}>
            {steps.map((s) => (
              <StaggerItem key={s.num}>
                <div className="card-dark h-full">
                  <div className="step-num mb-3">{s.num}</div>
                  <div className="mb-3">{s.icon}</div>
                  <div className="font-bricolage font-bold text-[0.95rem] text-off-white mb-2">{s.title}</div>
                  <p className="text-[0.78rem] text-off-white/38 leading-[1.6] font-light">{s.desc}</p>
                </div>
              </StaggerItem>
            ))}
          </StaggerGrid>
        </div>
      </section>

      {/* Form + info */}
      <section className="pb-16">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid lg:grid-cols-2 gap-8 items-start">

            {/* Form */}
            <FadeUp>
              <div className="card-dark">
                <h2 className="font-bricolage font-bold text-[1.5rem] text-off-white mb-1.5" style={{ letterSpacing: "-0.025em" }}>
                  Send Us a Message
                </h2>
                <p className="text-[0.82rem] text-off-white/35 mb-7 font-light">We respond within 24 hours.</p>

                <form className="space-y-5">
                  {[
                    { id: "name", label: "Full Name *", type: "text", placeholder: "Your name", required: true },
                    { id: "email", label: "Email Address *", type: "email", placeholder: "your@email.com", required: true },
                    { id: "company", label: "Company (Optional)", type: "text", placeholder: "Company name", required: false },
                  ].map((f) => (
                    <div key={f.id}>
                      <label htmlFor={f.id} className="block text-[0.75rem] font-outfit text-off-white/45 mb-2">{f.label}</label>
                      <input
                        type={f.type}
                        id={f.id}
                        name={f.id}
                        placeholder={f.placeholder}
                        required={f.required}
                        className="w-full px-4 py-3.5 bg-white/[0.03] border border-white/[0.08] rounded-xl text-off-white text-sm font-outfit placeholder-off-white/20 focus:border-lime/40 focus:ring-1 focus:ring-lime/20 outline-none transition-all"
                      />
                    </div>
                  ))}

                  <div>
                    <label htmlFor="project-type" className="block text-[0.75rem] font-outfit text-off-white/45 mb-2">Project Type</label>
                    <select
                      id="project-type"
                      name="project-type"
                      className="w-full px-4 py-3.5 bg-white/[0.03] border border-white/[0.08] rounded-xl text-off-white/60 text-sm font-outfit focus:border-lime/40 focus:ring-1 focus:ring-lime/20 outline-none transition-all"
                    >
                      <option value="">Select type</option>
                      <option value="product-dev">Product Development</option>
                      <option value="client-build">Client Build</option>
                      <option value="ai">AI Integration</option>
                      <option value="mobile">Mobile App</option>
                      <option value="other">Other</option>
                    </select>
                  </div>

                  <div>
                    <label htmlFor="message" className="block text-[0.75rem] font-outfit text-off-white/45 mb-2">Project Details *</label>
                    <textarea
                      id="message"
                      name="message"
                      rows={5}
                      placeholder="Tell us about your project, goals, and timeline..."
                      required
                      className="w-full px-4 py-3.5 bg-white/[0.03] border border-white/[0.08] rounded-xl text-off-white text-sm font-outfit placeholder-off-white/20 focus:border-lime/40 focus:ring-1 focus:ring-lime/20 outline-none transition-all resize-none"
                    />
                  </div>

                  <button type="submit" className="btn-primary w-full justify-center gap-2">
                    <TbSend size={16} />
                    Send Message
                  </button>
                </form>
              </div>
            </FadeUp>

            {/* Info */}
            <FadeUp delay={0.1}>
              <div className="space-y-5">

                {/* Contact details */}
                <div className="card-dark">
                  <h3 className="font-bricolage font-bold text-[1rem] text-off-white mb-5" style={{ letterSpacing: "-0.01em" }}>Contact Info</h3>
                  <div className="space-y-5">
                    {[
                      { icon: <TbMail size={18} className="text-lime" />, bg: "bg-lime/10", title: "Email", val: "hello@verjlabs.com", note: "We respond within 24 hours" },
                      { icon: <TbMapPin size={18} className="text-teal" />, bg: "bg-teal/10", title: "Location", val: "Toronto, Canada", note: "Remote-first, global reach" },
                      { icon: <TbClock size={18} className="text-purple" />, bg: "bg-purple/10", title: "Response Time", val: "Usually 2–4 hours", note: "Same-day for urgent inquiries" },
                    ].map((item) => (
                      <div key={item.title} className="flex items-start gap-3.5">
                        <div className={`p-2.5 ${item.bg} rounded-xl flex-shrink-0`}>{item.icon}</div>
                        <div>
                          <div className="text-[0.72rem] text-off-white/30 font-outfit mb-0.5">{item.title}</div>
                          <div className="text-[0.85rem] text-off-white/70 font-outfit font-medium">{item.val}</div>
                          <div className="text-[0.72rem] text-off-white/30 font-outfit mt-0.5">{item.note}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Book a call */}
                <div className="card-glass card-glass-lime">
                  <h3 className="font-bricolage font-bold text-[1rem] text-off-white mb-2">Prefer to talk?</h3>
                  <p className="text-[0.82rem] text-off-white/42 font-light mb-5">
                    Book a free 30-minute discovery call. We&apos;ll discuss your project and figure out the best path forward.
                  </p>
                  <a
                    href="mailto:hello@verjlabs.com?subject=Discovery Call Request"
                    className="btn-primary text-sm inline-flex items-center gap-2"
                  >
                    Book a Call <TbArrowRight size={15} />
                  </a>
                </div>

                {/* Quick links */}
                <div className="card-dark">
                  <h3 className="font-bricolage font-bold text-[1rem] text-off-white mb-4">Quick Links</h3>
                  <div className="space-y-1">
                    {[
                      { href: "/portfolio", label: "View Our Work" },
                      { href: "/services", label: "Our Services" },
                      { href: "/products", label: "Our Products" },
                    ].map((l) => (
                      <Link
                        key={l.href}
                        href={l.href}
                        className="flex items-center justify-between px-3 py-3 rounded-xl text-[0.82rem] font-outfit text-off-white/40 hover:text-off-white hover:bg-white/[0.03] transition-all group"
                      >
                        <span>{l.label}</span>
                        <TbArrowRight size={14} className="group-hover:translate-x-0.5 transition-transform" />
                      </Link>
                    ))}
                  </div>
                </div>
              </div>
            </FadeUp>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="pb-24">
        <div className="max-w-4xl mx-auto px-6">
          <FadeUp className="mb-10">
            <p className="eyebrow mb-3">Common Questions</p>
            <h2 className="text-scale-2 font-bricolage text-off-white">FAQ</h2>
          </FadeUp>
          <StaggerGrid className="grid sm:grid-cols-2 gap-5" staggerDelay={0.08}>
            {[
              { q: "How long does a typical project take?", a: "Most projects range from 4–16 weeks depending on scope. We provide a detailed timeline in our proposal before work begins." },
              { q: "Do you work with startups?", a: "Absolutely. We work with founders at idea stage and with established teams adding new capabilities. We're comfortable with ambiguity." },
              { q: "Do you offer fixed pricing?", a: "Yes — for scoped projects we provide a fixed quote. No hourly billing surprises. We scope carefully and stand behind our estimates." },
              { q: "Can you take over an existing project?", a: "Yes. We can audit, extend, or take over existing codebases. We'll be honest upfront if a codebase isn't something we can work with." },
            ].map((faq) => (
              <StaggerItem key={faq.q}>
                <div className="card-dark h-full">
                  <h3 className="font-bricolage font-bold text-[0.95rem] text-off-white mb-3" style={{ letterSpacing: "-0.01em" }}>{faq.q}</h3>
                  <p className="text-[0.82rem] text-off-white/38 leading-[1.65] font-light">{faq.a}</p>
                </div>
              </StaggerItem>
            ))}
          </StaggerGrid>
        </div>
      </section>
    </div>
  );
}
