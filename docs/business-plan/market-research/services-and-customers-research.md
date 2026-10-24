# Verj Labs: Service Longlist and Ideal Customer Longlist

Prepared 2026-10-22 for Verj Labs (verjlabs.com). This report builds on `market-reserach.md` (2026-10-21) and `competition-and-reels-research.md` (2026-10-22). It does not repeat their market sizing, demand statistics, competitor maps or compliance basics. When it relies on them, it says "prior report."

**Hard constraints applied throughout:**
- No healthcare or clinics of any kind, in any service or customer list.
- Jewelers and car dealerships are not top targets.
- Fixed-price, productized and recurring offers come first. Hourly billing is only for ad-hoc work.
- Everything must be deliverable by one engineer with AI tooling.

**Confidence legend:**
- **[H]** Primary source: regulator, StatCan/ISED, government, or a survey with a disclosed method.
- **[M]** Reputable secondary source, or a vendor survey with a stated sample.
- **[L]** Vendor marketing, an agency's own price page, an anecdote, or my estimate.

Most service-price "surveys" online are written by agencies or tool vendors selling that service, and I flag them. Prices are USD unless marked CA$.

---

## Executive summary

1. **Two buyer types, two ladders.**
   - Local service firms (trades, brokers, small law) buy **revenue capture**: answering, follow-up, reviews and visibility.
   - Back-office-heavy B2B firms (accountants, property managers, distributors, manufacturers, staffing) buy **time and error reduction**: automation, portals and modernized tools.
   - Verj's engineering depth is a bigger edge on the second ladder, where competition is thinner and tickets run CA$5k-60k.
2. **The 10 services, ranked by evidence:**
   1. Missed-Lead Recovery
   2. Ops Automation and CRM
   3. Custom tools and portals
   4. Lead-Leak Audit
   5. Multilingual Intake Desk
   6. Legacy Modernization
   7. Growth Site subscription
   8. AI Visibility and Reviews
   9. Local Video Engine
   10. Shopify/B2B commerce
3. **Shortlist five:** the Audit as entry, Missed-Lead Recovery, the Multilingual Intake Desk, Ops Automation, and Custom tools/modernization as one high-ticket track. Visibility and Video are month 2-4 upsells, not lead offers.
4. **Customer longlist:** 29 segments. The top 12 are led by:
   1. 5-30 staff HVAC/plumbing/electrical firms
   2. Small law firms
   3. Independent insurance brokerages
   4. Property managers
   5. Mortgage brokerages (2025-26 renewal wave)
   6. Accounting/tax firms
   - Downgrades: immigration consultants (IRCC volume cuts squeeze budgets), new-build construction subcontractors (GTA new home sales 81% below the 10-year average) and real estate agents.
5. **Corrections to the prior plan:**
   - OCI's DMAP requires its plan-writing consultants to be vendor-neutral. They cannot implement what they recommend.
   - The Canada-Ontario Job Grant is paused.
   - Neither grant is a near-term funnel for Verj implementation work.
6. **Test first:** three offers across seven segments for 90 days. The landing page must prove four things: a live multilingual demo number, a sample secret-shop audit, a recovered-revenue report, and a privacy/ownership page. It should show prices from CA$497.

---

# DELIVERABLE 1: Ten services Verj should consider

### How to read the scores

| Field | Scale |
|---|---|
| Newcomer sell difficulty | 1 = easy to sell with no brand, 5 = very hard |
| Solo feasibility with AI | 1 = needs a team, 5 = easily solo |
| Competition | 1 = little, 5 = saturated |
| Fit with Verj skills | 1 = poor, 5 = ideal |

Gross margin is after tools and the founder's delivery time valued at about CA$100/hour (my estimate). Sales cycle and margin figures are my estimates unless cited.

---

### S1. Lead-Leak and AI Visibility Audit (productized, fixed price)

- **What it is:** A 48-hour report. It covers:
  - Secret-shop calls in and after hours, with a recording
  - A web-form response timer test
  - Google Business Profile, review gap and schema check
  - A snapshot of how ChatGPT, Gemini and Perplexity answer "best [service] near [town]," against 3 competitors
  - A 10-item fix list with a Loom walkthrough
