import { NextResponse } from "next/server";
import { Lead, WHEN_IDS, saveLead, sendLeadEmails } from "@/lib/lead";
import { NEEDS } from "@/lib/site";

export const runtime = "nodejs";

// Small in-memory limiter: 5 enquiries per IP per 10 minutes (per server instance).
const hits = new Map<string, number[]>();
const limited = (ip: string) => {
  const now = Date.now();
  const recent = (hits.get(ip) ?? []).filter((t) => now - t < 10 * 60 * 1000);
  recent.push(now);
  hits.set(ip, recent);
  return recent.length > 5;
};

const clean = (v: unknown, max: number) => (typeof v === "string" ? v.trim().slice(0, max) : "");
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

export async function POST(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0].trim() || "unknown";
  if (limited(ip)) return NextResponse.json({ ok: false, error: "Too many requests. Please try again later." }, { status: 429 });

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid request." }, { status: 400 });
  }

  // Honeypot: bots fill the hidden field. Pretend it worked.
  if (clean(body.website, 200)) return NextResponse.json({ ok: true });

  const lead: Lead = {
    need: clean(body.need, 20),
    when: clean(body.when, 20),
    name: clean(body.name, 120),
    email: clean(body.email, 200),
    phone: clean(body.phone, 40),
    message: clean(body.message, 2000),
  };

  if (!lead.name) return NextResponse.json({ ok: false, error: "Please add your name." }, { status: 400 });
  if (!EMAIL_RE.test(lead.email)) return NextResponse.json({ ok: false, error: "Please check your email address." }, { status: 400 });
  if (lead.need !== "unsure" && !NEEDS.some((n) => n.id === lead.need)) {
    return NextResponse.json({ ok: false, error: "Please choose what you need." }, { status: 400 });
  }
  if (!WHEN_IDS.includes(lead.when)) lead.when = "exploring";

  const meta = { ip, ua: req.headers.get("user-agent") || "" };
  let saved = false;
  let emailed = false;
  try {
    saved = await saveLead(lead, meta);
  } catch (err) {
    console.error("[lead] database failed", err);
  }
  try {
    const r = await sendLeadEmails(lead);
    emailed = r.ownerSent;
  } catch (err) {
    console.error("[lead] email failed", err);
  }

  if (!saved && !emailed) {
    // Nothing is configured (local dev) or both failed.
    if (process.env.NODE_ENV !== "production") {
      console.log("[lead] no DATABASE_URL or RESEND_API_KEY set. Enquiry:", lead);
      return NextResponse.json({ ok: true, dev: true });
    }
    return NextResponse.json({ ok: false, error: "We could not send your enquiry just now." }, { status: 502 });
  }
  return NextResponse.json({ ok: true });
}
