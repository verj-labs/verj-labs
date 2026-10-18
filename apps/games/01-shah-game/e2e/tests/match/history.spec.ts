/**
 * Match History: verify the history page is reachable and shows correct data.
 */
import { expect } from '@playwright/test';
import { test } from '../../fixtures/game.fixture';
import { registerOrLogin } from '../../helpers/auth';
import { setupGame, driveFullGame, waitForGameFinishedDialog } from '../../helpers/game';

test.describe('Match History', () => {
  test('lobby has a view-history button that navigates to /history @smoke', async ({
    players,
  }) => {
    const suffix = Date.now();
    await registerOrLogin(players[0].page, `Alice-hist-${suffix}`);

    // Lobby renders with a view-history button
    await expect(players[0].page.locator('[data-testid="view-history-button"]')).toBeVisible({
      timeout: 5_000,
    });

    await players[0].page.click('[data-testid="view-history-button"]');

    await expect(players[0].page).toHaveURL(/\/history/, { timeout: 5_000 });
  });

  test('history page shows empty state for a new player with no matches', async ({ players }) => {
    const suffix = Date.now();
    await registerOrLogin(players[0].page, `Alice-hist-empty-${suffix}`);

    await players[0].page.click('[data-testid="view-history-button"]');
    await expect(players[0].page).toHaveURL(/\/history/, { timeout: 5_000 });

    // Wait for loading to finish (skeletons disappear) then check empty state
    await expect(players[0].page.locator('[data-testid="history-skeleton"]')).not.toBeVisible({
      timeout: 6_000,
    });
    await expect(players[0].page.locator('[data-testid="history-empty"]')).toBeVisible({
      timeout: 3_000,
    });
  });

  test('history page shows a match card after the host ends the match', async ({ players }) => {
    test.setTimeout(180_000);
    await setupGame(players);
    await driveFullGame(players);
    await waitForGameFinishedDialog(players[0].page);

    // Host ends the match
    await players[0].page.click('[data-testid="end-match-button"]');
    await expect(players[0].page).toHaveURL(/\/results/, { timeout: 10_000 });

    // Navigate back to lobby then to history
    await players[0].page.click('[data-testid="back-to-lobby-button"]');
    await expect(players[0].page).toHaveURL(/\/lobby/, { timeout: 5_000 });

    await players[0].page.click('[data-testid="view-history-button"]');
    await expect(players[0].page).toHaveURL(/\/history/, { timeout: 5_000 });

    // Wait for skeletons to disappear (page has finished loading)
    await expect(players[0].page.locator('[data-testid="history-skeleton"]')).not.toBeVisible({
      timeout: 6_000,
    });

    // At least one history-item-* card must be visible — the match we just played
    await expect(
      players[0].page.locator('[data-testid^="history-item-"]').first(),
    ).toBeVisible({ timeout: 5_000 });
  });
});
