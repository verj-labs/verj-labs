# Lead backend

The contact wizard (home page `#start` and `/contact`) posts to `POST /api/lead`
([apps/site/src/app/api/lead/route.ts](../apps/site/src/app/api/lead/route.ts)).

Each enquiry does three things:

1. Saves a row in Postgres (Neon) in the `leads` table. The table is created automatically on first use.
2. Emails the studio at `LEAD_TO` (default `hello@verjlabs.com`), with the visitor's address as Reply-To.
3. Emails the visitor a confirmation that the enquiry was received and how to book a call.

## Environment variables (apps/site, set on your host)

| Variable | Required | Purpose |
| --- | --- | --- |
| `DATABASE_URL` | for saving leads | Neon connection string |
| `RESEND_API_KEY` | for emails | Resend API key (the domain must be verified in Resend) |
| `RESEND_FROM` | no | Sender, default `Verj Labs <hello@verjlabs.com>` |
| `LEAD_TO` | no | Where studio notifications go, default `hello@verjlabs.com` |

With neither `DATABASE_URL` nor `RESEND_API_KEY` set, local development logs the enquiry to the server
console and still shows the success screen. In production it returns an error instead.

## Table

```sql
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
);
```

## Spam protection

A hidden honeypot field and a small in-memory limit of 5 enquiries per IP per 10 minutes per server instance.
For heavier traffic, add a shared limiter (for example Upstash) or a CAPTCHA.
