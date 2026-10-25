# Shah Exchange: production readiness review and checklist

Review date: 2026-10-25. Reviewed: the Godot client (`godot/`), the headless game server (`godot/server/`),
the Railway deployment, the iOS and Android exports, and the docs. Everything below was checked against the
code or by running it, except where marked *(not verified)*.

**Verdict: not ready to ship yet.** The game itself is solid: the rules engine is well tested (342 tests), the
server is authoritative and was verified against a real two-device game, and the arcade look is distinctive.
What is missing is everything *around* the game that the stores and real players expect: release builds,
a privacy policy, a stable server address, abuse protection, crash reporting, a settings screen, a tutorial,
store assets and a beta period. None of it is hard, but it is a lot of small items. This document lists them
in the order we should do them.

How to read it: **P0** = blocks submission or will hurt players on day one. **P1** = should be done before a public
launch. **P2** = nice to have, can follow in an update. Size: S = under half a day, M = 1-2 days, L = several days.
`[x]` done, `[~]` partly done, `[ ]` not started.

---

## 0. Summary of the biggest risks

1. **We are shipping debug builds.** Both the iOS project and the APK use Godot's *debug* templates
   (debuggable, slower, larger, remote-debugger enabled). Store builds must be *release* (P0).
2. **The server address is baked into the app** and it is the temporary
   `verj-labs-production.up.railway.app`. Changing it later needs an app update. Put a custom domain in
   front of it before any public build (P0).
3. **Anyone can take the server down.** Limits are global, not per player or per IP: one script can open
   all 800 connections or create all 200 rooms (P0).
4. **No privacy policy, support page or store listing**, which both stores require (P0).
5. **No crash reporting or analytics**, so after launch we would be blind (P1).
6. **First-time player experience is thin**: a text-only "How to play" and no settings screen (P1).
7. **A redeploy kills every running game.** Fine for a beta; needs a plan before launch (P1).

---

## 1. Store and legal (P0, blocks submission)

| # | Item | Pri | Size | Status |
|---|------|-----|------|--------|
| 1.1 | Apple Developer account for Verj Labs Inc. (team `XU24SGA3PU`) exists and is set as the default signing team | P0 | S | [x] |
| 1.2 | Confirm the final bundle ID (`com.verjlabs.shahexchange`) before creating the App Store Connect record; it can never change | P0 | S | [ ] |
| 1.3 | Create the App Store Connect app record and the Google Play Console app (Play dev account: one-time fee; new personal accounts need a 14-day closed test with 12 testers, organisation accounts do not) | P0 | S | [ ] |
| 1.4 | **Privacy policy** page at a public URL (what we collect: display name, IP address in server logs, a random session token, gameplay events; no ads, no tracking, no accounts) | P0 | S | [ ] |
| 1.5 | Support URL and support email (an inbox someone reads) | P0 | S | [ ] |
| 1.6 | Apple "App Privacy" answers and Google Play "Data safety" form, consistent with 1.4 and with whatever analytics/crash tools we add | P0 | S | [ ] |
| 1.7 | `PrivacyInfo.xcprivacy`: Godot generates one; set the *required-reason API* entries in the iOS export preset (file timestamps, disk space, system boot time) so App Store Connect does not warn or reject | P0 | S | [ ] |
| 1.8 | Export compliance: the app only uses standard TLS (`wss://`), so declare `ITSAppUsesNonExemptEncryption = false` in the iOS Info.plist to avoid the question on every upload | P0 | S | [ ] |
| 1.9 | Age rating questionnaires. Expected: 4+/Everyone. No real-money gambling, no chat, no user-created media. Players see other players' *names*, so state that honestly | P0 | S | [ ] |
| 1.10 | **User-generated content (Apple 1.2):** player names are shown to strangers. Add a name profanity filter on the server and keep the host's kick button. Reporting a player is a P1 follow-up | P0 | M | [ ] |
| 1.11 | Name and trademark check for "Shah Exchange" in the target stores; the game rules are a well-known traditional card game, so no IP issue, but verify the name is free | P0 | S | [ ] |
| 1.12 | Licences: everything is generated in code or by our scripts (font, art, audio). gdUnit4 (MIT) is excluded from exports. Add a Credits/licences entry for Godot (MIT) in the app | P1 | S | [ ] |
| 1.13 | Decide the business model for v1 (recommended: **free, no ads, no purchases, no accounts**). Ads need consent/ATT flows, IAP needs StoreKit/Billing plugins, accounts need Sign in with Apple and in-app account deletion | P0 | S | [ ] |
| 1.14 | Review notes for Apple: online play needs other players, but the host can add bots, so a reviewer can test alone. Say so, include the steps | P0 | S | [ ] |

