/**
 * Match Lifecycle: host ending match, results page, and lobby navigation.
 */
import { expect } from '@playwright/test';
import { test } from '../../fixtures/game.fixture';
import { setupGame, driveFullGame, waitForGameFinishedDialog } from '../../helpers/game';

test.describe('Match Lifecycle', () => {
  test('host can end match from game results overlay — all navigate to /results', async ({
    players,
  }) => {
    test.setTimeout(120_000);
    await setupGame(players);
    await driveFullGame(players);
    await waitForGameFinishedDialog(players[0].page);

    // end-match-button is only visible to the host (players[0] = Alice)
    await expect(players[0].page.locator('[data-testid="end-match-button"]')).toBeVisible({
      timeout: 5_000,
    });
    await expect(players[1].page.locator('[data-testid="end-match-button"]')).not.toBeVisible({
      timeout: 3_000,
    });

    await players[0].page.click('[data-testid="end-match-button"]');

    // All 4 players land on /results
    await Promise.all(
      players.map((p) => expect(p.page).toHaveURL(/\/results/, { timeout: 10_000 })),
    );

    // Final standings must be visible on all pages
    await Promise.all(
      players.map((p) =>
        expect(p.page.locator('[data-testid="final-standings"]')).toBeVisible({ timeout: 5_000 }),
      ),
    );
  });

  test('results page lists all 4 players', async ({ players }) => {
    test.setTimeout(120_000);
    await setupGame(players);
    await driveFullGame(players);
    await waitForGameFinishedDialog(players[0].page);

    await players[0].page.click('[data-testid="end-match-button"]');
    await expect(players[0].page).toHaveURL(/\/results/, { timeout: 10_000 });

    // There should be one standing-row per player
    const rows = players[0].page.locator('[data-testid^="standing-row-"]');
    await expect(rows).toHaveCount(4, { timeout: 5_000 });
  });

  test('back-to-lobby button returns to /lobby', async ({ players }) => {
    test.setTimeout(120_000);
    await setupGame(players);
    await driveFullGame(players);
    await waitForGameFinishedDialog(players[0].page);

    await players[0].page.click('[data-testid="end-match-button"]');
    await expect(players[0].page).toHaveURL(/\/results/, { timeout: 10_000 });

    await players[0].page.click('[data-testid="back-to-lobby-button"]');
    await expect(players[0].page).toHaveURL(/\/lobby/, { timeout: 5_000 });
  });
});