- **Pain and buyer's words:** "I don't know how many calls I miss." "Leads go cold." "Why does ChatGPT recommend my competitor?" "Is my marketing guy actually doing anything?"
- **Price evidence:**
  - Small-business discovery and audit fees run $250-1,000; mid-market $1,500-5,000 ([Vantaige rate card, July 2026](https://vantaige.io/blog/2026-ai-automation-rate-card-operators-charge)) [L, no sample disclosed].
  - AI visibility audits run $500-2,000 one-off ([LLM Pulse, Oct 2026](https://llmpulse.ai/blog/geo-agency-guide/)) [L, GEO-software vendor].
  - **Suggested Verj pricing:**
    - A free "mini" version (3 findings) as an outreach asset.
    - A paid CA$497 full audit for local firms, credited toward implementation.
    - A CA$750-1,500 "Ops Bottleneck Audit" for B2B firms.
- **Demand signal:** 45% of US consumers used AI tools for local business recommendations in the past year (31% ChatGPT), up from 6% ([BrightLocal LCRS AI report, Mar 2026, n=1,002](https://www.brightlocal.com/research/lcrs-ai-trust/)) [M]. Only about 16% of companies track their AI visibility (Bluefish 2025, via [QuickSEO compilation, 2026](https://quickseo.ai/blog/smb-seo-statistics-2026-75-benchmarks-on-budgets-roi-time-to-result-churn-geo)) [L, secondary].
- **Sales cycle:** same day to 1 week.
- **Newcomer sell difficulty:** 1. It is cheap, concrete and personalized.
- **Solo feasibility:** 5. Automate it with scripted test calls, an LLM prompt battery and a Next.js report template. About 1-2 hours per audit once built.
- **Gross margin:** 80-90%. But treat it as customer acquisition cost, not profit.
- **Retention:** none. It is one-off by design.
- **Competition:** 3. Many agencies give "free SEO audits," but almost none secret-shop the phone and the AI answers together.
- **Fit:** 5.
- **Role:** entry offer.
- **Verdict:** **Build first.** It is the top of every funnel below. Expect 20-40% audit-to-paid conversion when the audit shows a live, embarrassing gap (my estimate; the prior report's Indie Hackers benchmark was 16% reply and 3 of 8 signed).

---

### S2. Missed-Lead Recovery System (speed-to-lead layer)

- **What it is:**
  - Overflow and after-hours AI answering (or sitting on top of the client's Jobber/HCP receptionist)
  - Missed-call text-back
  - A 60-second web/LSA/HomeStars lead response
  - Quote follow-up and a dormant-customer reactivation sequence
  - A monthly recovered-revenue report
  - This is the offer already specified in the prior reports.
- **Pain and buyer's words:** "I'm on a roof, I can't answer." "We paid for the lead and nobody called back." "The answering service is useless."
- **Price evidence (prior reports):**
  - Agencies charge $199-599/month; SaaS runs $29-800.
  - Verj recommended price: CA$1,500-2,500 setup plus CA$497-997/month.
  - New 2026 evidence: Jobber raised list prices in June 2026 (Connect $99→$139, Grow $149→$199) and launched a $49/month Sales Pipeline add-on ([PricingSaaS, July 2026](https://pricingsaas.com/companies/jobber/diffs/2026Q2)) [M]. Owners are paying more for software that still doesn't do cross-channel follow-up.
- **Sales cycle:** 1-3 weeks.
- **Newcomer sell difficulty:** 2. A live demo phone number sells it.
- **Solo feasibility:** 4. It is templated after the first 2-3 installs.
- **Gross margin:** 70-85%.
- **Retention:** medium. It churns if not tied to reported dollars.
  - Agencies whose client relationships last 0-12 months are far less likely to offer analytics and reporting: 6%, versus 48% overall ([CallRail 2026 Agency Outlook, n=100, Oct 2025](https://cdn.mediavalet.com/usva/callrail/XgWRrshJhEWNQhju4is74g/GRI6z_RpNEOURtImvC_eQA/Original/CallRail_2026%20Agency%20Marketing%20Outlook%20Report.pdf)) [M].
  - Only 3% of agencies keep clients 36+ months; 57% keep them 12-24 months (same source).
- **Competition:** 4. The receptionist is commoditized; the installed, cross-channel and reported system is not.
- **Fit:** 5.
- **Role:** core offer and retainer anchor for local service firms.
- **Verdict:** **Shortlist.** Sell it as "lead recovery with proof," never as "an AI receptionist."

---

### S3. Multilingual Intake Desk (voice, WhatsApp and web, in community languages)

- **What it is:**
  - A 24/7 intake agent in English plus 2-3 of Punjabi, Urdu, Hindi, Mandarin, Cantonese, Tagalog, Tamil or Arabic
  - Code-switching scripts and a regulated "intake only, no advice" design
  - Booking, deposit links and CRM entry
  - Caller-ID routing so existing clients reach a human
  - A PIPEDA/OPC-aligned recording disclosure
- **Pain and buyer's words:** "Half my callers prefer Punjabi and my receptionist only speaks English." "We lose people at 9pm on WhatsApp." "I can't hire a multilingual front desk."
- **Demand evidence:**
  - 23.7% of Canadian private-sector businesses are majority immigrant-owned ([StatCan, Apr 2024, Q1 2024 data](https://www.statcan.gc.ca/o1/en/plus/6128-one-four-private-sector-businesses-are-owned-immigrants-how-are-they-doing)) [H].
  - 33% of Peel residents speak a non-official language at home ([Peel Region, 2021 Census release](https://www.peelregion.ca/articles/2022/census-language-data.asp)) [H].
  - The prior report found no GTA vendor marketing community-language intake for trades or immigration [L].
- **Price:**
  - Prior recommendation: CA$2,500 setup plus CA$997/month.
  - Human bilingual answering anchors this. Ruby runs $250-1,725/month for 50-500 minutes (prior report).
- **Sales cycle:** 2-4 weeks. Regulated buyers (lawyers, RCICs, brokers) ask compliance questions.
- **Newcomer sell difficulty:** 3. The buyer is cautious, but a demo in their own language is a strong hook.
- **Solo feasibility:** 3. Speech recognition, latency and language QA need real testing. ElevenLabs' low-latency Flash model lacks Punjabi, Urdu and Persian (prior report). Build scripts per language once, then reuse.
- **Gross margin:** 65-80%.
- **Retention:** good once trusted. There are few substitutes.
- **Competition:** 2 today. It will rise as Meta's WhatsApp Business Agent (live June 2026) and Clio Grow voice spread (prior report).
- **Fit:** 5.
- **Role:** core offer for diaspora-heavy and regulated segments, and a differentiating upsell to S2.
- **Verdict:** **Shortlist.** It is the most defensible offer, but keep it as a premium tier of S2 rather than a separate product line, so you build one stack.

---

### S4. Growth Site subscription (website plus local SEO and Google Business Profile, "pay monthly")

- **What it is:**
  - A fast Next.js or headless site with service-area pages
  - Call tracking and form tracking
  - Google Business Profile management, local schema and monthly content updates
  - Hosting, security and unlimited small edits
  - A low setup fee and a 12-month minimum
- **Pain and buyer's words:** "My website is from 2016." "My nephew built it." "I don't know if it brings anything."
- **Price evidence:**
  - Canadian managed website subscriptions run CA$200-700/month with no upfront fee; trades-specific CA$250-500/month. One-time small-business custom builds run CA$5,000-12,000; trades with SEO CA$8,000-22,000 ([Marvel Marketing, Apr/Aug 2026](https://marvelmarketing.ca/?p=78537)) [L, seller].
  - Maintenance for typical small-business sites runs $50-500/month (GoDaddy April 2026 via [UENI, Sept 2026](https://ueni.com/blog/website-maintenance-cost/)) [L].
  - Published care plans range from WP Buffs at $84 to SiteCare at $435-2,190/month ([Web Tonic, Oct 2026](https://www.webtonic.io/blog/best-website-maintenance-agencies)) [L].
  - The DIY floor is UENI at $79 plus $24.99/month [L].
- **Budget reality:** of 7,413 UENI signups (mostly micro businesses), 26% plan to spend $0/month on marketing and 90.5% under $200/month ([UENI, Aug 2026](https://ueni.com/blog/small-business-marketing-budget/)) [M, skewed to micro]. This offer only works for firms with 5+ staff.
- **Sales cycle:** 1-4 weeks.
- **Newcomer sell difficulty:** 2. Everyone understands "website."
- **Solo feasibility:** 4. AI-generated copy and a component library cut a build to 1-3 days.
- **Gross margin:** 70-85% after the template exists.
- **Retention:**
  - SEO clients churn about 38% a year; retainer clients about 18% a year, with a 56-month average life; project clients about 42% ([Focus Digital, July/Oct 2026](https://focus-digital.co/?p=6135)) [L, no sample disclosed].
  - The subscription form keeps clients longer than one-off builds.
- **Competition:** 5. It is saturated, and AI builders compress prices.
- **Fit:** 4.
- **Role:** entry or retainer anchor for 1-10 staff firms. It is also the "container" that S2 and S5 plug into.
- **Verdict:** **Keep as an upsell or bundle, not a lead offer.** Never sell a site without call and form tracking, because the tracking is what feeds the S2 report.

---

### S5. AI Visibility and Reviews plan (GEO, Google Business Profile and review engine)

- **What it is:**
  - Monthly monitoring of 20-50 buyer prompts across ChatGPT, Gemini, Perplexity and Google AI Mode
  - Entity and schema fixes and FAQ content
  - Citations and directory consistency
  - An automated review-request flow after each job, plus AI-drafted review replies
  - A monthly visibility scorecard
- **Pain and buyer's words:** "Traffic is down and I don't know why." "Competitor has 400 reviews, we have 40."
- **Price evidence:**
  - AI visibility monitoring runs $500-1,500/month; a full GEO retainer $2,000-5,000/month; an add-on to an SEO retainer $500-1,000 ([LLM Pulse, Oct 2026](https://llmpulse.ai/blog/geo-agency-guide/)) [L, vendor].
  - Review software runs $75-599/month (prior report).
  - **Suggested Verj pricing:** CA$397-797/month.
- **Demand evidence:**
  - Seer Interactive found organic click-through rate fell 61% on queries showing AI Overviews (Sept 2025, via [QuickSEO](https://quickseo.ai/blog/smb-seo-statistics-2026-75-benchmarks-on-budgets-roi-time-to-result-churn-geo)) [M].
  - Branded web mentions correlate with AI Overview visibility at r=0.664, versus 0.218 for backlinks ([Ahrefs](https://ahrefs.com/blog/ai-overview-brand-correlation/)) [M]. Reviews and mentions are the lever.
- **Sales cycle:** 1-3 weeks.
- **Newcomer sell difficulty:** 3. The audit (S1) creates the need, but outcomes are hard to attribute.
- **Solo feasibility:** 4. Monitoring is automatable.
- **Gross margin:** 75-85%.
- **Retention:** medium-low unless the scorecard moves. It is a new category with unproven standards.
- **Competition:** 3 and rising quickly.
- **Fit:** 4.
- **Role:** upsell at months 2-4.
- **Verdict:** **Upsell, not core.** Bundle reviews with it so there is a tangible monthly output.

---

### S6. Local Video Engine (done-for-you short-form video)

- **What it is:** 8-12 reels a month, built from the client's real jobs, team and products. Scripts are in English plus one community language, with captions and scheduling. It uses the internal Remotion/fal/Claude pipeline from the prior report.
- **Pain and buyer's words:** "We should be on Instagram/TikTok but nobody has time."
- **Price evidence (prior report):** done-for-you services run $99-629/month (99 Dollar Social) and $500-1,400/month at agencies. Verj recommended pricing is CA$400-900/month.
- **Sales cycle:** 1-2 weeks as an add-on.
- **Newcomer sell difficulty:** 3.
- **Solo feasibility:** 3. Human review time scales with the number of clients.
- **Gross margin:** 60-75% (prior report).
- **Retention:**
  - Social media retainers churn about 46% a year ([Focus Digital, 2026](https://focus-digital.co/?p=6135)) [L].
  - It churns when no leads are attributed.
- **Competition:** 4.
- **Fit:** 4.
- **Role:** upsell only.
- **Verdict:** **Add-on for 30-40% of S2 clients.** Do not lead with it, and use it heavily for Verj's own marketing.

---

### S7. Ops Automation and CRM ("quote-to-cash and paperwork autopilot")

- **What it is:** a fixed-scope build of 3-5 automations around the client's existing tools, then a monitoring retainer. Typical builds:
  - Quote, follow-up and e-signature, then invoice and payment chase
  - Client document collection and checklists (tax, immigration, mortgage, insurance renewals)
  - CRM setup and cleanup (HubSpot, Pipedrive, Jobber, Clio)
  - Email and inbox triage
  - A weekly owner KPI digest
- **Pain and buyer's words:** "We're drowning in admin." "I re-type the same thing into three systems." "Chasing clients for documents takes all of March."
- **Pain evidence:**
  - Accounting firms run an average of 8 apps for core operations, 66% feel overwhelmed by technology complexity at least weekly, and 64% plan to invest in AI within a year. Average firm tech spend is expected to fall from $24k to $20k a year (Intuit QuickBooks 2025 accountant survey via [Small Business Trends, Aug 2025](https://smallbiztrends.com/accountants-embrace-ai-anticipate-strategic-advisory-boom-amid-challenges/)) [M, sample not disclosed].
  - Property management leaders spend 66% of their time on routine reactive operations. Technology implementation is now a top-3 challenge, and 67% say consolidating data in one platform is key ([NAA/AppFolio, Dec 2025, n=1,984](https://www.appfolio.com/newsroom/technology-implementation-now-a-top-challenge-for-real-estate-leaders)) [M, vendor co-authored].
  - CFIB: only 10% of SMEs are fully digitally integrated (prior report) [H].
- **Price evidence:**
  - Simple workflow $500-2,000; integrated 3-5-tool workflow $2,000-5,000; custom agent or multi-workflow $5,000-15,000.
  - Monitoring retainers: $300-1,500/month for small businesses and $1,500-5,000 for mid-market ([Vantaige, July 2026](https://vantaige.io/blog/2026-ai-automation-rate-card-operators-charge)) [L].
  - HubSpot quick-starts run $1,500-6,000 (prior report).
  - **Suggested Verj pricing:** CA$2,500-7,500 build plus CA$400-1,500/month "Ops Care."
- **Sales cycle:** 2-6 weeks.
- **Newcomer sell difficulty:** 3. It is hard to explain but easy to show. A Loom of their own workflow automated sells it.
- **Solo feasibility:** 4. n8n or custom NestJS workers, plus Claude for document extraction.
- **Gross margin:** 65-80%.
- **Retention:** good when Verj owns monitoring and fixes, since APIs break.
- **Competition:** 3. There are many Zapier freelancers but few engineers who also handle data, security and reporting.
- **Fit:** 5.
- **Role:** core offer and retainer anchor for B2B and professional firms.
- **Verdict:** **Shortlist.** This is the main "second ladder." It suits segments where phones matter less: accountants, property managers, brokers, distributors and staffing.

---

### S8. Custom internal tools, client portals and owner dashboards

- **What it is:** a bespoke web app replacing spreadsheets and email. Examples:
  - Job, dispatch or estimating tool
  - B2B customer ordering and quote portal
  - Tenant or owner portal
  - Broker submission tracker
  - KPI dashboard pulling from QuickBooks, CRM and phone
  - Delivery is fixed-scope phases with hosting and support after launch.
- **Pain and buyer's words:** "Our business runs on a spreadsheet only Maria understands." "Customers call to ask where their order is." "I can't see my numbers until the accountant tells me."
- **Price evidence:**
  - A custom internal tool costs about €8,000-16,500 upfront plus €300-500/month maintenance and hosting, versus Retool at €50/user/month on its Business tier ([TechConcepts, May 2026](https://techconcepts.org/blog/retool-vs-custom-internal-tool)) [L, Madrid market].
  - Power BI: a basic dashboard costs $1,500-15,000, a multi-source build $25,000-50,000, and managed reporting $3,000-10,000/month ([Perceptive Analytics, 2026, New York](https://www.perceptive-analytics.com/how-much-does-power-bi-consulting-cost-in-2026-in-new-york/)) [L].
  - B2B demand: 45% of procurement buyers are dissatisfied with their distributors' online experience, and only 33% can reorder in one click ([MDM on B2B Online/OroCommerce survey, 2025](https://www.mdm.com/article/blog/what-the-latest-b2b-buyer-data-says-about-digital-distribution-in-2025/)) [M].
  - **Suggested Verj pricing:** CA$12,000-45,000 per project plus CA$500-2,000/month care.
- **Sales cycle:** 1-3 months.
- **Newcomer sell difficulty:** 4. It needs trust, references and a scoping workshop.
- **Solo feasibility:** 3. AI coding agents make it feasible, but scope control is essential. Run no more than 1-2 builds at a time.
- **Gross margin:** 60-75%.
- **Retention:** very sticky. Care plans rarely churn while the app is in daily use.
- **Competition:** 2 locally. Offshore shops compete on price, not accountability.
- **Fit:** 5.
- **Role:** high-ticket core, which feeds care-plan MRR.
- **Verdict:** **Shortlist, merged with S9 as a "Systems" track.** Sell it through referrals (accountants, associations) and the S7 audit, not cold outreach.

---

### S9. Legacy modernization (Access, Excel VBA, FoxPro or old desktop apps to a secure web app)

- **What it is:** a fixed-phase migration with data migration, parallel run and training, then hosting and a support plan. The founder already has a FoxPro school-finance case.
- **Pain and buyer's words:** "The guy who built it retired." "It only runs on one PC." "We're scared it will break at year-end."
- **Price evidence (USD, 2026, written for the Toronto market by an agency):**

  | Starting point | Price | Timeline |
  |---|---|---|
  | Excel VBA workbook | $9,000-16,500 | 6-8 weeks |
  | Simple Access database | $16,500-27,500 | 2-3 months |
  | Mid-size Access database | $27,500-38,500 | 3-4 months |
  | Complex Access database | $38,500-50,000 | 4-5 months |

  Ongoing costs are hosting at $55-220/month plus 10-15% of the project budget per year ([Kolonell, Oct 2026](https://kolonell.com/en/blog/replace-legacy-access-database-web-app-toronto-2026)) [L, seller].
- **Funding hooks:**
  - IRAP and SR&ED for custom development, and NGen for manufacturers (prior report).
  - About 60% of Canadian manufacturers are unsure where to start with digital adoption training, and about 5% use AI in production versus about 1 in 4 in the US ([Toronto Region Board of Trade, Nov 2025](https://bot.com/News/Survive-and-Thrive-Manufacturing-in-the-Age-of-Tariffs)) [L, figures unsourced in the recap].
- **Sales cycle:** 1-4 months.
- **Newcomer sell difficulty:** 4 to find buyers, but close rates are high once found.
- **Solo feasibility:** 3. AI is excellent at reading legacy code and schemas.
- **Gross margin:** 60-75%.
- **Retention:** very sticky.
- **Competition:** 1.
- **Fit:** 5.
- **Role:** high-ticket core that feeds care-plan MRR.
- **Verdict:** **Keep in the Systems track.** Market it with one page and the FoxPro case study, and source it from accountants, ERP resellers, school networks and manufacturers' associations. It is lumpy, so don't make it the MRR engine.

---

### S10. Shopify and B2B commerce (headless builds, wholesale portals, growth retainer)

- **What it is:**
  - Shopify or headless storefront builds and speed and conversion fixes
  - Shopify B2B and wholesale ordering
  - ERP and 3PL integrations
  - A monthly growth and ops retainer
- **Pain and buyer's words:** "Our site is slow and conversion dropped." "Wholesale orders come by email." "US shipping got complicated."
- **Price evidence:**
  - New builds $8-20k, redesigns $15-40k, retainers $2-5k/month for small stores (prior report, Tenten 2026).
  - Canadian standard Shopify builds run CA$5,000-15,000 ([Marvel Marketing, 2026](https://marvelmarketing.ca/?p=78537)) [L].
- **Market:**
  - There are 170,307 active Canadian Shopify stores, 3,853 of them on Plus, and at least 19,201 in Toronto (Storeleads via [EightX, June 2026](https://eightx.co/blog/canada-shopify-landscape-2026)) [M].
  - The US de minimis exemption ended 2025-08-29. Some Canadian DTC brands stopped US shipping or absorbed 25-30% higher shipping fees ([CBC, Aug 2025](https://www.cbc.ca/lite/story/1.7618234)) [M]. This is a pain trigger, but it also squeezes budgets.
- **Sales cycle:** 2-6 weeks.
- **Newcomer sell difficulty:** 4. Brands want a portfolio.
- **Solo feasibility:** 3.
- **Gross margin:** 55-70%.
- **Retention:** medium.
- **Competition:** 5.
- **Fit:** 4.
- **Role:** project revenue, plus a B2B portal angle that overlaps S8.
- **Verdict:** **Opportunistic only.** The best variant is B2B and wholesale portals for distributors, which belongs in S8, not DTC brand work.

---

### Considered and cut

| Candidate | Why it was cut |
|---|---|
| Paid ads management | High churn, about 49% a year for PPC ([Focus Digital](https://focus-digital.co/?p=6135)) [L], and buyers want case studies first |
| Standalone SEO | Saturated, slow and distrusted (prior report) |
| AI training and adoption sprints | The Canada-Ontario Job Grant is **paused** ([Ontario.ca](https://www.ontario.ca/page/canada-ontario-job-grant-cojg)) [H]. Private team workshops start around CA$12,500 ([GetClear](https://getclear.ca/ai-training-canadian-small-businesses)) [L]. Better used as a free webinar for lead generation |
| OCI DMAP plans | Digital Adoption Consultants must be vendor-neutral and **cannot be the vendor** on the related project ([OCI DMAP requirements, Apr 2026](https://www.oc-innovation.ca/wp-content/uploads/2026/06/DAC-DMAP-Requirements-April-2026.pdf)) [H]. This corrects the prior report's suggestion |
| Fractional CTO | Startup-oriented, US$4-25k/month ([A.Team, June 2026](https://www.a.team/talent/guides/fractional-cto-rates)) [L]. Not SMB-friendly |
| Managed IT (MSP) | CA$100-300/user/month ([F12, Aug 2026](https://f12.net/how-much-do-managed-it-services-cost/)) [L]. It is a different business with 24/7 liability. Partner with an MSP instead |
| Google Ad Grants management | Canadian registered charities are eligible for up to US$10k/month in ad grants ([Charity Law Group, Oct 2026](https://www.charitylawgroup.ca/charity-law-questions/can-google-ads-grants-help-your-canadian-charity-or-nonprofit)) [M]. Agencies charge $400-1,750/month ([REACHRIGHT, Oct 2026](https://www.reachrightstudios.com/blog/google-ad-grant-management-cost)) [L]. Keep it as a **niche add-on** for the charity and faith segment only |
| Chatbots alone | Commoditized (prior report) |

---

### Comparison table

Columns are converted so that **higher always means better for Verj**:
- **Ease** = 6 minus sell difficulty
- **Low comp** = 6 minus competition
- **Recur** = recurring potential
- **Ticket** = deal size
- **Volume** = how many buyers you can find each month

Maximum total is 35. The scores are my judgment, informed by the evidence above.

| # | Service | Ease | Solo | Low comp | Fit | Recur | Ticket | Volume | **Total** | Role |
|---|---|---|---|---|---|---|---|---|---|---|
| S2 | Missed-Lead Recovery | 4 | 4 | 2 | 5 | 4 | 3 | 5 | **27** | Core / retainer |
| S7 | Ops Automation and CRM | 3 | 4 | 3 | 5 | 4 | 4 | 4 | **27** | Core / retainer |
| S8 | Custom tools / portals / dashboards | 2 | 3 | 4 | 5 | 4 | 5 | 3 | **26** | High-ticket core |
| S1 | Lead-Leak and AI Visibility Audit | 5 | 5 | 3 | 5 | 1 | 1 | 5 | **25** | Entry |
| S3 | Multilingual Intake Desk | 3 | 3 | 4 | 5 | 4 | 3 | 3 | **25** | Core (premium tier) |
| S9 | Legacy modernization | 2 | 3 | 5 | 5 | 4 | 5 | 1 | **25** | High-ticket |
| S4 | Growth Site subscription | 4 | 4 | 1 | 4 | 4 | 2 | 5 | **24** | Entry / bundle |
| S5 | AI Visibility and Reviews | 3 | 4 | 3 | 4 | 3 | 2 | 5 | **24** | Upsell |
| S6 | Local Video Engine | 3 | 3 | 2 | 4 | 3 | 2 | 4 | **21** | Upsell |
| S10 | Shopify / B2B commerce | 2 | 3 | 1 | 4 | 3 | 4 | 3 | **20** | Opportunistic project |

Price summary (CA$, my recommended Verj pricing, informed by the sources above):

| Service | Setup / one-off | Monthly |
|---|---|---|
| S1 Audit | Free mini / $497 full / $750-1,500 ops audit | n/a |
| S2 Missed-Lead | $1,500-2,500 | $497-997 |
| S3 Multilingual | $2,500-3,500 | $997-1,500 |
| S4 Growth Site | $0-1,500 | $297-597 (12-month term) |
| S5 Visibility and Reviews | $0-500 | $397-797 |
| S6 Video | $0-500 | $400-900 |
| S7 Ops Automation | $2,500-7,500 | $400-1,500 |
| S8 Custom tools | $12,000-45,000 | $500-2,000 care |
| S9 Legacy | $15,000-60,000 | $500-2,000 care |
| S10 Shopify / B2B | $8,000-30,000 | $1,000-3,000 |

### The ladders

**Ladder A, Front-of-house (local service firms: trades, brokers, small law, property managers)**

| Step | Offer | Price (CA$) |
|---|---|---|
| Entry | S1 Lead-Leak Audit | Free mini, or $497 credited |
| Core | S2 Missed-Lead Recovery; S3 multilingual tier where relevant | $1,997 + $697/month, or $2,997 + $1,197/month multilingual |
| Upsell, months 2-4 | S5 Visibility and Reviews and/or S4 Growth Site, then S6 Video | +$400-900/month |
| Target account size | | $1,200-2,000/month |

**Ladder B, Back-office (accountants, property managers, brokers, distributors, manufacturers, staffing)**

| Step | Offer | Price (CA$) |
|---|---|---|
| Entry | S1 "Ops Bottleneck Audit," 2-hour workshop plus report | $750-1,500, credited |
| Core | S7 Ops Automation (3-5 automations) | $2,500-7,500 + $500-1,500/month Ops Care |
| Upsell | S8 portal or dashboard, or S9 modernization | $12-60k + $500-2,000/month care |
| Target account size | | $1,000-3,000/month, plus project cash |

**MRR math (estimate):** 20 Ladder A clients at CA$1,300 is about $26k. 12 Ladder B clients at CA$1,300 is about $15.6k. 6 Systems care plans at CA$1,400 is about $8.4k. That totals about **$50k MRR**, plus $60-150k a year in project fees. That is 38 accounts, close to the prior report's Path B count but with a less fragile mix.

### Shortlist of five (first 6 months)

1. **S1 Audit.** It is the cheapest way to start conversations and is reusable across both ladders.
2. **S2 Missed-Lead Recovery.** It has the largest pool of buyers who already spend on leads.
3. **S3 Multilingual tier.** This is the moat and the reason a GTA buyer picks Verj over a $49 SaaS tool.
4. **S7 Ops Automation.** It uses Verj's engineering strength, faces less competition, and opens B2B firms where phone answering doesn't matter.
5. **S8+S9 Systems track.** It brings high-ticket cash and very sticky care plans, sourced through referrals in parallel and capped at one build at a time.

S4, S5 and S6 are add-ons. S10 is opportunistic.

---

# DELIVERABLE 2: Ideal customer longlist (29 segments)

**Ontario establishment counts** are from ISED Canadian Industry Statistics (2025 data, Statistics Canada Business Register) [H] unless noted. "5-99" means Ontario employer establishments with 5-99 employees, which is the realistic paying pool.

**Scores:** Reach = how easily a solo founder can reach decision-makers (1-5). Budget = ability to pay CA$500+/month (1-5).

**"Verj budget"** is my estimate of what a typical firm in the segment would pay Verj each month. Decision-maker age, tech comfort and cultural notes are my judgment [L] and should be validated in interviews.

## A. Home and property services

**1. HVAC, plumbing and electrical contractors (5-30 staff)**
- **Decision-maker:** Owner-operator, 35-60, phone-first, moderate tech comfort. Many Peel and York owners are South Asian, Italian, Portuguese or Chinese Canadian.
- **Size:** 5-30 staff; CA$1-8M revenue.
- **Pains:** missed calls during jobs and after hours; slow follow-up on paid leads; technician time wasted on admin.
- **Current spend:**
  - Google Ads and LSA, HomeStars, and Jobber or Housecall Pro.
  - Contractors spending 12%+ of revenue on marketing report +9% net profit, versus +5% for those spending less ([ACCA/Farmington 2025 Contractor of the Future study, Dec 2025](https://www.phcppros.com/articles/22596-acca-and-farmington-consulting-group-release-2025-contractor-of-the-future-study-results)) [M].
- **Reach via:** HRAI, supplier counters (wholesale branches), HomeStars listings, Google Maps, local trade Facebook groups, the CMPX trade show (Toronto, biennial; verify 2028 dates).
- **Buying trigger:** heating or cooling season peaks; a new technician hire; a bad month of missed calls.
  - Ontario's Home Renovation Savings program (Enbridge/IESO) runs a participating HVAC contractor list. 2026 applications closed May 31 ([Mechanical Business, May 2026](https://mechanicalbusiness.com/2026/05/05/apply-now-to-be-added-to-the-home-renovation-savings-program-contractor-list/)) [M]. Rebate-driven demand creates enquiry spikes.
- **Objections:** "Jobber already has a receptionist." "AI sounds robotic." "Tried an agency, wasted money."
- **Best services:** S2 → S5 → S4.
- **Verj budget:** CA$600-1,500/month.
- **Ontario count:** 13,218 employer establishments; 5,126 with 5-99 staff ([ISED 2382](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/2382)).
- **Reach 4, Budget 4.**

**2. Roofing, siding, foundation and exterior contractors**
- **Decision-maker:** Owner, 30-55, sales-driven.
- **Size:** 5-40 staff, often seasonal; CA$1-10M revenue.
- **Pains:** storm-driven call surges; quote follow-up; reviews.
- **Current spend:** the highest home-service cost per lead (prior report: roofing about $101 per lead).
- **Reach via:** HomeStars, Google Maps, supplier yards, RenoMark.
- **Buying trigger:** spring and storm season.
- **Objections:** seasonality ("pause in winter").
- **Best services:** S2 → S5 → S6 (before/after reels).
- **Verj budget:** CA$600-1,200/month.
- **Ontario count:** 6,988 employer establishments; 2,815 with 5-99 staff ([ISED 2381](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/2381)).
- **Reach 4, Budget 4.**

**3. Renovation and design-build firms (residential)**
- **Decision-maker:** Owner or designer-owner, 35-60.
- **Size:** 3-25 staff; CA$1-6M revenue.
- **Pains:** long sales cycles; unqualified leads; quoting and change-order admin.
- **Current spend:** Houzz, HomeStars, Instagram, websites.
- **Reach via:** RenoMark/BILD, the National Home Show, Houzz, Instagram.
- **Buying trigger:** a pipeline dip.
- **Objections:** "I get work by referral."
- **Best services:** S4 + S6 + S7 (quote-to-contract).
- **Verj budget:** CA$500-1,200/month.
- **Ontario count:** 13,606 residential building establishments; 3,865 with 5-99 staff ([ISED 2361](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/2361)). This includes builders.
- **Caution:** GTA new home sales in 2025 were 5,314 units, 81% below the 10-year average ([UrbanToronto on Altus/BILD, Feb 2026](https://urbantoronto.ca/news/2026/02/industry-updates-market-forecasts-housing-slowdown-and-industry-response.60402)) [M]. Target renovators, not new-build firms.
- **Reach 4, Budget 3.**

**4. Landscaping, hardscaping and snow removal**
- **Decision-maker:** Owner, 30-55.
- **Size:** 5-40 seasonal staff.
- **Pains:** spring quote flood; crew scheduling; recurring-contract renewals.
- **Current spend:** low-to-moderate ads; LMN or Aspire software.
- **Reach via:** Landscape Ontario (2,000+ member companies; its January Congress trade show draws about 12,500 trade visitors) ([Wikipedia/LO](https://en.wikipedia.org/wiki/Landscape_Ontario)) [M].
- **Buying trigger:** February-April.
- **Objections:** cash-tight in winter.
- **Best services:** S2 (spring), S7 (contract renewals).
- **Verj budget:** CA$400-900/month.
- **Ontario count:** part of 10,713 "services to buildings" establishments; 4,626 with 5-99 staff ([ISED 5617](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5617)). That code also includes cleaning and pest control.
- **Reach 4, Budget 3.**

**5. Commercial cleaning, janitorial and pest control**
- **Decision-maker:** Owner or general manager, 35-60. Many are immigrant-owned (Portuguese, Filipino, South Asian, Latin American) [L].
- **Size:** 10-200 staff (labour-heavy).
- **Pains:** winning B2B contracts and bids; staff scheduling and turnover; proving service quality (inspections).
- **Current spend:** low marketing; some software (Swept, Janitorial Manager).
- **Reach via:** BOMA and facility-manager events, ISSA Canada, LinkedIn.
- **Buying trigger:** losing a contract over quality or reporting.
- **Objections:** thin margins.
- **Best services:** S8 (inspection and QA app, client portal), S7.
- **Verj budget:** CA$500-1,500/month.
- **Ontario count:** within the 10,713 above.
- **Reach 3, Budget 3.**

**6. Moving and storage companies**
- **Decision-maker:** Owner, 30-60.
- **Size:** 5-50 staff.
- **Pains:** quote-request speed (customers ask 3-5 movers); review reputation (fraud fears); peak-season call volume.
- **Current spend:** Google Ads and lead marketplaces.
- **Reach via:** Canadian Association of Movers, Google Maps.
- **Buying trigger:** May-September peak.
- **Objections:** price shopping.
- **Best services:** S2 + S5.
- **Verj budget:** CA$400-900/month.
- **Ontario count:** inside 4,854 specialized freight trucking establishments, 839 with 5-99 staff ([ISED 4842](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/4842)). Movers are a subset.
- **Reach 4, Budget 3.**

**7. Specialty installers: security and alarm, low-voltage, solar, EV chargers**
- **Decision-maker:** Owner or sales manager, 30-55, comfortable with technology.
- **Size:** 5-50 staff.
- **Pains:** lead response on high-ticket quotes; service-contract renewals; site-survey scheduling.
- **Current spend:** moderate ads and dealer programs.
- **Reach via:** CANASA, the EV and solar installer networks of incentive programs, LinkedIn.
- **Buying trigger:** new incentive or rebate programs.
- **Objections:** manufacturer lead programs already exist.
- **Best services:** S2, S7.
- **Verj budget:** CA$500-1,200/month.
- **Ontario count:** 1,426 investigation and security employer establishments, 660 with 5-99 staff ([ISED 5616](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5616)). Solar and EV installers sit inside 2382.
- **Reach 3, Budget 3.**

**8. Property managers (residential rental and condo)**
- **Decision-maker:** Owner or principal, 40-65; operations manager.
- **Size:** 5-60 staff, managing 300-5,000 units.
- **Pains:**
  - 24/7 tenant maintenance calls
  - Leasing enquiry follow-up
  - Owner reporting and the "66% of time on reactive work" problem ([NAA/AppFolio, Dec 2025](https://www.appfolio.com/newsroom/technology-implementation-now-a-top-challenge-for-real-estate-leaders)) [M]
- **Current spend:** Yardi, AppFolio or Buildium; answering services.
- **Reach via:** FRPO, ACMO, the CMRAO public register, landlord associations, LinkedIn.
- **Buying trigger:** losing a building contract; a staff turnover spike.
- **Objections:** "Our PM software has AI now."
- **Best services:** S3/S2 (maintenance intake), S7, S8 (owner portal).
- **Verj budget:** CA$800-2,500/month.
- **Ontario count:**
  - 3,563 "activities related to real estate" employer establishments, 1,073 with 5-99 staff (prior report, ISED 5313).
  - 399 licensed condominium management companies and 4,439 licensed condo managers as of March 2024 ([CMRAO Business Plan 2024-25](https://cmrao.ca/wp-content/uploads/2024/04/CMRAO_Business-Plan-2024-2025.pdf)) [H].
- **Reach 4, Budget 4.**

## B. Professional services

**9. Immigration consultants (RCICs)**
- **Decision-maker:** Licensed consultant-owner, 30-55. Often Punjabi, Urdu, Hindi, Mandarin, Tagalog, Arabic or Farsi speaking; WhatsApp-first.
- **Size:** 1-15 staff.
- **Pains:** enquiry volume with low conversion; free-consult time sink; document collection.
- **Current spend:** Facebook and Instagram ads, ethnic media, portals.
- **Reach via:** the CICC public register, CAPIC, community media, WhatsApp groups.
- **Buying trigger:** a new IRCC program draw or pause.
- **Market pressure:** the "volume era" is over. IRCC paused Start-Up Visa intake for 2026 and the caregiver pilots, and study-permit caps cut the student pipeline ([LearnFormula, May 2026](https://learnformula.com/latest-intelligence/the-end-of-the-volume-era-what-applyboards-reckoning-and-irccs-program-pauses-mean-for-rcics)) [L]. Ontario expects 92,000 fewer international students in 2025-26 than in 2023-24, a 36% drop ([CP24 on StatCan, May 2026](https://www.cp24.com/local/toronto/2026/05/06/ontario-to-lose-more-than-a-third-of-international-students-statcan/)) [M].
- **Objections:** price; "I do it on WhatsApp myself"; CICC compliance fears.
- **Best services:** S3 → S7 (document collection) → S5.
- **Verj budget:** CA$400-1,200/month. Solos are lower.
- **Ontario count:** 5,391 RCICs in Ontario (prior report).
- **Reach 5, Budget 2-3.** Downgraded from the prior report's #1 because of budget pressure. Target multi-staff firms only.

**10. Small law firms (immigration, family, real estate, personal injury, employment; 2-15 lawyers)**
- **Decision-maker:** Managing partner, 35-60; office manager or law clerk as gatekeeper.
- **Size:** 2-15 lawyers; CA$1-8M revenue.
- **Pains:** intake responsiveness (the prior report cited a Clio finding that 48% of firms didn't answer or return calls); conflict-check and intake admin; client document collection.
- **Current spend:**
  - Clio or PCLaw; Google Ads with the highest cost per lead of any vertical (prior report: legal median about $132).
  - Clio suggests 2-5% of revenue for marketing, or the SBA's 7-8% ([Clio blog, updated Dec 2024](https://www.clio.com/blog/marketing-budget-for-small-law-firm/)) [L].
- **Reach via:** the LSO directory, OBA sections, the Toronto Lawyers Association, ethnic bar associations (e.g., South Asian and Asian-Canadian lawyers' associations), and legal-tech meetups.
- **Buying trigger:** losing a retainer to a faster firm; an associate leaving.
- **Objections:** LSO confidentiality; "Clio is adding AI."
- **Best services:** S3 → S7 → S8 (client portal).
- **Verj budget:** CA$800-2,000/month.
- **Ontario count:** 3,151 firms with 2-10 lawyers, plus 9,148 sole practitioners (prior report, FLSC).
- **Reach 4, Budget 4.**

**11. Accounting, bookkeeping and tax firms (3-30 staff)**
- **Decision-maker:** CPA-owner or partner, 40-65. Many South Asian and Chinese Canadian owner-led firms in the GTA [L].
- **Size:** 3-30 staff.
- **Pains:** tax-season document chasing; "8 apps" overload, with 66% overwhelmed weekly; staff shortage, with 80% finding it hard to hire experienced staff (Intuit 2025 via [Small Business Trends](https://smallbiztrends.com/accountants-embrace-ai-anticipate-strategic-advisory-boom-amid-challenges/)) [M].
- **Current spend:** about $20k a year on technology (same source).
- **Reach via:** CPA Ontario, QuickBooks ProAdvisor and Xero partner directories, Intuit/CFIB AI tour events ([CFIB events](https://www.cfib-fcei.ca/en/event/intuit-more-with-ai-tour-toronto)).
- **Buying trigger:** January-April season prep; a bad season.
- **Objections:** security and confidentiality; "too busy to implement."
- **Best services:** S7 (client document portal and intake) → S8 dashboards.
- **Verj budget:** CA$600-1,500/month.
- **Bonus:** they are a **referral channel** to their SMB clients.
- **Ontario count:** 8,349 employer establishments; 1,902 with 5-99 staff (prior report, ISED 5412).
- **Reach 4, Budget 4.**

**12. Independent insurance brokerages (P&C, commercial, life; 5-60 staff)**
- **Decision-maker:** Principal or owner, 40-65; operations manager.
- **Size:** 5-60 staff.
- **Pains:** quote-request speed, against digital brokers and comparison tools; renewal and remarketing workload; consolidation pressure, with Ontario brokerages falling from about 1,500 to about 800 while individual brokers exceed 21,000 ([Canadian Underwriter, Dec 2024](https://www.canadianunderwriter.ca/brokers/ribo-ceo-patrick-ballantyne-retiring-talks-self-regulation-ma-and-optionality)) [M].
- **Current spend:** Applied Epic, Power Broker, quoting tools.
- **AI maturity:** Canadian insurance lags on AI and mostly sits at proof-of-concept; distribution is least automated ([Insurance Business, June 2026](https://www.insurancebusinessmag.com/ca/news/technology/canadian-insurance-is-behind-on-ai--but-the-disruption-to-brokers-isnt-waiting-580451.aspx)) [M].
- **Reach via:** IBAO and its conventions, the RIBO register, LinkedIn.
- **Buying trigger:** an acquisition (integration work); losing young clients online.
- **Objections:** RIBO and privacy; vendor lock-in.
- **Best services:** S2/S3 (multilingual quote intake), S7 (renewals), S8.
- **Verj budget:** CA$800-2,500/month.
- **Ontario count:** 4,029 employer establishments, 1,641 with 5-99 staff (prior report, ISED 5242); about 800 RIBO brokerages.
- **Reach 4, Budget 4.**

**13. Mortgage brokerages and teams**
- **Decision-maker:** Principal broker or team lead, 30-55, sales-driven. Many South Asian and Chinese Canadian teams [L].
- **Size:** 3-50 agents.
- **Pains:** lead response; database reactivation; document collection.
- **Current spend:** Velocity, Finmo and Filogix; ads; CRMs.
- **Reach via:** the FSRA register, Mortgage Professionals Canada, CMP events.
- **Buying trigger:** **The 2025-26 renewal wave.** About 60% of outstanding mortgages renew in 2025-26, and about 60% of those renewers face higher payments, with 5-year fixed up 15-20% ([Bank of Canada SAN 2025-21, July 2025](https://www.bankofcanada.ca/2025/07/staff-analytical-note-2025-21/)) [H]. Reactivating the past-client database is the obvious play.
- **Objections:** commission-only cash flow; FSRA compliance (fines reached $875k in 2025 ([Money.ca](https://money.ca/mortgages/homebuying/fsra-doubled-mortgage-broker-sanctions))) [M].
- **Best services:** S2 (database reactivation) → S3 → S7.
- **Verj budget:** CA$500-1,500/month.
- **Ontario count:** 1,561 credit-intermediation employer establishments, 420 with 5-99 staff ([ISED 5223](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5223)). Thousands of individual agents are not counted.
- **Reach 4, Budget 3.**

**14. Real estate teams (top-producing teams only, 5+ agents)**
- **Decision-maker:** Team lead, 30-55.
- **Pains:** lead conversion from portals; database nurture.
- **Current spend:** heavy (CRMs and ads), but saturated with GoHighLevel resellers (prior report).
- **Market:** TRREB forecasts 60-70k 2026 sales, with softer buying intentions ([UrbanToronto, Feb 2026](https://urbantoronto.ca/news/2026/02/industry-updates-market-forecasts-housing-slowdown-and-industry-response.60402)) [M].
- **Best services:** S2, S6.
- **Verj budget:** CA$400-1,000/month.
- **Ontario count:** 6,538 employer establishments, 656 with 5-99 staff (prior report, ISED 5312).
- **Reach 4, Budget 2.**

**15. Architecture, engineering and design consultancies (5-50 staff)**
- **Decision-maker:** Principal, 40-65, analytical.
- **Pains:** proposal and RFP effort; project tracking in spreadsheets; utilization visibility.
- **Current spend:** Deltek or BQE, sometimes custom tools.
- **Reach via:** OAA, OSPE/PEO, Consulting Engineers Ontario, LinkedIn.
- **Buying trigger:** a missed bid deadline; growth past 20 staff.
- **Objections:** "We'll just use Deltek."
- **Best services:** S7 (proposal automation), S8 (project dashboards).
- **Verj budget:** CA$800-2,500/month.
- **Ontario count:** 6,764 employer establishments; 2,379 with 5-99 staff ([ISED 5413](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5413)).
- **Reach 3, Budget 4.**

**16. Staffing and recruitment agencies (light industrial, warehouse, office)**
- **Decision-maker:** Owner or general manager, 30-60. Many Peel agencies are South Asian-owned [L].
- **Size:** 5-50 internal staff.
- **Pains:**
  - Candidate intake at volume, often multilingual
  - Compliance paperwork, since Ontario has required temporary help agency and recruiter licences since 2024 ([DLA Piper, 2023](https://dlapiper.com/en/insights/publications/2023/08/new-licensing-regime-in-ontario-for-recruiters-and-temporary-help-agencies)) [H]
  - Client portals for timesheets
- **Evidence:** staffing firms using AI for screening were 86% more likely to place candidates in under 20 days ([Bullhorn GRID 2025, n=1,500+](https://www.bullhorn.com/grid/2025-industry-trends/)) [M, vendor].
- **Reach via:** ACSESS, the Ontario licence register, LinkedIn.
- **Buying trigger:** a licensing audit; landing a big client.
- **Objections:** margin pressure.
- **Best services:** S3 (candidate intake), S7, S8.
- **Verj budget:** CA$800-2,000/month.
- **Ontario count:** 2,334 employment-services employer establishments; 1,239 with 5-99 staff ([ISED 5613](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5613)).
- **Reach 4, Budget 3.**

**17. Diaspora and immigration-adjacent services (travel agencies, translation, education agents, language and IELTS schools, settlement-related firms)**
- **Decision-maker:** Owner, 30-60, community-embedded, WhatsApp-first.
- **Size:** 2-20 staff.
- **Pains:** enquiries across WhatsApp, phone and Instagram; manual quoting and booking; reputation.
- **Current spend:** low-moderate; ethnic media ads.
- **Reach via:** TICO's register (1,894 registrants, 2025 ([TICO annual report](https://tico.ca/files/2024-2025_Annual_Report_At-a-Glance.pdf))) [H], ATIO (translators), and community chambers and media.
- **Buying trigger:** seasonal travel peaks (Hajj and Umrah, December holidays).
- **Objections:** price; "family runs it."
- **Best services:** S3, S4.
- **Verj budget:** CA$300-800/month.
- **Ontario count:** 5,096 "other professional services" employer establishments (includes translation) ([ISED 5419](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5419)) and 1,894 TICO registrants.
- **Reach 5 (founder's community), Budget 2.**

## C. Trade, logistics and industrial

**18. Trucking fleets (10-100 trucks)**
- **Decision-maker:** Owner or operations manager, 30-55. In Toronto and Vancouver, South Asians are over half the trucking workforce ([Asia Samachar on CTOA, 2023](https://asiasamachar.com/2023/01/26/new-canadian-trucking-powerhouse-is-on-the-move-they-want-to-be-heard/)) [L-M]. Punjabi-first communication is common.
- **Pains:** driver recruiting and onboarding; dispatch and compliance paperwork; broker load communications.
- **Current spend:** TMS and ELD; job boards for drivers.
- **Reach via:** OTA, CTOA, South Asian trucking media, the Truck World show (Toronto, biennial; verify dates).
- **Buying trigger:** driver shortage; an audit failure.
- **Objections:** freight-recession margins; "we use WhatsApp."
- **Best services:** S3 (Punjabi driver-recruiting intake), S7, S8.
- **Verj budget:** CA$500-1,500/month.
- **Ontario count:** 20,565 general freight trucking employer establishments, but only 1,347 have 5-99 staff and 19,165 are micro ([ISED 4841](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/4841)). Target only the roughly 1.3k fleets.
- **Reach 5, Budget 2-3.**

**19. Freight brokers, forwarders and customs brokers**
- **Decision-maker:** Owner or general manager, 35-60, operations-minded, with "AI fatigue" (prior report).
- **Size:** 5-50 staff.
- **Pains:** quoting speed; document and data re-keying; tariff and CARM complexity. CBSA's CARM was fully implemented in May 2025 and ended release-prior-to-payment grace for importers without security ([A&A Customs Brokers, 2025](https://www.aacb.com/blog/navigating-the-tides-top-concerns-for-canadian-importers-and-exporters-in-mid-2025)) [L].
- **Current spend:** TMS (e.g., Descartes), CargoWise.
- **Reach via:** CIFFA, CSCB, TIA, LinkedIn.
- **Buying trigger:** tariff changes driving quote volume.
- **Objections:** integration risk.
- **Best services:** S7 (document extraction to TMS), S8.
- **Verj budget:** CA$1,000-3,000/month.
- **Ontario count:** 1,333 employer establishments, 605 with 5-99 staff (prior report, ISED 4885).
- **Reach 3, Budget 4.**

**20. Importers, wholesalers and distributors (CA$3-50M revenue)**
- **Decision-maker:** Owner, CEO or controller, 40-65. Many family- and immigrant-owned (food, building products, auto parts, apparel) [L].
- **Size:** 10-150 staff.
- **Pains:**
  - Orders by email and phone, with 45% of B2B buyers dissatisfied with distributors' online experience ([MDM, 2025](https://www.mdm.com/article/blog/what-the-latest-b2b-buyer-data-says-about-digital-distribution-in-2025/)) [M]
  - Legacy ERP and spreadsheets
  - Tariff repricing
- **Current spend:** ERP (Sage, Acumatica, legacy), with little marketing.
- **Reach via:** accountants, ERP resellers, sector associations, the Toronto Region Board of Trade, LinkedIn.
- **Buying trigger:** tariffs, a key person retiring, an ERP end-of-life.
- **Objections:** "Too disruptive."
- **Best services:** S8 (B2B portal), S9, S7.
- **Verj budget:** CA$1,500-4,000/month plus projects.
- **Ontario count:** 19,746 wholesale employer establishments; 10,987 with 5-99 staff ([ISED 41](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/41)). Also 1,569 wholesale agents and brokers ([ISED 4191](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/4191)).
- **Reach 2, Budget 5.**

**21. Small manufacturers and job shops (metal fabrication, plastics, food processing)**
- **Decision-maker:** Owner or plant manager, 45-65, practical, spreadsheet-heavy.
- **Size:** 10-150 staff.
- **Pains:**
  - RFQ quoting speed
  - Shop-floor tracking
  - Tariff exposure: about 5% of Canadian manufacturers use AI in production versus about 1 in 4 in the US, and about 60% are unsure where to start ([Toronto Region Board of Trade, Nov 2025](https://bot.com/News/Survive-and-Thrive-Manufacturing-in-the-Age-of-Tariffs)) [L]
- **Current spend:** ERP and MRP (often legacy), with funding available (NGen, IRAP; prior report).
- **Reach via:** CME, EMC, NGen, Halton and Peel manufacturing networks, the ADM Expo (Toronto).
- **Buying trigger:** a tariff hit; funding approval; a retirement.
- **Objections:** "We tried software before."
- **Best services:** S8 (quoting and shop-floor app), S9.
- **Verj budget:** CA$1,500-4,000/month plus projects.
- **Ontario count:** 20,456 manufacturing employer establishments; 11,848 with 5-99 staff ([ISED 31-33](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/31-33)). This includes 3,242 fabricated metal establishments ([ISED 332](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/332)).
- **Reach 2, Budget 5.**

**22. Equipment rental, sign and print shops (local B2B suppliers)**
- **Decision-maker:** Owner, 40-65.
- **Size:** 5-40 staff.
- **Pains:** quote requests; online ordering and file intake; fleet and asset tracking.
- **Current spend:** low-moderate.
- **Reach via:** Canadian Rental Association, sign and print associations, Google Maps.
- **Buying trigger:** competitor launches online ordering.
- **Best services:** S8 (ordering portal), S2.
- **Verj budget:** CA$400-1,200/month.
- **Ontario count:** 747 machinery-rental establishments ([ISED 5324](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5324)) and 1,359 printing establishments ([ISED 3231](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/3231)).
- **Reach 3, Budget 3.**

## D. Education, community and events

**23. Private schools, tutoring centres and driving schools**
- **Decision-maker:** Owner or principal, 35-65. Many are community-founded (Chinese, South Asian, Muslim, Korean) [L].
- **Size:** 5-100 staff.
- **Pains:**
  - Enrolment enquiries and follow-up
  - Fee collection and admin (the founder's FoxPro project is exactly this)
  - The international-student squeeze: private secondary schools targeting international students grew from 48 in 2017 to 174 ([The Conversation via Education News Canada, Sept 2026](https://educationnewscanada.com/article/education/level/k12/3/1216125/the-private-school-market-serving-international-secondary-students-in-ontario-has-grown-.html)) [M], and study-permit caps now hit them
- **Current spend:** moderate ads; school management software.
- **Reach via:** OFIS, CAIS, community networks.
- **Buying trigger:** enrolment drop; admissions season (January-April).
- **Objections:** board approval.
- **Best services:** S2/S3 (admissions), S9 (legacy admin), S8.
- **Verj budget:** CA$600-2,000/month.
- **Ontario count:** 3,632 "other schools" establishments, 2,000 with 5-99 staff (prior report, ISED 6116), plus 826 elementary/secondary employer establishments ([ISED 6111](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/6111)).
- **Reach 4, Budget 3.**

**24. Non-profits, charities and faith/community organizations (mosques, gurdwaras, temples, cultural centres)**
- **Decision-maker:** Executive director or board chair, 40-70, volunteers involved. Committee decisions are slow.
- **Pains:** donations and recurring giving; event and program registration; volunteer and member communication.
- **Current spend:** low cash, but CanadaHelps fees, and Google Ad Grants (up to US$10k/month) are often unused ([Charity Law Group, Oct 2026](https://www.charitylawgroup.ca/charity-law-questions/can-google-ads-grants-help-your-canadian-charity-or-nonprofit)) [M].
- **Reach via:** ONN, Imagine Canada, the founder's community networks, umbrella councils.
- **Buying trigger:** a capital campaign; Ramadan or festival season.
- **Objections:** budget and committee approvals.
- **Best services:** S4 (donation site) plus Ad Grants management, S7.
- **Verj budget:** CA$200-800/month.
- **Ontario count:** about 64,000 nonprofits, including about 30,000 charities ([ONN, July 2026](https://theonn.ca/2026/07/whats-in-the-numbers-the-nonprofit-impact-story/)) [H]; 5,503 religious-organization employer establishments ([ISED 8131](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/8131)).
- **Reach 5, Budget 2.** Good for goodwill and referrals, weak for MRR.

**25. Banquet halls, event venues, caterers and wedding vendors (especially South Asian weddings in Peel)**
- **Decision-maker:** Owner or family, 35-60.
- **Pains:** inquiry volume across Instagram and WhatsApp; slow quoting; booking calendar and deposits.
- **Current spend:** Instagram, bridal shows, wedding directories.
- **Reach via:** bridal expos, Instagram, community media.
- **Buying trigger:** pre-season (fall and winter bookings for summer).
- **Objections:** "Family handles bookings."
- **Best services:** S3, S6, S7.
- **Verj budget:** CA$400-1,200/month.
- **Ontario count:** 1,654 special-food-services establishments (caterers), 929 with 5-99 staff ([ISED 7223](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/7223)). Venue counts are not available. GTA South Asian-specialist halls number at least several dozen ([EventSource listicle](https://www.eventsource.ca/blog/25-beautiful-banquet-halls-that-specialize-in-south-asian-weddings)) [L].
- **Reach 4, Budget 3.**

**26. Independent funeral homes**
- **Decision-maker:** Owner or funeral director, 45-70, conservative.
- **Pains:** 24/7 first calls; pre-planning leads; competing with consolidators. The Bereavement Authority of Ontario cites "industry consolidation" ([BAO business plan 2024-25](https://thebao.ca/wp-content/uploads/2024/09/BAO_2024_25BusinessPlan.pdf)) [H].
- **Current spend:** low-moderate.
- **Reach via:** OFSA and the BAO register.
- **Buying trigger:** succession or new competition.
- **Objections:** tradition.
- **Best services:** S3 (multilingual first-call line), S4.
- **Verj budget:** CA$400-900/month.
- **Ontario count:** 491 employer establishments ([ISED 8122](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/8122)).
- **Reach 3, Budget 3.**

## E. Commerce, franchise and auto

**27. Ecommerce and Shopify brands (CA$1-20M revenue)**
- **Decision-maker:** Founder or ecommerce manager, 28-45, tech-comfortable.
- **Pains:** conversion and speed; wholesale or B2B channel; US cross-border after de minimis ended ([CBC, Aug 2025](https://www.cbc.ca/lite/story/1.7618234)) [M].
- **Current spend:** high on apps and ads; Klaviyo on 12.7% of Canadian stores ([EightX, 2026](https://eightx.co/blog/canada-shopify-landscape-2026)) [M].
- **Reach via:** Storeleads lists, Shopify meetups, LinkedIn.
- **Buying trigger:** replatforming; a wholesale push.
- **Objections:** portfolio and price; many agencies.
- **Best services:** S10, S6, S8.
- **Verj budget:** CA$1,000-3,000/month.
- **Count:** 170,307 Canadian Shopify stores; 19,201+ in Toronto.
- **Reach 3, Budget 3.**

**28. Multi-unit franchisees (3+ locations: home services, QSR excluded, fitness excluded, education, automotive service)**
- **Decision-maker:** Multi-unit owner, 35-60. Franchising is a common newcomer path (Retail Insider) [L].
- **Pains:** local lead handling across units; reporting across stores; franchisor-approved tools only.
- **Reach via:** CFA, the Franchise Show, franchisee associations.
- **Buying trigger:** opening unit #3+.
- **Objections:** franchisor restrictions (a big risk).
- **Best services:** S2, S8 (multi-store dashboards).
- **Verj budget:** CA$800-2,000/month.
- **Count:** about 70,900 franchise establishments in Canada projected by 2027, across 1,100+ brands, with Ontario leading expansion ([Retail Insider on CFA outlook, June 2026](https://retail-insider.com/retail-insider/2026/06/canadian-franchise-association-celebrating-special-day-to-honour-the-industry/)) [M].
- **Reach 3, Budget 3.**

**29. Independent auto repair and collision centres (via DealrDash relationships)**
- **Decision-maker:** Owner, 35-60.
- **Pains:** phone overload while wrenching; estimate follow-up; reviews.
- **Reach via:** the DealrDash network, AIA Canada, CCIF.
- **Best services:** S2, S5.
- **Verj budget:** CA$400-800/month.
- **Ontario count:** 8,889 establishments, 3,777 with 5-99 staff (prior report).
- **Reach 4, Budget 2-3.** Per the founder's own experience with dealerships, treat this as a **secondary channel only**. Evidence of strong budgets here is weak, and I found none for a high-budget dealer sub-segment.

---

## Ranked top 12 segments

Ranking weights: budget, reachability, measurable pain, fit with the shortlisted services, and market headwinds (my judgment).

| Rank | Segment | Ladder | Why |
|---|---|---|---|
| 1 | HVAC / plumbing / electrical (5-30 staff, not ServiceTitan) | A | Largest pool (5.1k with 5-99 staff). Already pays $50-100+ per lead. Measurable missed-call pain. Rebate-driven demand spikes |
| 2 | Small law firms (2-15 lawyers) | A+B | Highest lead value. Documented responsiveness failure. Multilingual edge. Clio voice is US-only for now |
| 3 | Independent insurance brokerages | A+B | Strong budgets. Consolidation and digital competitors force modernization. Low AI maturity |
| 4 | Property managers (residential and condo) | A+B | 24/7 intake, ops overload and owner reporting. A good fit for both ladders |
| 5 | Accounting and tax firms | B | Reliable tech spend (about $20k/year). Clear seasonal trigger. Doubles as a **referral channel** |
| 6 | Mortgage brokerages and teams | A | Renewal-wave trigger (about 60% of mortgages renew in 2025-26). Database reactivation is easy to prove |
| 7 | Roofing / exterior / renovation | A | High cost per lead and visual work (video upsell). Renovators only, not new build |
| 8 | Distributors and wholesalers | B | Highest budget. B2B portal pain is real. Slow, referral-led |
| 9 | Small manufacturers | B | Funding plus tariff triggers. Legacy systems. Slow, referral-led |
| 10 | Staffing agencies | A+B | Multilingual intake plus licensing compliance plus portals |
| 11 | Immigration consultants (multi-staff firms only) | A | Best multilingual fit, but budget pressure from IRCC cuts |
| 12 | Private schools / tutoring | A+B | Enrolment pressure plus a legacy-admin case study the founder already has |

Strong next: freight and customs brokers (#13), A&E firms (#14), funeral homes (#15), banquet halls (#16).

## Service-to-segment mapping

Legend: ● = primary fit, ○ = secondary, blank = not recommended.

| Segment | S1 Audit | S2 Missed-Lead | S3 Multilingual | S4 Site | S5 Visibility | S6 Video | S7 Ops | S8 Tools | S9 Legacy | S10 Commerce |
|---|---|---|---|---|---|---|---|---|---|---|
| HVAC / plumbing / electrical | ● | ● | ○ | ○ | ● | ○ | ○ | | | |
| Roofing / renovation | ● | ● | ○ | ○ | ● | ● | ○ | | | |
| Landscaping / cleaning / moving | ● | ● | | ○ | ○ | | ○ | ○ | | |
| Property managers | ● | ● | ● | | | | ● | ● | ○ | |
| Small law | ● | ○ | ● | ○ | ● | | ● | ○ | | |
| RCICs | ● | ○ | ● | ○ | ○ | ○ | ● | | | |
| Accounting / tax | ● | | ○ | | ○ | | ● | ● | ○ | |
| Insurance brokers | ● | ● | ● | | ○ | | ● | ○ | | |
| Mortgage brokers | ● | ● | ● | | ○ | ○ | ● | | | |
| Staffing agencies | ○ | | ● | | | | ● | ● | | |
| Freight / customs brokers | ○ | | | | | | ● | ● | ○ | |
| Distributors / wholesalers | ○ | | | | | | ● | ● | ● | ○ |
| Manufacturers | ○ | | | | | | ● | ● | ● | |
| Private schools / tutoring | ● | ● | ● | ○ | ○ | ○ | ○ | ○ | ● | |
| Non-profits / faith orgs | ○ | | ○ | ● | ○ | ○ | ○ | | | |
| Banquet / events | ● | ○ | ● | ○ | ○ | ● | ○ | | | |
| Shopify brands | | | | | ○ | ● | ○ | ● | | ● |

## Segments to avoid, and why

| Segment | Reason |
|---|---|
| **All healthcare and clinics** (dental, med spa, physio, chiro, optometry, pharmacy, allied and mental health, home care) | Founder's contract conflict. Excluded entirely |
| **Restaurants, cafes, QSR franchisees** | 1.5-1.8% AI adoption and thin margins (prior report). The 27,703 Ontario restaurants are not worth the churn |
| **Salons, barbers, spas** | 8,221 Ontario employer establishments plus 17,000 non-employer ([ISED 8121](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/8121)). Mostly micro, with low budgets and DIY booking apps |
| **Gyms and fitness studios** | 3,910 establishments ([ISED 7139](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/7139)). Franchise-controlled tech and price-sensitive owners |
| **Child care operators** | 4,010 employer establishments ([ISED 6244](https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/6244)). Under the federal-provincial fee-reduction program many are fee-capped with waitlists, so marketing need is low (my assessment, low confidence) |
| **Solo realtors and solo mortgage agents** | Low and volatile income; GoHighLevel saturation |
| **New-build construction subcontractors** (framing, drywall for builders) | GTA new home sales 81% below the 10-year average; up to 100k construction jobs at risk ([UrbanToronto, 2026](https://urbantoronto.ca/news/2026/02/industry-updates-market-forecasts-housing-slowdown-and-industry-response.60402)) |
| **Owner-operator truckers and micro trucking** | 19,165 micro establishments with no budget. Target only the roughly 1,347 fleets |
| **Car dealerships and jewelers** | Founder experience shows low budgets. No contrary evidence found. Serve them via DealrDash and Studio only |
| **Solo RCICs with no staff** | Budget pressure from IRCC cuts |

---

## Persona-building kit

### Data to collect for each persona

- **Firmographics:** staff, revenue band, locations, years in business, ownership (family, immigrant, partner)
- **The money map:** average job or client value, monthly lead volume, close rate, marketing spend and channels, current software stack and monthly cost
- **The leak map:** where enquiries go unanswered (phone, form, WhatsApp, DMs), after-hours volume, response time, languages customers prefer
- **The admin map:** top 3 repetitive tasks, hours per week, who does them, which tools are re-keyed
- **Buying behaviour:** who signs, who influences, past agency or vendor experience, preferred contract (monthly vs annual), payment method
- **Channels:** associations, events, groups, media they consume, who they trust for advice (accountant, supplier, peers)
- **Trigger events and seasonality:** when they buy and when they freeze spend
- **Compliance concerns:** PIPEDA, the regulator (LSO, CICC, RIBO, FSRA, CMRAO), call recording
- **Words they use:** verbatim phrases for the landing page

### Validation interview questions (choose up to 10 per persona)

1. Walk me through what happens from the moment a new enquiry arrives until you're paid. Where does it stall or get lost?
2. Roughly how many enquiries come in per week, and how many went unanswered or weren't followed up last month? How do you know?
3. What's a typical job or client worth to you, and how many of every 10 enquiries do you win?
4. What do you spend per month on marketing, leads and software? Which of those do you resent paying for?
5. Tell me about the last agency, freelancer or software you hired. Why did it end, or why do you keep it?
6. What languages do your customers prefer? Have you lost business over language or after-hours availability?
7. Which admin task eats the most hours each week, and who does it? What happens when that person is away?
8. If you could fix one thing in the next 90 days, what would it be worth to you in dollars?
9. Who else is involved in approving a CA$500+/month or CA$5,000+ one-off spend, and how do you usually pay?
10. Where do you go for business advice or recommendations: association, accountant, supplier, WhatsApp/Facebook group, peers?

Segment swaps:
- **Law, RCIC, broker:** replace Q6 with "What does your regulator or insurer require about client communications and recording?"
- **Distributor, manufacturer:** replace Q2 with "How do orders and quotes arrive today, and how many are re-keyed?"
- **Property manager:** replace Q2 with "How many after-hours maintenance calls a month, and who answers them?"

### Persona document template (one page each)

```
PERSONA: [Name, e.g., "Harjit, HVAC owner, Brampton"]
Segment / NAICS:            Size (staff, revenue):        Location:
Decision-maker:  title, age, background, language(s), tech comfort (1-5)
Day in the life (3 lines):
Top 3 pains (in their words):
  1. "…"  2. "…"  3. "…"
Money map: avg job value | leads/month | close rate | marketing spend | software spend
Leak map: missed calls/forms % | after-hours share | response time | languages
Current tools/vendors (and sentiment):
Buying trigger(s) and season:
Objections, and our answer to each:
Best-fit offer + price point:          Expected MRR:     Upsell path:
Where to find 50 more like them (lists, associations, groups, events):
Proof they need to see (demo, case study, guarantee, compliance doc):
Validation status: # interviews | key quotes | confidence (L/M/H)
```

---

# COMBINED RECOMMENDATION: what to test first

### The test matrix (90 days)

| | **S1 Audit (entry)** | **S2 + S3 Lead Recovery, multilingual tier (core)** | **S7 Ops Automation (core)** |
|---|---|---|---|
| HVAC / plumbing / electrical | ✔ | ✔ | |
| Small law firms | ✔ | ✔ (S3 tier) | ✔ (intake and documents) |
| Insurance brokerages | ✔ | ✔ | ✔ (renewals) |
| Property managers | ✔ | ✔ (maintenance line) | ✔ |
| Accounting / tax firms | ✔ (Ops Audit) | | ✔ (document collection, before the Jan-Apr season) |
| Mortgage brokerages | ✔ | ✔ (database reactivation) | ○ |
| Roofing / renovation | ✔ | ✔ | |

- **The Systems track (S8/S9)** runs in parallel through referrals only: accountants, ERP resellers, school and manufacturer networks. Cap it at one build at a time.
- **Volume and success criteria:** 40 audits per month across these seven segments. After 90 days, rank the segments by audit-to-paid conversion and by average MRR, keep the top 3, and drop the rest.

### What the "customer-attracting machine" landing page should say

**Headline idea:** *"Every call, form and message answered in under 60 seconds, in your customer's language, and a monthly report showing the dollars it recovered."*

**Second track:** *"Stop re-typing your business. We automate the admin between your tools and give you one dashboard."*

**What it must prove** (each item is a page element):

1. **A live demo phone number** with buttons: "Call in English / ਪੰਜਾਬੀ / اردو / 中文 / Tagalog." This proves quality in 30 seconds and is the main differentiator against $49 SaaS.
2. **"Get your free Lead-Leak Report"** form. Show a real redacted sample (secret-shop recording, form response time, AI-answer screenshot). This proves you find problems they didn't know about.
3. **Recovered-revenue calculator:** missed calls × close rate × job value. This proves the ROI is about their numbers, not about "AI."
4. **Case studies with numbers**, one per segment as soon as pilots finish, for example "Recovered 11 jobs / CA$18,400 in 30 days." Until then, show the founder's FoxPro modernization story as engineering proof.
5. **A "You own it" and privacy page:**
   - Your number and data stay yours
   - Canadian data residency option
   - Recording disclosure aligned with OPC guidance (Oct 2026)
   - CASL-safe follow-up
   - Intake-only scripts for regulated professions
   - This proves trust to lawyers, brokers and RCICs.
6. **Transparent pricing:** "From CA$497 audit; systems from CA$1,997 + CA$697/month; no long contracts." Visible prices filter out tire-kickers and set the price anchor. Ruby-style human answering at CA$1,000+ makes it look cheap.
7. **Guarantee:** "If it doesn't recover at least X leads in 30 days, we refund the setup."
8. **Local and human:** the founder's face, "Milton/GTA, on-site setup," calendar booking, and WhatsApp contact.
9. **Segment landing pages:**
   - /hvac
   - /law
   - /insurance
   - /property-management
   - /accountants
   - /mortgage

   Each uses that segment's words from the persona interviews and its own demo script.

**What it should not say:** "AI agency," "AI receptionist" as the headline, "10x your business," or generic stock imagery.

---

## Memory-worthy notes for the main session

- Corrections to the prior plan:
  - OCI DMAP consultants must be vendor-neutral and cannot implement their own plan.
  - The Canada-Ontario Job Grant is paused (Oct 2026).
- Immigration consultants were downgraded (budget squeeze from IRCC cuts). Accounting firms, insurance brokerages and property managers were upgraded, and a B2B "Ops Automation" ladder was added alongside the lead-recovery ladder.
- Shortlisted services: S1 Audit, S2 Missed-Lead, S3 Multilingual tier, S7 Ops Automation, and an S8/S9 Systems track (referral-only).

---

## Sources

**Service pricing and agency economics**
- Vantaige, 2026 AI automation rate card (July 2026): https://vantaige.io/blog/2026-ai-automation-rate-card-operators-charge
- LLM Pulse, GEO agency guide and pricing (Oct 2026): https://llmpulse.ai/blog/geo-agency-guide/
- Marvel Marketing, website design cost guide Canada (Apr/Aug 2026): https://marvelmarketing.ca/?p=78537
- UENI, website maintenance cost (Sept 2026): https://ueni.com/blog/website-maintenance-cost/
- UENI, small business marketing budget 2026 (Aug 2026): https://ueni.com/blog/small-business-marketing-budget/
- Web Tonic, website maintenance agencies priced (Oct 2026): https://www.webtonic.io/blog/best-website-maintenance-agencies
- Kolonell, replacing Access with a web app, Toronto (Oct 2026): https://kolonell.com/en/blog/replace-legacy-access-database-web-app-toronto-2026
- TechConcepts, Retool vs custom internal tool (May 2026): https://techconcepts.org/blog/retool-vs-custom-internal-tool
- Perceptive Analytics, Power BI consulting cost NY (2026): https://www.perceptive-analytics.com/how-much-does-power-bi-consulting-cost-in-2026-in-new-york/
- A.Team, fractional CTO rates (June 2026): https://www.a.team/talent/guides/fractional-cto-rates
- Groovy Web, fractional AI CTO cost (Sept 2026): https://www.groovyweb.co/blog/fractional-ai-cto-cost-usa-2026
- GetClear, AI training for Canadian small businesses: https://getclear.ca/ai-training-canadian-small-businesses
- F12, managed IT services cost Canada (Aug 2026): https://f12.net/how-much-do-managed-it-services-cost/
- REACHRIGHT, Google Ad Grant management cost (Oct 2026): https://www.reachrightstudios.com/blog/google-ad-grant-management-cost
- PricingSaaS, Jobber 2026 price changes (July 2026): https://pricingsaas.com/companies/jobber/diffs/2026Q2
- Focus Digital, average marketing agency churn (July/Oct 2026): https://focus-digital.co/?p=6135
- CallRail 2026 Agency Marketing Outlook (survey Oct 2025): https://cdn.mediavalet.com/usva/callrail/XgWRrshJhEWNQhju4is74g/GRI6z_RpNEOURtImvC_eQA/Original/CallRail_2026%20Agency%20Marketing%20Outlook%20Report.pdf
- SparkToro, state of digital agencies (Jan 2025): https://sparktoro.com/blog/the-state-of-digital-agencies-in-2024-client-referrals-drive-agency-new-business-but-is-it-enough-and
- QuickSEO, SMB SEO statistics 2026 (compilation): https://quickseo.ai/blog/smb-seo-statistics-2026-75-benchmarks-on-budgets-roi-time-to-result-churn-geo
- Ahrefs, AI Overview brand correlation: https://ahrefs.com/blog/ai-overview-brand-correlation/
- BrightLocal, LCRS 2026 AI trust report (Mar 2026): https://www.brightlocal.com/research/lcrs-ai-trust/
- BDC, average marketing budget (2019 survey): https://www.bdc.ca/en/articles-tools/marketing-sales-export/marketing/marketing-budget

**Grants and programs**
- Ontario, Canada-Ontario Job Grant (paused): https://www.ontario.ca/page/canada-ontario-job-grant-cojg
- OCI, DAC/DMAP requirements (Apr 2026): https://www.oc-innovation.ca/wp-content/uploads/2026/06/DAC-DMAP-Requirements-April-2026.pdf
- Mechanical Business, Home Renovation Savings contractor list (May 2026): https://mechanicalbusiness.com/2026/05/05/apply-now-to-be-added-to-the-home-renovation-savings-program-contractor-list/
- Charity Law Group, Google Ad Grants for Canadian charities (Oct 2026): https://www.charitylawgroup.ca/charity-law-questions/can-google-ads-grants-help-your-canadian-charity-or-nonprofit

**Segment counts (ISED Canadian Industry Statistics, 2025 data)**
- 2361: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/2361
- 2381: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/2381
- 2382: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/2382
- 2383: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/2383
- 2389: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/2389
- 31-33: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/31-33
- 332: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/332
- 3231: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/3231
- 41: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/41
- 4191: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/4191
- 4841: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/4841
- 4842: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/4842
- 5223: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5223
- 5324: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5324
- 5413: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5413
- 5416: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5416
- 5419: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5419
- 5613: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5613
- 5616: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5616
- 5617: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/5617
- 6111: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/6111
- 6244: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/6244
- 7139: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/7139
- 7223: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/7223
- 8121: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/8121
- 8122: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/8122
- 8131: https://ised-isde.canada.ca/app/ixb/cis/businesses-entreprises/8131
- Other counts (2382, 2381, 5242, 5311-5313, 5411, 5412, 6116, 4885, 8111, RCICs, FLSC) are from the prior reports.

**Segment context**
- StatCan, one in four private businesses immigrant-owned (Apr 2024): https://www.statcan.gc.ca/o1/en/plus/6128-one-four-private-sector-businesses-are-owned-immigrants-how-are-they-doing
- Peel Region, 2021 Census language data: https://www.peelregion.ca/articles/2022/census-language-data.asp
- ONN, nonprofit numbers (July 2026): https://theonn.ca/2026/07/whats-in-the-numbers-the-nonprofit-impact-story/
- Retail Insider on CFA 2026 outlook (June 2026): https://retail-insider.com/retail-insider/2026/06/canadian-franchise-association-celebrating-special-day-to-honour-the-industry/
- CMRAO Business Plan 2024-25: https://cmrao.ca/wp-content/uploads/2024/04/CMRAO_Business-Plan-2024-2025.pdf
- Canadian Underwriter, RIBO CEO on consolidation (Dec 2024): https://www.canadianunderwriter.ca/brokers/ribo-ceo-patrick-ballantyne-retiring-talks-self-regulation-ma-and-optionality
- Insurance Business, Canadian insurance behind on AI (June 2026): https://www.insurancebusinessmag.com/ca/news/technology/canadian-insurance-is-behind-on-ai--but-the-disruption-to-brokers-isnt-waiting-580451.aspx
- Money.ca, FSRA mortgage broker sanctions (2025-26): https://money.ca/mortgages/homebuying/fsra-doubled-mortgage-broker-sanctions
- Bank of Canada SAN 2025-21, mortgage renewals (July 2025): https://www.bankofcanada.ca/2025/07/staff-analytical-note-2025-21/
- TICO 2024-25 Annual Report at a glance: https://tico.ca/files/2024-2025_Annual_Report_At-a-Glance.pdf
- Wikipedia, Landscape Ontario: https://en.wikipedia.org/wiki/Landscape_Ontario
- Small Business Trends on Intuit 2025 accountant survey (Aug 2025): https://smallbiztrends.com/accountants-embrace-ai-anticipate-strategic-advisory-boom-amid-challenges/
- AppFolio/NAA 2025 Performance Ecosystem Report (Dec 2025): https://www.appfolio.com/newsroom/technology-implementation-now-a-top-challenge-for-real-estate-leaders
- PHCPPros, ACCA/Farmington 2025 Contractor of the Future (Dec 2025): https://www.phcppros.com/articles/22596-acca-and-farmington-consulting-group-release-2025-contractor-of-the-future-study-results
- Clio, small law firm marketing budget (updated Dec 2024): https://www.clio.com/blog/marketing-budget-for-small-law-firm/
- LearnFormula, end of the volume era for RCICs (May 2026): https://learnformula.com/latest-intelligence/the-end-of-the-volume-era-what-applyboards-reckoning-and-irccs-program-pauses-mean-for-rcics
- LearnFormula, RCIC client acquisition (Mar 2026): https://learnformula.com/latest-intelligence/strategic-adaptation-how-immigration-consultants-must-evolve-amidst-bill-c-12-settlement-cuts-and-shifting-client-acquisition
- CP24 on StatCan international students (May 2026): https://www.cp24.com/local/toronto/2026/05/06/ontario-to-lose-more-than-a-third-of-international-students-statcan/
- Education News Canada / The Conversation, private schools for international students (Sept 2026): https://educationnewscanada.com/article/education/level/k12/3/1216125/the-private-school-market-serving-international-secondary-students-in-ontario-has-grown-.html
- UrbanToronto, GTA housing slowdown (Feb 2026): https://urbantoronto.ca/news/2026/02/industry-updates-market-forecasts-housing-slowdown-and-industry-response.60402
- DLA Piper, Ontario THA and recruiter licensing (2023): https://dlapiper.com/en/insights/publications/2023/08/new-licensing-regime-in-ontario-for-recruiters-and-temporary-help-agencies
- Bullhorn GRID 2025 industry trends: https://www.bullhorn.com/grid/2025-industry-trends/
- Asia Samachar, CTOA and South Asian truckers (Jan 2023): https://asiasamachar.com/2023/01/26/new-canadian-trucking-powerhouse-is-on-the-move-they-want-to-be-heard/
- A&A Customs Brokers, importer concerns mid-2025: https://www.aacb.com/blog/navigating-the-tides-top-concerns-for-canadian-importers-and-exporters-in-mid-2025
- Toronto Region Board of Trade, manufacturing in the age of tariffs (Nov 2025): https://bot.com/News/Survive-and-Thrive-Manufacturing-in-the-Age-of-Tariffs
- MDM, B2B buyer data 2025: https://www.mdm.com/article/blog/what-the-latest-b2b-buyer-data-says-about-digital-distribution-in-2025/
- EightX, Canada Shopify landscape (June 2026): https://eightx.co/blog/canada-shopify-landscape-2026
- CBC, end of US de minimis (Aug 2025): https://www.cbc.ca/lite/story/1.7618234
- EventSource, South Asian banquet halls (listicle): https://www.eventsource.ca/blog/25-beautiful-banquet-halls-that-specialize-in-south-asian-weddings
- BAO 2024-25 business plan: https://thebao.ca/wp-content/uploads/2024/09/BAO_2024_25BusinessPlan.pdf
- CFIB, Intuit "More with AI" tour Toronto: https://www.cfib-fcei.ca/en/event/intuit-more-with-ai-tour-toronto

**Research limitations:**
- focus-digital.co's main URL and WordStream's SMB website report were not reachable directly. Focus Digital was read via an alternate URL, and the WordStream figures come from a compilation.
- FSRA does not currently publish downloadable mortgage-agent counts.
- No reliable count of GTA mosques or banquet venues was found.
- Several price sources are sellers' own pages and are marked [L].
