/**
 * Card selection UX tests
 *
 * 1. Same-rank filter   – after selecting a card, only cards of the same rank
 *    remain interactive; all other ranks are disabled.
 * 2. Pile-based filter  – when an active pile exists, only cards that can beat
 *    or reset the pile are enabled for the next player.
 * 3. Skip overlay       – when a same-rank play triggers the skip overlay it
 *    auto-dismisses and is never stuck visible.
 */
import { expect } from '@playwright/test';
import { test } from '../../fixtures/game.fixture';
import {
  setupGame,
  findActivePage,
  tryPlayFirstCard,
  waitForTurnToAdvance,
  waitForGameFinishedDialog,
} from '../../helpers/game';

// ─── Helpers shared across tests ─────────────────────────────────────────────

/** Rank → numeric sort order (mirrors frontend src/types/card.ts RANK_ORDER). */
const RANK_ORDER: Record<string, number> = {
  '3': 1,  '4': 2,  '5': 3,  '6': 4,  '7': 5,  '8': 6,
  '9': 7, '10': 8,  'J': 9,  'Q': 10, 'K': 11,  'A': 12, '2': 13,
};

/**
 * Given a card data-testid like "card-10clubs" or "card-Jhearts", return the
 * rank string ("10", "J", etc.).  Suit names are stripped from the end.
 */
function parseRankFromTestId(testId: string): string {
  const base = testId.replace(/^card-/, '');
  return base.replace(/hearts|diamonds|clubs|spades/, '');
}

// ─── Tests ────────────────────────────────────────────────────────────────────

