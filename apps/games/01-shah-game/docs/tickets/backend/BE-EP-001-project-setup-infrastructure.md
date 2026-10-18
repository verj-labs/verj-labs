> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary backend detail.
> **Replaced by:** [EP-001 — Infrastructure & Project Setup](../epics/EP-001-infrastructure-project-setup.md) · [tickets.json](../tickets.json) → T-001–T-007

---

# BE-EP-001 — Project Setup & Infrastructure

| Field | Value |
|---|---|
| **ID** | BE-EP-001 |
| **Type** | Epic |
| **Team** | Backend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | None |
| **Blocks** | All other backend epics |
| **Estimated Effort** | M (3–5 days) |

---

## Description

This epic covers the complete foundational setup of the NestJS backend, establishing the repository structure, development tooling, environment configuration, database connectivity, and CI baseline before any feature development begins.

The backend was scaffolded via the NestJS CLI but has not had any modules, environment variables, database setup, or deployment tooling applied yet. This epic brings it to a state where all other epics can be built on top of a working, connected, and testable foundation.

---

## Background & Motivation

A strong infrastructure baseline prevents costly rework later. Every other backend epic depends on:
- A consistent module/folder structure
- Working database connectivity
- Redis connectivity for real-time state
- Environment variable management
- Linting/formatting enforced in CI
- Baseline test setup

Without this epic completed, no other work should begin.

---

## Goals

- Establish module architecture matching the system design
- Configure PostgreSQL connection via TypeORM/Prisma
- Configure Redis for session/state storage
- Define all environment variables and validation schema
- Set up Docker Compose for local development (Postgres + Redis)
- Install and configure testing framework (Jest)
- Configure ESLint, Prettier, and enforce via pre-commit hooks (Husky)
- Set up basic CI pipeline (GitHub Actions or equivalent)
- Health check endpoint wired and working

---

## Detailed Scope

### 1. Module Structure
Create the following NestJS modules (empty shells with correct decorators):
- `AuthModule`
- `PlayerModule`
- `MatchModule`
- `GameModule`
- `GameEngineModule`
- `GatewayModule`

Each module should have a corresponding `*.module.ts`, `*.service.ts`, and (where applicable) `*.controller.ts`.

### 2. Database Setup (PostgreSQL via TypeORM or Prisma)
- Choose and commit to ORM (TypeORM or Prisma — decision to be made during grooming)
- Configure connection from environment variables
- Create initial migration or schema file with all tables defined in `SYSTEM_DESIGN.md §7`
- Ensure `synchronize: false` in production, migrations-based in all envs
- Add database seeding script for local development (sample players, rooms)

### 3. Redis Setup
- Install `ioredis` and create a `RedisModule` (or use `@nestjs-modules/ioredis`)
- Inject Redis client into services as needed
- Confirm connectivity on startup with a health check

### 4. Configuration Management
- Install `@nestjs/config`
- Define `.env.example` with all required keys:
  - `DATABASE_URL`
  - `REDIS_URL`
  - `JWT_SECRET` or `SESSION_SECRET`
  - `PORT`
  - `NODE_ENV`
- Validate env at startup using `Joi` or `zod` schema
- Never commit `.env` — only `.env.example`

### 5. Docker Compose
Create `docker-compose.yml` at the repo root (or backend dir) with:
- `postgres:16` service with named volume
- `redis:7` service
- Correct port mappings and environment variables
- `docker-compose.override.yml` for local dev overrides

### 6. Health Check
- Install `@nestjs/terminus`
- Expose `GET /health` endpoint
- Check: HTTP server alive, Postgres reachable, Redis reachable

### 7. Tooling
- ESLint with TypeScript rules (already partially set up — audit and extend)
- Prettier config committed
- Husky + lint-staged: run lint + format check on commit
- `package.json` scripts: `start:dev`, `build`, `test`, `test:e2e`, `lint`, `format`

### 8. CI Pipeline
- GitHub Actions workflow (or equivalent)
- Jobs: lint → unit test → build
- Run on PRs to `main`

---

## Acceptance Criteria

- [ ] `pnpm install` succeeds from scratch
- [ ] `docker-compose up` starts Postgres and Redis locally
- [ ] `pnpm start:dev` starts the server without errors
- [ ] `GET /health` returns `200 OK` with status of Postgres and Redis
- [ ] All module shells exist with correct NestJS decorators
- [ ] Database migrations run cleanly with `pnpm migration:run`
- [ ] `.env.example` documents all required variables
- [ ] `pnpm lint` passes with zero errors
- [ ] `pnpm test` runs and passes (empty test suite is acceptable at this stage)
- [ ] CI pipeline runs and passes on a test PR

---

## Out of Scope

- Any game logic implementation
- Any actual data being written to the database
- Authentication token issuance (covered in BE-EP-002)

---

## Technical Notes

- Use **pnpm** as the package manager (already initialized)
- NestJS version: latest stable (v10+)
- Node.js minimum: 20 LTS
- All TypeScript strict mode enabled (`"strict": true` in tsconfig)
- Prefer `class-validator` + `class-transformer` for DTO validation throughout the project
