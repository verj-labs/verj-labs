# Verj Labs

Monorepo for everything Verj Labs.

```
apps/
  site/    Company website (Next.js, npm)
  games/   Verj Games: self-contained project with its own backend, frontend and e2e (pnpm)
docs/      Company-level docs and design references
```

Each app is independent and manages its own dependencies. See the README / CLAUDE.md inside each app.

## Website

```bash
npm run site:install
npm run site:dev
```

## Games

See [apps/games/CLAUDE.md](apps/games/CLAUDE.md).
