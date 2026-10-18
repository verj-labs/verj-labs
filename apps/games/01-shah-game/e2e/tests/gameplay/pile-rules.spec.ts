/**
 * Pile Rules: verify pile mechanics — first play visibility,
 * inactive player restrictions, and consecutive passes clearing the pile.
 */
import { expect } from '@playwright/test';
import { test } from '../../fixtures/game.fixture';
import {
  setupGame,
  findActivePage,
  tryPlayFirstCard,
  waitForTurnToAdvance,
} from '../../helpers/game';

test.describe('Pile Rules', () => {
  test('first play on empty pile appears in all other players pile-top @smoke', async ({
    players,
  }) => {
    test.setTimeout(60_000);
    await setupGame(players);

    const active = await findActivePage(players);
    expect(active).not.toBeNull();

    await tryPlayFirstCard(active!.page);
    await waitForTurnToAdvance(active!.page);

    // All other players must see the pile-top
    const others = players.filter((p) => p !== active);
    await Promise.all(
      others.map((p) =>
        expect(p.page.locator('[data-testid="pile-top"]')).toBeVisible({ timeout: 2_000 }),
      ),
    );
  });

  test('non-active player card click does not enable play button', async ({ players }) => {
    test.setTimeout(30_000);
    await setupGame(players);

    const active = await findActivePage(players);
    expect(active).not.toBeNull();

    const inactive = players.find((p) => p !== active);
    expect(inactive).toBeDefined();

    // Force-click the first card in the inactive player's hand.
    // Cards are HTML-disabled when it's not your turn, so { force: true } is
    // required to bypass Playwright's "element must be enabled" check.
    const firstCard = inactive!.page
      .locator('[data-testid="local-hand"] [data-testid^="card-"]')
      .first();
    await firstCard.click({ force: true });

    // Play button must remain disabled — it's not their turn, so selecting a
    // card has no effect on the game state (onClick is undefined when disabled).
    await expect(inactive!.page.locator('[data-testid="play-button"]')).toBeDisabled({
      timeout: 1_000,
    });
  });

  test('all players passing consecutively clears the pile', async ({ players }) => {
    test.setTimeout(90_000);
    await setupGame(players);

    // Active player must play first (pile is empty — can play any single card)
    const firstActive = await findActivePage(players);
    expect(firstActive).not.toBeNull();

    await tryPlayFirstCard(firstActive!.page);
    await waitForTurnToAdvance(firstActive!.page);

    // The next 3 players all pass — 3 consecutive passes ends the round
    for (let i = 0; i < 3; i++) {
      const current = await findActivePage(players);
      if (!current) break; // game might be over (shouldn't happen this early)

      await current.page.click('[data-testid="pass-button"]');
      await waitForTurnToAdvance(current.page);
    }

    // After a full round of passes the pile should be cleared
    await Promise.all(
      players.map((p) =>
        expect(p.page.locator('[data-testid="pile-top"]')).not.toBeVisible({ timeout: 3_000 }),
      ),
    );
  });
});