## 2. Build and release pipeline

| # | Item | Pri | Size | Status |
|---|------|-----|------|--------|
| 2.1 | **Export release builds**, not debug (`--export-release`; iOS Release scheme; Android release AAB). Verify `OS.is_debug_build()` is false and remote debug is off | P0 | S | [ ] |
| 2.2 | Android: Google Play needs an **AAB** (not an APK), built with the Gradle build option, a **release keystore** (generate once, back it up, enrol in Play App Signing). Our current APK is debug-signed and only good for sideloading | P0 | M | [ ] |
| 2.3 | Android: confirm target SDK is current (Play requires the latest within a year) and the native libs support 16 KB page sizes (required for new apps targeting Android 15+) | P0 | S | [ ] |
| 2.4 | iOS: archive in Xcode, upload to TestFlight, install on a real device from TestFlight (not from Xcode) as a final check | P0 | S | [ ] |
| 2.5 | Replace the **Godot boot splash** and set a proper launch screen (iOS storyboard and Android splash) in our colours | P0 | S | [ ] |
| 2.6 | App icon: new neon crown-card design, iOS 1024 icon plus Android adaptive icon (foreground, background, monochrome). Made by `tools/make_icon.py` + `tools/render_icons.gd` | P0 | M | [x] |
| 2.7 | Version scheme: `application/short_version` / `version` (iOS) and `version/name` / `version/code` (Android) bumped per release; write down the rule (e.g. build number = CI run) | P1 | S | [ ] |
| 2.8 | CI: GitHub Actions to run `./test.sh`, export builds, and (later) upload to TestFlight / Play internal testing. Also run `tools/check_server.py wss://...` after each server deploy | P1 | L | [ ] |
| 2.9 | The signing team, bundle ID and export presets live in `godot/export_presets.cfg` (committed). Keep keystores and any App Store Connect API keys *out* of git | P0 | S | [~] |
| 2.10 | Pin tool versions in one place (Godot 4.7.2 is pinned in the Dockerfile; document the same for the editor and export templates) | P2 | S | [ ] |

## 3. Server and infrastructure

What is good: the server is the referee (clients send intents only), hands are private per player, session tokens
are cryptographically random, messages are size-limited and rate-limited per connection, bad clients are
dropped, rooms and sessions expire, and there is a `/health` endpoint and a restart policy. It passed an
independent Python client and the game's own client over `wss://` on Railway.

