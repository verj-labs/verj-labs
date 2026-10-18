/**
 * Game-play helpers for E2E tests.
 */
import { type Page, expect } from '@playwright/test';
import { type Player } from '../fixtures/game.fixture';
import { registerOrLogin } from './auth';
import { createRoom, joinRoom, startGame } from './lobby';

/**
 * Waits for the game board to be visible for a given player's page.
 * This indicates `game:started` has been received and the board has rendered.
 */
export async function waitForGameBoard(page: Page): Promise<void> {
  await page.waitForURL('**/game/**', { timeout: 10_000 });
  await expect(page.locator('[data-testid="game-board"]')).toBeVisible({
    timeout: 6_000,
  });
}

/**
 * Asserts the number of cards shown in the player's own hand area.
 */
export async function assertHandCount(page: Page, count: number): Promise<void> {
  const hand = page.locator('[data-testid="local-hand"]');
  await expect(hand.locator('[data-testid^="card-"]')).toHaveCount(count, {
    timeout: 3_000,
  });
}

/**
 * Asserts the rank+suit of the top card visible on the pile.
 * e.g. assertPileTop(page, '3H') for 3 of Hearts.
 */
export async function assertPileTop(page: Page, cardLabel: string): Promise<void> {
  await expect(page.locator('[data-testid="pile-top"]')).toHaveText(cardLabel, {
    timeout: 2_000,
  });
}

/**
 * Clicks a card in the local hand to select it, then clicks the Play button.
 * Expects the `data-testid` to be "card-{RANK}{SUIT}" e.g. "card-3H".
 */
export async function playCard(page: Page, cardTestId: string): Promise<void> {
  await page.click(`[data-testid="${cardTestId}"]`);
  await page.click('[data-testid="play-button"]');
}

/**
 * Clicks the Pass button for the current player.
 */
export async function pass(page: Page): Promise<void> {
  await page.click('[data-testid="pass-button"]');
}

/**
 * Full register → create → join → start sequence.
 * Registers each player with a unique name, creates a room, joins all others,
 * waits for start button to be enabled, starts the game, and waits for all
 * players to see the game board.
 */
export async function setupGame(players: Player[]): Promise<void> {
  const suffix = Date.now();

  await Promise.all(
    players.map((p, i) => registerOrLogin(p.page, `${p.name}-${suffix}-${i}`)),
  );

  const roomCode = await createRoom(players[0].page);

  await Promise.all(players.slice(1).map((p) => joinRoom(p.page, roomCode)));

  await expect(players[0].page.locator('[data-testid="start-game-button"]')).toBeEnabled({
    timeout: 8_000,
  });

  await startGame(players[0].page);

  await Promise.all(players.map((p) => waitForGameBoard(p.page)));

  // Wait for ActionBar to be fully rendered on every player's page before
  // returning.  waitForGameBoard confirms gameState !== null (game-board visible),
  // but the ActionBar's buttons are set in the same React render cycle via
  // Zustand — page.evaluate() instant checks can race against that first render.
  await Promise.all(
    players.map((p) =>
      p.page.waitForFunction(
        () => !!document.querySelector('[data-testid="pass-button"]'),
        { timeout: 6_000 },
      ),
    ),
  );
}

/**
 * Returns the player whose pass-button is currently enabled (= their turn).
 * Returns null when no player's ActionBar is visible (game over).
 *
 * Uses `page.evaluate()` (instant DOM snapshot) rather than `locator.isEnabled()`.
 * `isEnabled()` waits up to the actionTimeout (15s) for the element to appear
 * in the DOM.  When the ActionBar unmounts at game end, this hangs — and the
 * next game's button re-appears within 3 s, causing the loop to roll into the
 * next game instead of stopping.  `evaluate()` returns the current DOM state
 * with zero latency.
 */
export async function findActivePage(players: Player[]): Promise<Player | null> {
  const results = await Promise.all(
    players.map(async (p) => ({
      player: p,
      isEnabled: await p.page
        .evaluate(() => {
          const btn = document.querySelector(
            '[data-testid="pass-button"]',
          ) as HTMLButtonElement | null;
          return !!(btn && !btn.disabled);
        })
        .catch(() => false),
    })),
  );
  const active = results.find((r) => r.isEnabled);
  return active ? active.player : null;
}

