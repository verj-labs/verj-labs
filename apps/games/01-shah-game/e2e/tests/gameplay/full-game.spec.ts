/**
 * Full Game Simulation: drive a complete 4-player game from start to finish.
 */
import { expect } from '@playwright/test';
import { test } from '../../fixtures/game.fixture';
import {
  setupGame,
  findActivePage,
  tryPlayFirstCard,
  waitForTurnToAdvance,
  getHandCount,
  waitForGameFinishedDialog,
  driveFullGame,
  assertHandCount,
} from '../../helpers/game';

test.describe('Full Game Simulation', () => {
  test('4 players complete a full game — game:finished dialog appears @smoke', async ({
    players,
  }) => {
    test.setTimeout(120_000);
    await setupGame(players);

    // Each player should start with 13 cards
    await Promise.all(players.map((p) => assertHandCount(p.page, 13)));

    await driveFullGame(players);

    // Game results dialog must be visible on all 4 pages
    await Promise.all(players.map((p) => waitForGameFinishedDialog(p.page)));

    // Dialog must contain a ranked list with 4 items
    const list = players[0].page.locator(
      '[role="dialog"][aria-label="Game results"] ul li',
    );
    await expect(list).toHaveCount(4, { timeout: 5_000 });
  });

  test('hand count decreases by 1 after the active player plays a single card', async ({
    players,
  }) => {
    test.setTimeout(60_000);
    await setupGame(players);

    const active = await findActivePage(players);
    expect(active).not.toBeNull();

    const before = await getHandCount(active!.page);

    const played = await tryPlayFirstCard(active!.page);

    if (played) {
      await waitForTurnToAdvance(active!.page);
      const after = await getHandCount(active!.page);
      expect(after).toBe(before - 1);
    } else {
      // Active player had no playable card and passed — hand is unchanged
      await waitForTurnToAdvance(active!.page);
      const after = await getHandCount(active!.page);
      expect(after).toBe(before);
    }
  });

  test('rank-1 winner is shown first in the game results dialog', async ({ players }) => {
    test.setTimeout(120_000);
    await setupGame(players);
    await driveFullGame(players);
    await waitForGameFinishedDialog(players[0].page);

    const firstItem = players[0].page
      .locator('[role="dialog"][aria-label="Game results"] ul li')
      .first();
    await expect(firstItem).toContainText('🥇', { timeout: 5_000 });
  });
});