| # | Item | Pri | Size | Status |
|---|------|-----|------|--------|
| 3.1 | **Custom domain** (e.g. `play.verjlabs.com`) pointing at the Railway service, and use that in the app instead of `*.up.railway.app` | P0 | S | [ ] |
| 3.2 | **Per-IP limits** (Railway forwards the client IP in `X-Forwarded-For`): max connections per IP, max new connections per minute, max rooms created per IP/session, cooldown after repeated failed joins. Today only global caps exist (`MAX_CONNECTIONS` 800, `MAX_ROOMS` 200), so one client can exhaust them | P0 | M | [ ] |
| 3.3 | Room codes are 4 letters (about 330,000 combinations) from a non-cryptographic RNG; lobbies can be guessed by brute force. Mitigate with the join rate limit in 3.2 and, optionally, 5-letter codes | P1 | S | [ ] |
| 3.4 | Name moderation (see 1.10) on the server, in `Protocol.clean_name` / `Room._unique_name` | P0 | M | [ ] |
| 3.5 | **Staging environment** on Railway (second environment) so builds are tested against a server that is not production; deploy to production only from a tagged commit | P1 | S | [ ] |
| 3.6 | Fix the Railway service config: the service is still linked to the GitHub repo root (Railpack, failing). Set Root Directory to `apps/games/01-shah-game-redesign`, builder Dockerfile, and rename the service (e.g. `shah-server`). Until then, deploys are manual with `railway up` | P1 | S | [ ] |
| 3.7 | **Graceful redeploys.** A redeploy ends all running games and nothing warns players. Options: (a) deploy only at quiet hours and accept it for the first launch; (b) handle SIGTERM, send a "server restarting" message, and let clients show it and rejoin automatically afterwards; (c) persist room state. Pick at least (a)+(b) | P1 | M | [ ] |
| 3.8 | Monitoring: external uptime check on `/health` (e.g. BetterStack/UptimeRobot) with alerts to Verj Labs; Railway metrics dashboard; log rooms/connections (already printed once a minute) and errors in a structured form | P1 | S | [ ] |
| 3.9 | Add `GET /version` (server version, protocol version, build commit) for support and for the client | P1 | S | [ ] |
| 3.10 | **Client/server version compatibility:** the client must show a friendly "please update the app" screen on `bad_version` and the server should accept the previous protocol for a release or two | P0 | M | [ ] |
| 3.11 | Load test: soak with ~200 bot-driven rooms and ~800 connections on the real Railway plan; record CPU, memory and message latency. The server is one single-threaded Godot process | P1 | M | [ ] |
| 3.12 | Region/latency: the service is in US East. Fine for North America; players in South Asia / Europe will see 150-300 ms. Acceptable for a turn-based game; revisit with a second region if usage grows | P2 | S | [ ] |
| 3.13 | Accounts / leaderboards (Supabase) are not built and **should stay out of v1**: they add Sign in with Apple, account deletion and moderation requirements | P2 | L | [ ] |
| 3.14 | `ALLOWED_ORIGINS` is empty (any origin). That is fine for native apps; set it if a web build is ever published | P2 | S | [ ] |
| 3.15 | Cost estimate and Railway plan sized for launch (hobby plans can sleep or cap usage) | P1 | S | [ ] |

## 4. Gameplay and rules

| # | Item | Pri | Size | Status |
|---|------|-----|------|--------|
| 4.1 | Confirm the **open rule questions** in `docs/OPEN_QUESTIONS.md`, especially #7 (which side counts as "right" for the 2nd-place direction) and #13 (match scoring: placement points, most points wins) | P0 | S | [ ] |
| 4.2 | Exchange rule: 2s are never exchanged (done, tested) | P0 | S | [x] |
| 4.3 | Match length 10 or 20 games with scoring and final standings (done, tested) | P0 | M | [x] |
| 4.4 | Bots: only Easy and Medium exist. Add a **Hard** bot and check that bots never stall or make illegal moves in long soak runs (the random-game tests already do this for the engine) | P1 | M | [ ] |
| 4.5 | Known text bug: the hint can read "YOU IS THINKING..." while your own move animates. Fix the wording | P1 | S | [ ] |
| 4.6 | Turn timer fairness online: timers are server-side (good). Add a visible "away" state and let the host skip an absent player instead of waiting for time-outs | P1 | M | [ ] |
| 4.7 | After a match: "Play again with the same players" without going through the lobby | P2 | M | [ ] |
| 4.8 | Statistics (games, wins, streaks) stored on the device | P2 | M | [ ] |

## 5. UX and UI

Fixed in this pass: notch/Dynamic Island safe areas, finger-sized buttons, bigger cards, scrolling by dragging
anywhere on long screens (`ui/touch_scroll.gd`), the server address field removed from the screen, a confirmation
before leaving a game, and REJOIN GAME on the main menu for online games.

