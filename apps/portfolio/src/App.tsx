import { useEffect, useRef, useState } from "react";
import { RouteMap } from "./atlas";
import { TraceCanvas } from "./trace";
import {
  CITIES,
  MAIL,
  PHONE,
  PHONE_LABEL,
  PROOF,
  ROUTE,
  TRACES,
  WORK,
  cityById,
  hopsOf,
  traceById,
  workById,
} from "./content";

const GROUPS = [...new Set(WORK.map((item) => item.group))];

export function App() {
  const [workId, setWorkId] = useState("verily");
  const [hotId, setHotId] = useState("verily");
  const [cityId, setCityId] = useState("waterloo");
  const [traceId, setTraceId] = useState("campaign");
  const [walking, setWalking] = useState(false);
  const [menu, setMenu] = useState(false);
  const [hop, setHop] = useState(0);
  const [playing, setPlaying] = useState(false);
  const [run, setRun] = useState(0);
  const [lit, setLit] = useState(0);
  const [previewTop, setPreviewTop] = useState(0);
  const rowsRef = useRef<HTMLDivElement>(null);

  const shown = workById(hotId);
  const trace = traceById(traceId);
  const hops = hopsOf(trace);

  useEffect(() => {
    const nodes = [...document.querySelectorAll<HTMLElement>(".reveal")];
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) {
      nodes.forEach((node) => node.classList.add("in"));
      return;
    }
    const io = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;
          entry.target.classList.add("in");
          io.unobserve(entry.target);
        }
      },
      { threshold: 0.18 },
    );
    nodes.forEach((node) => io.observe(node));
    return () => io.disconnect();
  }, []);

  useEffect(() => {
    const header = document.querySelector<HTMLElement>(".header");
    if (!header) return;
    const sections = [...document.querySelectorAll<HTMLElement>("[data-tone]")];
    const apply = () => {
      let tone = "paper";
      for (const section of sections) {
        const box = section.getBoundingClientRect();
        if (box.top <= 28 && box.bottom > 28) tone = section.dataset.tone || tone;
      }
      header.dataset.tone = tone;
    };
    apply();
    window.addEventListener("scroll", apply, { passive: true });
    return () => window.removeEventListener("scroll", apply);
  }, []);

  useEffect(() => {
    const id = window.setInterval(() => setLit((n) => (n + 1) % PROOF.length), 2000);
    return () => window.clearInterval(id);
  }, []);

  function align(el: HTMLElement) {
    const body = rowsRef.current;
    if (!body) return;
    const top = el.getBoundingClientRect().top - body.getBoundingClientRect().top;
    setPreviewTop(top);
  }

  function preview(id: string, el: HTMLElement) {
    setHotId(id);
    align(el);
  }

  function commit(id: string) {
    const next = workById(id);
    setWorkId(id);
    setHotId(id);
    setCityId(next.cityId);
    setWalking(false);
    if (next.traceId) {
      setTraceId(next.traceId);
      setHop(0);
      setPlaying(false);
    }
  }

  function place(id: string, scroll = false) {
    setCityId(id);
    const lead = WORK.find((item) => item.cityId === id && item.lead) ?? WORK.find((item) => item.cityId === id);
    if (lead) {
      setWorkId(lead.id);
      setHotId(lead.id);
    }
    const traced = WORK.find((item) => item.cityId === id && item.traceId);
    if (traced?.traceId) {
      setTraceId(traced.traceId);
      setHop(0);
      setPlaying(false);
    }
    if (scroll) document.getElementById(`city-${id}`)?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  function send() {
    setHop(0);
    setPlaying(true);
    setRun((n) => n + 1);
  }

  return (
    <>
      <a className="skip" href="#work">
        Skip to the work
      </a>
      <header className="header" data-tone="paper">
        <a className="word" href="#top">
          Waqas Rehmani
        </a>
        <nav className={menu ? "nav is-open" : "nav"} aria-label="Pages">
          <button className="menu" type="button" aria-expanded={menu} onClick={() => setMenu((open) => !open)}>
            Menu
          </button>
          <div className="links">
            <a href="#work" onClick={() => setMenu(false)}>
              Work
            </a>
            <a href="#map" onClick={() => setMenu(false)}>
              Map
            </a>
            <a href="#trace" onClick={() => setMenu(false)}>
              Trace
            </a>
            <a href="https://verjlabs.com" onClick={() => setMenu(false)}>
              Verj
            </a>
          </div>
          <a className="write" href={MAIL}>
            Write
          </a>
        </nav>
      </header>

      <main>
        <section className="hero" id="top" data-tone="paper">
          <div className="hero-paper" />
          <h1 className="hero-title">
            <span>AI</span>
            <span>engineer</span>
          </h1>
          <p className="support">
            Software engineer at Verily Health. Verj Labs is the studio he runs beside it.
          </p>
        </section>

        <section className="about" data-tone="paper">
          <p className="story reveal">
            <span className="name">Waqas Rehmani</span> is an AI engineer. By day he is a software engineer at{" "}
            <mark>Verily Health</mark> in Waterloo, from August 2026. <mark className="ink">Verj Labs</mark> is the
            studio he runs beside that job, and <mark className="soft">DealrDash</mark> is one product of the studio.
            At Arctic Wolf he shipped on a security platform used by more than 700 people inside the company and more
            than 10,000 outside it, and cut the team’s review cycle by more than half with an AI workflow he built. At
            Coda Payments, campaign setup went from four days of scripting to <mark>fifteen minutes</mark>, and a
            catalogue system he led took processing from ten days to hours. He co-founded Trakart in{" "}
            <mark className="ink">Karachi</mark>, earned a bachelor’s at Bilkent in Ankara and a master’s in Melbourne,
            and studied on exchange at NTU in Singapore.{" "}
            <a className="end" href="#contact">
              He keeps shipping after every move.
            </a>
          </p>
        </section>

        <section className="work" id="work" data-tone="surface">
          <div className="ledger">
            <h2 className="reveal">The work</h2>
            <p className="outcome" aria-live="polite">
              {shown.outcome}{" "}
              {shown.href && <a href={shown.href.url}>{shown.href.label}</a>}
            </p>
            <p className="jumps">
              <a
                href="#map"
                onClick={() => {
                  setWalking(false);
                  setCityId(shown.cityId);
                }}
              >
                See {cityById(shown.cityId).name}
              </a>
              {shown.traceId && (
                <a
                  href="#trace"
                  onClick={() => {
                    setTraceId(shown.traceId as string);
                    setHop(0);
                    setPlaying(false);
                  }}
                >
                  Follow the request
                </a>
              )}
            </p>
            <div className="rows" ref={rowsRef}>
              {GROUPS.map((group) => (
                <div className="year" key={group}>
                  {WORK.filter((item) => item.group === group).map((row) => {
                    const on = row.id === hotId;
                    return (
                      <div className="slot" key={row.id}>
                        <button
                          type="button"
                          className={on ? "row is-on" : "row"}
                          aria-pressed={row.id === workId}
                          onClick={(event) => {
                            preview(row.id, event.currentTarget);
                            commit(row.id);
                          }}
                          onFocus={(event) => preview(row.id, event.currentTarget)}
                          onMouseEnter={(event) => preview(row.id, event.currentTarget)}
                        >
                          <span className="nm">{row.name}</span>
                          <span className="kd">{row.kind}</span>
                          <span className="yr">{row.year}</span>
                        </button>
                      </div>
                    );
                  })}
                </div>
              ))}
              <figure className="preview" style={{ top: previewTop }} aria-hidden="true">
                <img src={cityById(shown.cityId).src} alt="" />
              </figure>
            </div>
          </div>
        </section>

        <section className="map" id="map" data-tone="ink">
          <div className="atlas">
            <div className="atlas-copy">
              <h2 className="reveal">Five countries</h2>
              <p className="reveal" style={{ ["--d" as string]: "80ms" }}>
                Ankara, then Singapore, Melbourne, Karachi and Waterloo. A degree, an exchange, a remote role for a
                company abroad, a startup, and the Canadian work. He starts again in a new place and ships.
              </p>
              <button
                className="send reveal"
                type="button"
                style={{ ["--d" as string]: "160ms" }}
                onClick={() => {
                  if (walking) {
                    setWalking(false);
                    return;
                  }
                  if (cityId === ROUTE[ROUTE.length - 1]) place(ROUTE[0]);
                  setWalking(true);
                }}
              >
                {walking ? "Pause" : "Walk the route"}
              </button>
              <div className="choices">
                {CITIES.map((item) => (
                  <button
                    key={item.id}
                    type="button"
                    className="choice"
                    aria-pressed={item.id === cityId}
                  onClick={() => {
                    setWalking(false);
                    place(item.id, true);
                  }}
                  >
                    {item.name}
                  </button>
                ))}
              </div>
            </div>
            <RouteMap
              cityId={cityId}
              walking={walking}
              onPick={(id) => {
                setWalking(false);
                place(id, true);
              }}
              onArrive={(id) => place(id, false)}
              onDone={() => setWalking(false)}
            />
          </div>
          {CITIES.map((item) => (
            <article className={item.id === cityId ? "place is-on" : "place"} id={`city-${item.id}`} key={item.id}>
              <div className="frame">
                <img src={item.src} alt={item.alt} width={item.width} height={item.height} />
              </div>
              <div className="place-copy">
                <h3>{item.name}</h3>
                <p>{item.story}</p>
                <p className="credit">
                  <a href={item.credit.page}>{item.credit.title}</a> by {item.credit.creator},{" "}
                  <a href={item.credit.licenseUrl}>{item.credit.license}</a>, via Wikimedia Commons. The photograph is
                  the city, not a picture of his office.
                </p>
              </div>
            </article>
          ))}
        </section>

        <section className="compare" data-tone="paper">
          <div className="compare-top">
            <h2 className="reveal">Campaign setup</h2>
            <p className="reveal" style={{ ["--d" as string]: "90ms" }}>
              At Coda Payments, setting up a campaign meant writing scripts, and it took four days. He built a tool
              that does that setup in fifteen minutes. On the same team, catalogue changes that took ten days started
              clearing in hours. He connects that speed to an estimated $1.2 million a month.
            </p>
          </div>
          <div className="specimens">
            <p className="giant reveal" style={{ ["--d" as string]: "40ms" }}>
              4<span>days</span>
            </p>
            <p className="giant reveal inverse" style={{ ["--d" as string]: "120ms" }}>
              15<span>min</span>
            </p>
          </div>
        </section>

        <section className="trace" id="trace" data-tone="ink">
          <div className="trace-grid">
            <div className="trace-copy">
              <h2 className="reveal">One request</h2>
              <p className="reveal" style={{ ["--d" as string]: "80ms" }}>
                {trace.blurb} The slip beside it is the same path, if you would rather read than watch.
              </p>
              <button className="send" type="button" onClick={send}>
                Send it
              </button>
            </div>
            <div className="trace-stage">
              <div className="systems" role="group" aria-label="Systems">
                {TRACES.map((item) => (
                  <button
                    key={item.id}
                    type="button"
                    className="choice"
                    aria-pressed={item.id === traceId}
                    onClick={() => {
                      setTraceId(item.id);
                      setHop(0);
                      setPlaying(false);
                    }}
                  >
                    {item.name}
                  </button>
                ))}
              </div>
              <p className="now" aria-live="polite">
                {hops[hop]?.what}
              </p>
              <TraceCanvas
                trace={trace}
                hop={hop}
                playing={playing}
                run={run}
                onHop={setHop}
                onDone={() => setPlaying(false)}
              />
              <article className="slip" aria-label={trace.name}>
                {trace.groups.map((group) => (
                  <div key={group.heading}>
                    <h3>{group.heading}</h3>
                    {group.hops.map((step) => (
                      <p key={step.short} className={step.what === hops[hop]?.what ? "is-hot" : ""}>
                        <span>{step.what}</span>
                        <span className="dots" aria-hidden="true">
                          {Array.from({ length: 5 }, (_, i) => (
                            <i key={i} />
                          ))}
                        </span>
                        <span className="detail">{step.detail}</span>
                      </p>
                    ))}
                  </div>
                ))}
                <p className="result">{trace.result}</p>
              </article>
            </div>
          </div>
        </section>

        <section className="proof" data-tone="paper" aria-label="Shipped">
          <p className="runon">
            <span className="full">Shipped </span>
            {PROOF.map((name, index) => (
              <span key={name} className={index === lit ? "on" : ""}>
                {name}
                {index < PROOF.length - 1 ? ", " : "."}
              </span>
            ))}
          </p>
        </section>

        <section className="contact" id="contact" data-tone="paper">
          <p>Waqas Rehmani</p>
          <a href="https://maps.google.com/?q=Milton,Ontario">Milton, Ontario</a>
          <a href="https://verily.com">Verily Health</a>
          <a href="https://verjlabs.com">Verj Labs</a>
          <a href={PHONE}>{PHONE_LABEL}</a>
          <div className="hello">
            <a href={MAIL}>Hello</a>
            <a className="arrow" href={MAIL} aria-label="Email Waqas">
              <Arrow />
            </a>
          </div>
        </section>
      </main>

      <footer className="footer" data-tone="accent">
        <div className="notes">
          <p>AI engineer. Software engineer at Verily Health. Verj Labs is the studio beside it.</p>
          <a href="#top">Back to the top</a>
        </div>
        <a className="email" href={MAIL}>
          mr.wrehmani
          <br />
          @gmail.com
        </a>
        <div className="meta">
          <p>
            <a href="https://www.linkedin.com/in/wrehmani">LinkedIn</a>
            <a href="https://github.com/dadaJaani">GitHub</a>
            <a href="https://verjlabs.com">Verj Labs</a>
          </p>
          <p>Milton, 2026</p>
        </div>
        <p className="credits">
          Pictures:{" "}
          {CITIES.map((item, index) => (
            <span key={item.id}>
              <a href={item.credit.page}>{item.credit.title}</a> by {item.credit.creator},{" "}
              <a href={item.credit.licenseUrl}>{item.credit.license}</a>
              {index < CITIES.length - 1 ? "; " : ", via Wikimedia Commons."}
            </span>
          ))}
        </p>
      </footer>
    </>
  );
}

function Arrow() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M5 12h12M13 6l6 6-6 6" fill="none" stroke="currentColor" strokeWidth="2" />
    </svg>
  );
}
