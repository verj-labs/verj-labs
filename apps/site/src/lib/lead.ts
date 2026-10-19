import { neon } from "@neondatabase/serverless";
import { CAL_URL, EMAIL, needById } from "./site";

export type Lead = {
  need: string;
  when: string;
  name: string;
  email: string;
  phone: string;
  message: string;
};

const WHEN_LABELS: Record<string, string> = {
  asap: "As soon as possible",
  "1-3m": "In the next 1 to 3 months",
  later: "Later this year",
  exploring: "Just exploring for now",
};

export const WHEN_IDS = Object.keys(WHEN_LABELS);
export const needLabel = (id: string) => needById(id)?.label ?? "Not sure yet";
export const whenLabel = (id: string) => WHEN_LABELS[id] ?? "No date yet";

const esc = (s: string) =>
  s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] as string);

let ready: Promise<void> | null = null;

/** Saves the lead to Postgres (Neon). Creates the table on first use. */
export async function saveLead(lead: Lead, meta: { ip: string; ua: string }) {
  const url = process.env.DATABASE_URL;
  if (!url) return false;
  const sql = neon(url);
  ready ??= sql`
    CREATE TABLE IF NOT EXISTS leads (
      id BIGSERIAL PRIMARY KEY,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      need TEXT NOT NULL,
      timeframe TEXT NOT NULL,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone TEXT,
      message TEXT,
      ip TEXT,
      user_agent TEXT
    )
  `.then(() => undefined);
  await ready;
  await sql`
    INSERT INTO leads (need, timeframe, name, email, phone, message, ip, user_agent)
    VALUES (${lead.need}, ${lead.when}, ${lead.name}, ${lead.email}, ${lead.phone || null}, ${lead.message || null}, ${meta.ip}, ${meta.ua.slice(0, 300)})
  `;
  return true;
}

async function send(payload: { to: string; subject: string; html: string; text: string; replyTo: string }) {
  const key = process.env.RESEND_API_KEY;
  if (!key) return false;
  const from = process.env.RESEND_FROM || `Verj Labs <${EMAIL}>`;
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from,
      to: [payload.to],
      subject: payload.subject,
      html: payload.html,
      text: payload.text,
      reply_to: payload.replyTo,
    }),
  });
  if (!res.ok) throw new Error(`Resend ${res.status}: ${(await res.text()).slice(0, 200)}`);
  return true;
}

/** One email to the studio, one to the person who asked. */
export async function sendLeadEmails(lead: Lead) {
  const owner = process.env.LEAD_TO || EMAIL;
  const first = lead.name.split(" ")[0];
  const rows: [string, string][] = [
    ["Name", lead.name],
    ["Email", lead.email],
    ["Phone", lead.phone || "-"],
    ["Needs", needLabel(lead.need)],
    ["When", whenLabel(lead.when)],
    ["Message", lead.message || "-"],
  ];

  const ownerSent = await send({
    to: owner,
    replyTo: lead.email,
    subject: `New enquiry: ${needLabel(lead.need)} (${lead.name})`,
    text: rows.map(([k, v]) => `${k}: ${v}`).join("\n"),
    html: `<h2 style="margin:0 0 12px">New enquiry</h2><table cellpadding="6" style="border-collapse:collapse">${rows
      .map(([k, v]) => `<tr><td style="color:#666"><b>${esc(k)}</b></td><td>${esc(v).replace(/\n/g, "<br>")}</td></tr>`)
      .join("")}</table>`,
  });

  let customerSent = false;
  try {
    customerSent = await send({
      to: lead.email,
      replyTo: EMAIL,
      subject: `We got your enquiry, ${first}`,
      text: `Hi ${first},\n\nThanks for reaching out to Verj Labs. We have your enquiry about "${needLabel(lead.need)}" and we are reading it now.\n\nWe will reply to this email with next steps. If you would rather talk it through, you can pick a time here:\n${CAL_URL}\n\nVerj Labs`,
      html: `<p>Hi ${esc(first)},</p><p>Thanks for reaching out to Verj Labs. We have your enquiry about <b>${esc(needLabel(lead.need))}</b> and we are reading it now.</p><p>We will reply to this email with next steps. If you would rather talk it through, you can <a href="${CAL_URL}">pick a time here</a>.</p><p>Verj Labs</p>`,
    });
  } catch (err) {
    console.error("[lead] customer email failed", err);
  }
  return { ownerSent, customerSent };
}