/**
 * Plays a card or passes, depending on pile state.
 *
 * Strategy:
 *   - Empty pile (we are the round leader): play the first card in hand.
 *     Any card is a valid lead, and the play button enables immediately
 *     when a card is selected (ActionBar: disabled={!isMyTurn || selectedCards.length === 0}).
 *   - Pile has cards: pass. This is always safe and keeps the loop fast.
 *     After the threshold number of consecutive passes the pile clears,
 *     handing the lead back to the appropriate player.
 *
 * IMPORTANT: we check the pile label text ("Pile (empty)") rather than
 * data-testid="pile-top" visibility.  The PileDisplay uses AnimatePresence
 * mode="wait", which keeps the outgoing card in the DOM for ~200ms during
 * its exit animation even after topPlay becomes null.  The label <span> is
 * outside AnimatePresence and updates instantly, making it a reliable signal.
 *
 * Returns true if a card was played, false if we passed.
 */
export async function tryPlayFirstCard(page: Page): Promise<boolean> {
  // "Pile (empty)" text appears instantly when pile.history === [] — no animation lag
  const pileIsEmpty = await page
    .getByText('Pile (empty)', { exact: true })
    .isVisible()
    .catch(() => false);

  if (pileIsEmpty) {
    // Empty pile — lead with the first card in hand
    const firstCard = page
      .locator('[data-testid="local-hand"] [data-testid^="card-"]')
      .first();
    await firstCard.click(); // selects the card
    await page.click('[data-testid="play-button"]');
    return true;
  }

  // Pile has cards (or transitioning) — pass
  await page.click('[data-testid="pass-button"]');
  return false;
}

/**
 * After a play/pass, waits for the current player's turn to end.
 *
 * Uses `waitForFunction` so we can check two conditions simultaneously in the
 * browser context:
 *   (a) pass-button is now disabled  → turn moved to another player
 *   (b) pass-button no longer exists → ActionBar unmounted (game finished)
 *
 * This resolves immediately when the game ends, unlike `expect.toBeDisabled`
 * which would wait the full timeout for a missing element.
 */
export async function waitForTurnToAdvance(page: Page): Promise<void> {
  await page
    .waitForFunction(
      () => {
        const btn = document.querySelector(
          '[data-testid="pass-button"]',
        ) as HTMLButtonElement | null;
        return !btn || btn.disabled;
      },
      { timeout: 6_000 },
    )
    .catch(() => {
      /* timeout is fine — game or navigation may have ended the ActionBar */
    });
}

/**
 * Returns the count of cards shown in the player's local hand.
 */
export async function getHandCount(page: Page): Promise<number> {
  return page.locator('[data-testid="local-hand"] [data-testid^="card-"]').count();
}

/**
 * Waits for the Game Results dialog to be visible.
 */
export async function waitForGameFinishedDialog(page: Page): Promise<void> {
  await expect(page.locator('[role="dialog"][aria-label="Game results"]')).toBeVisible({
    timeout: 10_000,
  });
}

/**
 * Waits for the Card Exchange dialog to appear.
 * The GameFinishedOverlay auto-closes after ~3-5s, then CardExchangeView opens.
 */
export async function waitForExchangeDialog(page: Page): Promise<void> {
  await expect(page.locator('[role="dialog"][aria-label="Card exchange"]')).toBeVisible({
    timeout: 12_000,
  });
}

/**
 * Drives a full game to completion by repeatedly finding the active player
 * and playing/passing until the Game Results dialog appears.
 * Throws if the game doesn't complete within MAX_TURNS.
 */
/** Instant DOM check — no locator timeout that would hide the game-end moment. */
async function isGameResultsVisible(page: Page): Promise<boolean> {
  return page
    .evaluate(
      () =>
        !!document.querySelector('[role="dialog"][aria-label="Game results"]'),
    )
    .catch(() => false);
}

export async function driveFullGame(players: Player[]): Promise<void> {
  const MAX_TURNS = 600; // 52 cards × ~10 passes worst case

  for (let i = 0; i < MAX_TURNS; i++) {
    // Instant check — no locator wait that might block across game boundaries
    if (await isGameResultsVisible(players[0].page)) return;

    // Find active player — retry briefly in case the server is mid-broadcast.
    // Each retry uses page.evaluate() (instant) so the whole loop runs in <100ms.
    let active: Player | null = null;
    for (let attempt = 0; attempt < 15; attempt++) {
      active = await findActivePage(players);
      if (active) break;
      if (await isGameResultsVisible(players[0].page)) return;
    }
    if (!active) return; // ActionBar gone = game over

    await tryPlayFirstCard(active.page);
    await waitForTurnToAdvance(active.page);

    // Extra instant check right after turn advance — game may have just ended.
    if (await isGameResultsVisible(players[0].page)) return;
  }

  throw new Error(`Game did not complete within ${MAX_TURNS} turns`);
}