| # | Item | Pri | Size | Status |
|---|------|-----|------|--------|
| 5.1 | **Settings screen**: music and sound (exist as two buttons), vibration, name, "How to play", Privacy policy and Terms links, credits and licences, app version, "Delete my data" | P0 | M | [ ] |
| 5.2 | **Tutorial / first-run guide.** Today there is a text pop-up only. A short interactive first game (guided hints for single, double, skip, reset and exchange) will decide whether new players understand the game | P1 | L | [ ] |
| 5.3 | Layout verified on the common phone shapes: iPhone SE (16:9), iPhone 15/16 (19.5:9), Pro Max, Android 20:9. Done for menu, setup, online, lobby and the 3/5/8-player table; the dialogs and results panels were checked at 19.5:9 only. The app is iPhone-only, so iPad runs it in compatibility mode | P0 | M | [~] |
| 5.4 | Network error states: the Online screen shows "RECONNECTING..." forever when the server is unreachable. Add a timeout, a clear "Can't reach the server" message and a Retry button; show the update prompt (3.10); explain `room_full`, `room_started`, `no_such_room` in plain words (some exist in `online/online_text.gd`) | P0 | M | [ ] |
| 5.5 | Android system **Back button** and iOS swipe-back: currently Back can quit the app mid-game. Route it to the same "Leave game?" confirmation | P0 | S | [ ] |
| 5.6 | Haptics (light tap on card select, stronger on play/skip/reset) and a **mute switch** that respects the iPhone silent switch (audio session category) | P1 | S | [ ] |
| 5.7 | Accessibility: the game uses custom-drawn controls, so VoiceOver/TalkBack cannot read them (a known Godot limitation). Document this, keep contrast high, never rely on colour alone (seats also have names), add a "Reduce effects" option (screen shake, scanlines, flashing blocks) | P1 | M | [ ] |
| 5.8 | Localisation: English only, and the pixel font has only A-Z, 0-9 and a little punctuation, so names are restricted to those. If South Asian / Middle Eastern markets matter (the name suggests so), plan translations and a second font; this is a large change | P2 | L | [ ] |
| 5.9 | Share a room: "Invite friends" button using the system share sheet with the code (and later a link that opens the app) | P1 | M | [ ] |
| 5.10 | Rate-the-app prompt after a few completed games; feedback/contact button | P2 | S | [ ] |
| 5.11 | The 8-player table is tight on the narrowest phones (seat badges nearly touch). Check on a 360 dp Android; shrink badges further if needed | P1 | S | [ ] |
| 5.12 | The Android "Viewing full screen" system hint appears once because of immersive mode; acceptable, or switch to non-immersive | P2 | S | [ ] |

## 6. Device matrix (what "fits popular phones" means)

The layout is 540 units wide and at least 960 tall. Taller phones get extra height, wider screens (iPad) get
extra width. Targets to check, in layout terms:

| Aspect | Example devices | Layout |
|---|---|---|
| 16:9 | iPhone SE 2/3, old Androids | 540 x 960, tightest height |
| 19.5:9 | iPhone X to 16 Pro | 540 x ~1170 |
| 20:9 | Samsung Galaxy S/A series, Pixels | 540 x ~1200 |
| 4:3 | iPad (runs the iPhone app letterboxed or scaled) | 720 x 960 |

Checklist: main menu, setup, online, lobby (3 and 8 seats), table with 3, 4 and 8 players, game-over and
match-over panels, the leave and rejoin dialogs, with and without a notch (`--fake-notch`).
Status: [x] 16:9 and 19.5:9 checked with `tools/screenshot.gd` (menu, setup, online, lobby, table with 3, 5 and 8 players); 4:3 only matters for Android tablets. Still to check on real hardware: a 360 dp Android and a Pro Max.

## 7. Performance, stability, quality

