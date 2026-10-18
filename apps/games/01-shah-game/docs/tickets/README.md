# Shah Exchange — Epic & Ticket Index

> **Source of truth:** [`tickets.json`](./tickets.json) — all epics, tickets, acceptance criteria, dependencies, and quality standards live there.

> **Epic structure:** Epics are **feature-based**, not BE/FE split. Each epic covers a full-stack feature area. Individual tickets within each epic carry a `type` of `backend` or `frontend`. The legacy `backend/` and `frontend/` epic markdown files are retained as supplementary reference only.

---

## Epic Overview

| ID | Title | Priority | Ticket Range | Description |
|---|---|---|---|---|
| EP-001 | Infrastructure & Project Setup | P0 | T-001–T-013 | Dev tooling, DB, Redis, CI, base UI primitives |
| EP-002 | Authentication & Session Management | P0 | T-014–T-020 | Anonymous session auth, token storage, landing page |
| EP-003 | Lobby & Room Management | P0 | T-021–T-027 | Room creation, join by code, waiting room, host controls |
| EP-004 | Core Game Engine | P0 | T-028–T-040 | Pure stateless rules engine, 90%+ coverage target |
| EP-005 | Real-Time Game Play | P0 | T-041–T-058 | WebSocket gateway, game board, socket integration |
| EP-006 | Card Exchange System | P1 | T-059–T-063 | Post-game exchange algorithm + animated UI |
| EP-007 | Game End, Rankings & Results | P1 | T-064–T-067 | Match results page, aggregate standings, animations |
| EP-008 | Match History | P2 | T-068–T-069 | History API + history list page |

---

## Build Order

Respect the dependency chain below. Epics within the same tier can be parallelised across BE and FE, but the inter-epic dependencies are strict.

```
EP-001 (infra + base UI)
    └──► EP-002 (auth)
              └──► EP-003 (lobby)
                        └──► EP-004 (game engine — BE only, no FE)
                                  └──► EP-005 (real-time play — BE + FE, main game loop)
                                            ├──► EP-006 (card exchange)
                                            │         └──► EP-007 (results + animations)
                                            └──► EP-007 (results)
                                                       └──► EP-008 (history)
```

---

## Ticket Counts by Epic

| Epic | Backend tickets | Frontend tickets | Total |
|---|---|---|---|
| EP-001 | 7 (T-001–T-007) | 6 (T-008–T-013) | 13 |
| EP-002 | 4 (T-014–T-017) | 3 (T-018–T-020) | 7 |
| EP-003 | 4 (T-021–T-024) | 3 (T-025–T-027) | 7 |
| EP-004 | 12 (T-028–T-039) | 1 (T-040) | 13 |
| EP-005 | 8 (T-041–T-048) | 10 (T-049–T-058) | 18 |
| EP-006 | 3 (T-059–T-061) | 2 (T-062–T-063) | 5 |
| EP-007 | 2 (T-064–T-065) | 2 (T-066–T-067) | 4 |
| EP-008 | 1 (T-068) | 1 (T-069) | 2 |
| **Total** | **41** | **28** | **69** |

---

## Quality Standards

Global quality criteria (Definition of Done, code quality rules, testing standards, PR standards) are embedded in the `criteria` key at the top of `tickets.json`. All tickets inherit these standards implicitly.

---

## Reference Documents

- [`../SYSTEM_DESIGN.md`](../SYSTEM_DESIGN.md) — Full architecture: domain model, state machine, DB schema, REST API, WebSocket contract
- [`tickets.json`](./tickets.json) — Single source of truth for all tickets, epics, acceptance criteria, and quality standards
- [`epics/EP-001-infrastructure-project-setup.md`](./epics/EP-001-infrastructure-project-setup.md)
- [`epics/EP-002-auth-session-management.md`](./epics/EP-002-auth-session-management.md)
- [`epics/EP-003-lobby-room-management.md`](./epics/EP-003-lobby-room-management.md)
- [`epics/EP-004-core-game-engine.md`](./epics/EP-004-core-game-engine.md)
- [`epics/EP-005-realtime-game-play.md`](./epics/EP-005-realtime-game-play.md)
- [`epics/EP-006-card-exchange-system.md`](./epics/EP-006-card-exchange-system.md)
- [`epics/EP-007-game-end-rankings-results.md`](./epics/EP-007-game-end-rankings-results.md)
- [`epics/EP-008-match-history.md`](./epics/EP-008-match-history.md)
- [`backend/`](./backend/) — Original BE-only epic writeups (**superseded** — reference only)
- [`frontend/`](./frontend/) — Original FE-only epic writeups (**superseded** — reference only)
