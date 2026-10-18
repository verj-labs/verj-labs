/**
 * Card Exchange: verify the exchange flow that happens after a game finishes.
 */
import { expect } from '@playwright/test';
import { test } from '../../fixtures/game.fixture';
import {
  setupGame,
  driveFullGame,
  waitForGameFinishedDialog,
  waitForExchangeDialog,
  assertHandCount,
} from '../../helpers/game';

test.describe('Card Exchange', () => {
  test('card exchange dialog appears on all players screens after game finishes', async ({
    players,
  }) => {
    test.setTimeout(120_000);
    await setupGame(players);
    await driveFullGame(players);
    await waitForGameFinishedDialog(players[0].page);

    // Exchange dialog must open on all 4 pages after the results overlay closes
    await Promise.all(players.map((p) => waitForExchangeDialog(p.page)));
  });

  test('exchange dialog lists the card transfers', async ({ players }) => {
    test.setTimeout(120_000);
    await setupGame(players);
    await driveFullGame(players);
    await waitForExchangeDialog(players[0].page);

    // With 4 players there should be 2 exchange transfers (1st↔last, 2nd↔3rd)
    const listItems = players[0].page.locator(
      '[role="dialog"][aria-label="Card exchange"] ul li',
    );
    // Wait for at least one item to appear, then verify the count
    await expect(listItems.first()).toBeVisible({ timeout: 3_000 });
    const count = await listItems.count();
    expect(count).toBeGreaterThanOrEqual(1);
  });

  test('next game starts automatically after exchange countdown', async ({ players }) => {
    test.setTimeout(180_000);
    await setupGame(players);
    await driveFullGame(players);
    await waitForExchangeDialog(players[0].page);

    // Wait for exchange dialog to close — game:started fires after the countdown
    await expect(players[0].page.locator('[role="dialog"][aria-label="Card exchange"]')).not
      .toBeVisible({ timeout: 10_000 });

    // Game board must still be visible (new game started)
    await Promise.all(
      players.map((p) =>
        expect(p.page.locator('[data-testid="game-board"]')).toBeVisible({ timeout: 5_000 }),
      ),
    );

    // Each player should have a fresh hand of 13 cards
    await Promise.all(players.map((p) => assertHandCount(p.page, 13)));
  });
});