test.describe('Card selection UX', () => {
  // ── 1. Same-rank filter ────────────────────────────────────────────────────

  test('selecting a card disables all cards of a different rank', async ({
    players,
  }) => {
    test.setTimeout(60_000);
    await setupGame(players);

    const active = await findActivePage(players);
    expect(active).not.toBeNull();

    const handLocator = active!.page.locator(
      '[data-testid="local-hand"] [data-testid^="card-"]',
    );

    // Need at least 2 cards to verify cross-rank disabling is meaningful
    const cardCount = await handLocator.count();
    if (cardCount < 2) return; // degenerate hand (should not happen in a 4-player game)

    // Click the first card to select it
    const firstCard = handLocator.first();
    await firstCard.click();

    // Verify aria-pressed="true" so we know selection registered
    await expect(firstCard).toHaveAttribute('aria-pressed', 'true', {
      timeout: 2_000,
    });

    // Evaluate DOM: every unselected card of a different rank must be disabled
    const allDisabledCorrectly = await active!.page.evaluate(() => {
      const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
      const parseRank = (testId: string) =>
        suits.reduce((id, s) => id.replace(s, ''), testId.replace('card-', ''));

      const cards = Array.from(
        document.querySelectorAll(
          '[data-testid="local-hand"] [data-testid^="card-"]',
        ),
      ) as HTMLButtonElement[];

      const selected = cards.find(
        (el) => el.getAttribute('aria-pressed') === 'true',
      );
      if (!selected) return { ok: false, reason: 'no card selected' };

      const selectedRank = parseRank(
        selected.getAttribute('data-testid') ?? '',
      );

      const violations: string[] = [];
      for (const el of cards) {
        if (el.getAttribute('aria-pressed') === 'true') continue; // skip selected
        const rank = parseRank(el.getAttribute('data-testid') ?? '');
        if (rank !== selectedRank) {
          const isDisabled =
            el.disabled || el.getAttribute('aria-disabled') === 'true';
          if (!isDisabled) {
            violations.push(
              `card ${el.getAttribute('data-testid')} (rank ${rank}) should be disabled`,
            );
          }
        }
      }

      return { ok: violations.length === 0, reason: violations.join('; ') };
    });

    expect(
      allDisabledCorrectly.ok,
      `Same-rank filter violated: ${allDisabledCorrectly.reason}`,
    ).toBe(true);
  });

  // ── 2. Pile-based filter ───────────────────────────────────────────────────

  test(
    'when pile has a single, only cards with rank ≥ pile rank or valid 2-reset are enabled',
    async ({ players }) => {
      test.setTimeout(60_000);
      await setupGame(players);

      // Active player leads a single card onto the empty pile
      const firstActive = await findActivePage(players);
      expect(firstActive).not.toBeNull();

      await tryPlayFirstCard(firstActive!.page);
      await waitForTurnToAdvance(firstActive!.page);

      // Find the next active player
      const nextActive = await findActivePage(players);
      // Guard: the first player may have finished (emptied their 1-card hand)
      if (!nextActive) return;

      // Verify pile-based filtering from the next active player's perspective
      const result = await nextActive.page.evaluate(() => {
        const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
        const parseRank = (testId: string) =>
          suits.reduce((id, s) => id.replace(s, ''), testId.replace('card-', ''));

        // Get pile rank from the first card inside the pile-top container
        const pileCardEl = document.querySelector(
          '[data-testid="pile-top"] [data-testid^="card-"]',
        );
        const pileRank = parseRank(
          pileCardEl?.getAttribute('data-testid') ?? '',
        );

        const cards = Array.from(
          document.querySelectorAll(
            '[data-testid="local-hand"] [data-testid^="card-"]',
          ),
        ) as HTMLButtonElement[];

        const enabledRanks: string[] = [];
        const disabledRanks: string[] = [];

        for (const el of cards) {
          const rank = parseRank(el.getAttribute('data-testid') ?? '');
          if (el.disabled || el.getAttribute('aria-disabled') === 'true') {
            disabledRanks.push(rank);
          } else {
            enabledRanks.push(rank);
          }
        }

        return { pileRank, enabledRanks, disabledRanks };
      });

      const pileValue = RANK_ORDER[result.pileRank] ?? 0;

      // Every disabled non-'2' card must have rank strictly below pile rank.
      // ('2' can only be disabled when the player has fewer 2s than required
      // for a reset; for a single pile that threshold is 1, so any '2' in hand
      // is enabled.)
      for (const rank of result.disabledRanks) {
        if (rank === '2') {
          // A '2' in hand against a single pile should always be enabled
          // (reset requirement is 1). We fail explicitly here to surface bugs.
          expect(rank, `'2' card should not be disabled vs. a single pile`).not.toBe('2');
        } else {
          expect(
            RANK_ORDER[rank],
            `disabled card rank "${rank}" must be below pile rank "${result.pileRank}"`,
          ).toBeLessThan(pileValue);
        }
      }

      // At least one card must be enabled (the player should have a valid play
      // or be able to pass — the action bar's pass button is the last resort,
      // but we verify the hand filter itself doesn't block everything)
      expect(
        result.enabledRanks.length,
        'At least one card must remain enabled when facing a single pile',
      ).toBeGreaterThan(0);
    },
  );

  // ── 3. Skip overlay auto-dismisses ────────────────────────────────────────

  test(
    'skip overlay auto-dismisses and is never stuck after a completed game',
    async ({ players }) => {
      test.setTimeout(180_000);
      await setupGame(players);

      const MAX_TURNS = 600;
      let skipObserved = false;

      const isGameOver = async (): Promise<boolean> => {
        const visible = await players[0].page
          .evaluate(
            () =>
              !!document.querySelector(
                '[role="dialog"][aria-label="Game results"]',
              ),
          )
          .catch(() => false);
        return visible;
      };

      for (let i = 0; i < MAX_TURNS; i++) {
        if (await isGameOver()) break;

        let active = null;
        for (let attempt = 0; attempt < 15; attempt++) {
          active = await findActivePage(players);
          if (active) break;
          if (await isGameOver()) break;
        }
        if (!active) break;

        await tryPlayFirstCard(active.page);

        // After each play, check all players for a skip overlay.
        // If found, assert it disappears within 2 s.
        for (const p of players) {
          const isVisible = await p.page
            .locator('[data-testid="skip-overlay-title"]')
            .isVisible()
            .catch(() => false);

          if (isVisible) {
            skipObserved = true;
            await expect(
              p.page.locator('[data-testid="skip-overlay-title"]'),
            ).not.toBeVisible({
              timeout: 2_000,
            });
          }
        }

        await waitForTurnToAdvance(active.page);
      }

      // Final hard assertion: overlay must not be visible on any player's screen
      await Promise.all(
        players.map((p) =>
          expect(
            p.page.locator('[data-testid="skip-overlay-title"]'),
          ).not.toBeVisible({ timeout: 1_500 }),
        ),
      );

      if (!skipObserved) {
        // eslint-disable-next-line no-console
        console.log(
          '[card-selection] No skip was triggered this run — ' +
            'test validity depends on stochastic card distribution.',
        );
      }

      // Confirm the game actually finished (not just exhausted MAX_TURNS)
      await waitForGameFinishedDialog(players[0].page);
    },
  );
});
