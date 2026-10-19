# Verj Labs homepage redesign: direction and copy deck

Status: draft for review. Nothing is built yet.
Skills used: design-taste-frontend (draw seed 47047106), industrial-brutalist-ui (type and geometry only).

## 1. Direction

**Dealt:** "The sentence is the layout" (`sentence-as-layout`). One short sentence at poster scale; something from the subject sits inside it where a word would be.

**Why this one over the other two** (`type-only-statement`, `editorial-report`): Verj's idea is that the studio ships *live* software. A sentence whose middle is a working fragment, not a picture of one, says that in one glance. Type-only has no room for the pixel field. Editorial-report is too quiet for brutalist.

**Idea sentence:** On this page, *the squares of the pixel field* become *the software itself*: the field sits inside the hero sentence where the noun would be, and later resolves into a real product fragment.

**Competitor test:** Another agency's sentence can't hold DealrDash, Zavara and Halal Compass as the thing that fills the gap. Passes.

**Live thing:** "Scope it". Pick a project type; the page shows the real timeline range, the stack we'd use, and a code block that types out a real snippet for that type. One control, thumb-sized, with a plain list fallback without script.

### Redraws (with reasons)

| Slot | Dealt | Replaced with | Reason |
| --- | --- | --- | --- |
| Palette | Mustard and black, royal blue accent | Black ground, lime accent, off-white ink | Existing brand: lime `#D4F53C` is the identity. |
| Type | Sentient (light serif) | One heavy grotesque, uppercase display, tight tracking (0.85 to 0.95 leading) | Brutalist direction you chose. Candidate: Archivo Black or Bricolage (already loaded). |
| Photographs | "Architecture" set | None. Real product screenshots (the three live sites) plus drawn pixel fields | The architecture set is unrelated to this subject. |

### Rules where the two skills disagree
- **Taken from brutalist:** heavy sans at huge scale, tight tracking, square corners, rigid grid, one substrate (dark).
- **Dropped from brutalist:** mono uppercase labels, `01/02/03`, hairline rules, `[BRACKETED]` text, CRT scanlines and noise. The taste inspector fails these.
- **Pixel field:** built from discrete flat squares (hard edges, no smooth gradient, no blur), so it passes the "no gradients" rule. Lime and black only. One large field per screen at most.
- **Code block:** the one permitted monospace, real code in `<pre>`. No falling-character matrix.

## 2. The argument (claims and proof)

| # | Claim | Proof |
| --- | --- | --- |
| 1 | We ship software that is live today. | Hero: pixel field inside the sentence; one button. |
| 2 | Three products are running in production. | Real screenshots of DealrDash, Zavara Studio, Halal Compass, each linked. |
| 3 | You get a fixed shape and a timeline. | Process slider: Scope, Design, Build, Launch. |
| 4 | Here is what we build, and how long each takes. | Services paragraph with inline fragments; ranges taken from the existing services page. |
| 5 | Your questions have straight answers. | Six FAQ items. |
| 6 | Tell us what you need and hear back. | Sentence-with-a-blank form. |

Cut from the current page: tech-stack marquee, "What we do" card grid, badges, orbs.

## 3. Copy deck

Rules applied: headlines two lines or fewer, sentence case or uppercase per the display style, no eyebrows, no numbering, no invented proof, no personal info.

### Navigation
Wordmark: Verj Labs. Links: Work, Services, About, Contact. Button: Start a project.

### Hero (sentence split by the pixel frame)
- Left half: **We ship**
- Frame: live pixel field (lime and black squares), 16:9, resolving to a product fragment on load.
- Right half: **real software**
- Supporting sentence (18px): Verj Labs is a Canadian studio that designs, builds and launches SaaS products and client platforms, end to end.
- Button: **Start a project** (links to `#start`).

Alternates to consider: "We build / live software", "Shipped, / not shelved".

### Intro (pinned sentence)
Paragraph, not a heading, about 12 words:
> Three products live today. Each one built and run by the same small team.

(Screenshots of the three sites scroll past behind it.)

### Work (names as one paragraph)
Opening words, full ink: **Shipped:** then names flowing as one paragraph, each a link:
DealrDash, Zavara Studio, Halal Compass, Industry sites.

Per-name hover reveals one line:
- **DealrDash**: Dealer management for car dealerships across Canada and the US. Multi-tenant, multi-location, real-time inventory. dealrdash.com
- **Zavara Studio**: AI-first project and client platform for jewelers, with AI content generation. zavarastudio.com
- **Halal Compass**: Web, mobile and internal tools for discovering halal restaurants and businesses. thehalalcompass.com
- **Industry sites**: CMS-backed websites for automotive and jewellery clients, managed by the client.

Footer line (15px): Three live products. Client work in automotive and jewellery.

### How it works (drag through stages; the live thing)
Heading words per stage (clause, 3 to 6 words):
- **First, we scope it.** Fragment: a scoped brief with fixed deliverables.
- **Then we design it.** Fragment: a real interface screen.
- **Then we build it.** Fragment: the code block, typing real code.
- **Then we launch it.** Fragment: a deploy log ending in "live".

Slider labels: Scope, Design, Build, Launch.

"Scope it" control (inside this section): choose Product, Client build, AI integration or Mobile app. Output:

| Pick | Timeline | Stack we would use |
| --- | --- | --- |
| Product | 6 to 16 weeks | Next.js, NestJS, PostgreSQL, AWS |
| Client build | 4 to 8 weeks | Next.js, Sanity CMS, Vercel |
| AI integration | 2 to 6 weeks | OpenAI or Claude APIs, RAG pipeline |
| Mobile app | 6 to 14 weeks | React Native, Expo |

(Ranges are from the current services page. Confirm before launch.)

### Services (paragraph with picture words)
Visually hidden heading: What we build.
> We take a product from idea to a deployed **SaaS** [fragment] and keep improving it after launch. We build custom **websites** [fragment] and CMS platforms with fixed scope and a proper handoff. We add **AI** [fragment] where it helps: RAG pipelines, LLM APIs and automation that ships. And we build **mobile apps** [fragment] in React Native for iOS and Android.

Support sentence (18px): Fixed scope, fixed timeline, full handoff with documentation. **Start a project**.

### FAQ (six questions, answers to write with you)
1. How long does a project take?: Ranges by type, as above.
2. Do you work with fixed scope?: Client builds are fixed scope and timeline.
3. Who will I be working with?: Answer needs your input (studio, no individual bios).
4. Do you only build from scratch?: AI features can be added to existing products.
5. What happens after launch?: Ongoing iterations post-launch.
6. Where are you based?: Verj Labs Inc., Canada.

Open items marked here need your confirmation: payment terms and pricing, team size, and a policy for working with existing codebases. I have not invented answers.

### Closing form (sentence with a blank)
> I need a **[email field]** built. **Send**

Line under: We reply from hello@verjlabs.com, usually within two business days. *(Confirm the reply time.)*

### Footer
Invitation: **Let's build it.** Button: Start a project. Links: Email, plus any socials you want listed.
Wordmark: VERJ LABS, cropped at the bottom.
Legal row: Verj Labs Inc. Canada.

## 4. What I need from you
- Hero sentence: "We ship real software" or an alternate?
- Pricing: show "from" ranges, or keep "tell us what you need"?
- Reply-time claim and FAQ items 3 to 6 answers.
- Whether to capture fresh screenshots of the three live sites for the work section.
- Whether the three project names should link out in a new tab.