| # | Item | Pri | Size | Status |
|---|------|-----|------|--------|
| 7.1 | Measure FPS, CPU and battery on a **low-end Android** and an older iPhone. The background and CRT overlay redraw every frame in script (`ArcadeBackground._process` calls `queue_redraw`); make them cheaper or cap to 30 fps on menus if needed | P1 | M | [ ] |
| 7.2 | **Crash reporting** (Sentry's Godot SDK, or Firebase Crashlytics via a plugin) plus a minimal privacy-friendly event log (sessions, games finished) so we can see retention and failures. Update the privacy forms (1.6) accordingly | P1 | M | [ ] |
| 7.3 | Real-device testing of **backgrounding and reconnection**: lock the phone for 20 s mid-game, switch apps, lose and regain Wi-Fi, airplane mode. The client reconnects with a saved token and the new rejoin flow covers a deliberate leave; neither has been tried on a physical phone *(not verified)* | P0 | M | [ ] |
| 7.4 | A written **manual test plan** (single player, online 2/3/8 players, bots, host leaves, kicked, match end, rejoin, server restart) and run it on iOS and Android before every release | P0 | M | [ ] |
| 7.5 | Beta: TestFlight (10-20 people) and Play internal/closed testing for at least a week; fix what they find | P0 | L | [ ] |
| 7.6 | Automated UI smoke test: load every scene at several window sizes, assert no overflow past the screen (`scenes_load_test.gd` loads the scenes; size checks are not automated yet) | P2 | M | [ ] |
| 7.7 | Test suite health: 342 tests pass (`./test.sh`). Keep it green in CI (2.8) | P1 | S | [x] |
| 7.8 | App size is about 27 MB (mostly the engine). Convert `music.wav` and other WAVs to OGG to save a few MB; strip unused engine modules only if size becomes an issue | P2 | S | [ ] |

## 8. Branding and store assets

| # | Item | Pri | Size | Status |
|---|------|-----|------|--------|
| 8.1 | New app icon (neon crown card on a synthwave horizon). Generated by `tools/make_icon.py`; iOS 1024 px, Android adaptive layers. Still to decide: keep this design or iterate after seeing it on a home screen | P0 | M | [x] |
| 8.2 | **App Store screenshots** for the 6.9" iPhone class (1320 x 2868) and 6.5" (1284 x 2778), plus Google Play phone screenshots (1080 x 1920 or larger) and a 1024 x 500 feature graphic. Generated by `tools/screenshots.gd` from real game screens (5 shots x 3 sizes, raw and with a caption in a phone frame), so they can be refreshed. Still to do: review the wording, add 6.7"/iPad sets only if we support iPad | P0 | M | [~] |
| 8.3 | App name, subtitle (30 chars), keywords, description, promo text, "What's new", category (Games > Card), copyright, and a short Play Store description | P0 | S | [ ] |
| 8.4 | Landing page with the privacy policy, support contact and store badges (can be one static page) | P0 | M | [ ] |
| 8.5 | App preview video (15-30 s screen capture) | P2 | M | [ ] |

## 9. Launch and after launch

- [ ] Phased release on iOS and staged rollout on Android (start at 10-20%).
- [ ] Watch crash-free sessions, server CPU, rooms created per day and reconnect rate for the first week.
- [ ] A kill switch / minimum-version message from the server for emergencies.
- [ ] Support routine: who reads the inbox, response times, how bug reports reach the backlog.
- [ ] Release notes and a changelog habit.

---

## Suggested order of work

1. **Blockers that are quick**: custom domain (3.1), version-mismatch screen and network errors (3.10, 5.4),
   Back button (5.5), name filter (1.10/3.4), per-IP limits (3.2), release builds (2.1), splash and icon (2.5, 2.6, 8.1).
2. **Player-facing basics**: settings screen (5.1), privacy policy and support page (1.4, 1.5, 8.4), fix the hint text
   (4.5), the device matrix (section 6), real-device reconnect testing (7.3).
3. **Store submission kit**: privacy forms, export compliance, screenshots, listing text (1.6-1.9, 8.2, 8.3), AAB and
   keystore (2.2), TestFlight and Play internal testing (2.4, 7.5).
4. **Quality and learning**: crash reporting (7.2), tutorial (5.2), Hard bot (4.4), load test (3.11), CI (2.8),
   staging and graceful redeploys (3.5-3.7).
5. **Launch**, then updates: invite link, stats, localisation, accounts and leaderboards.

## What changed in the pass that produced this document

- Touch scrolling that works from anywhere on the screen (`ui/touch_scroll.gd`).
- The server address is gone from the Online screen; developers can still override it with `SHAH_SERVER` or
  `-- --server=ws://host:port`.
- MENU on the table now asks before leaving. Online, leaving keeps the seat for a short while (a bot plays it) and the
  main menu shows **REJOIN GAME** (`OnlineClient.park()` / `rejoin()`).
- The table now learns your seat from the server (a joiner who was not seat 0 could previously see the table from seat 0's point of view).
- Main menu compacted so it fits the shortest phones (audio buttons float in the corner).
- Single-player match length from the setup screen now actually reaches the game (it was ignored before).
- Lobby: option chips are compact and ADD BOT / LEAVE share a row; the table sizes the hand area to the number of cards and keeps the pile clear of your seat on short screens.
- New app icon, an App Store / Play screenshot generator (`tools/screenshots.gd`) and this checklist.
- 352 tests, including rejoin, touch scrolling and the leave confirmation. Touch scrolling was also verified with real swipes on the Android emulator.
