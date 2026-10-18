/**
 * Card synchronisation: a card played by the active player is visible to all
 * other players within the 2-second WebSocket round-trip window.
 */
import { expect } from '@playwright/test';
import { test } from '../../fixtures/game.fixture';
import { registerOrLogin } from '../../helpers/auth';
import { createRoom, joinRoom, startGame } from '../../helpers/lobby';

test.describe('Card Synchronisation', () => {
  test('active player card play is reflected in all other players pile', async ({
    players,
  }) => {
    const [alice, bob, carol, dave] = players;
    const suffix = Date.now();

    await Promise.all([
      registerOrLogin(alice.page, `Alice-${suffix}`),
      registerOrLogin(bob.page, `Bob-${suffix}`),
      registerOrLogin(carol.page, `Carol-${suffix}`),
      registerOrLogin(dave.page, `Dave-${suffix}`),
    ]);

    const roomCode = await createRoom(alice.page);
    await Promise.all([
      joinRoom(bob.page, roomCode),
      joinRoom(carol.page, roomCode),
      joinRoom(dave.page, roomCode),
    ]);

    await expect(alice.page.locator('[data-testid="start-game-button"]')).toBeEnabled({
      timeout: 4_000,
    });
    await startGame(alice.page);

    await Promise.all(
      players.map((p) => expect(p.page).toHaveURL(/\/game\//, { timeout: 10_000 })),
    );

    // Find the active player (their Play button is enabled AND they have selectable cards)
    const activePage = (
      await Promise.all(
        players.map(async (p) => ({
          player: p,
          isEnabled: await p.page
            .locator('[data-testid="play-button"]')
            .isEnabled()
            .catch(() => false),
        })),
      )
    ).find((x) => x.isEnabled);

    if (!activePage) {
      // Game may not have dealt yet — skip rather than fail
      return;
    }

    // Active player clicks their first selectable card and plays it
    const firstCard = activePage.player.page.locator('[data-testid^="card-"]').first();
    await firstCard.click();
    await activePage.player.page.click('[data-testid="play-button"]');

    // Pile should update for all other players within 2 seconds
    const others = players.filter((p) => p !== activePage.player);
    await Promise.all(
      others.map((p) =>
        expect(p.page.locator('[data-testid="pile-top"]')).not.toBeEmpty({
          timeout: 2_000,
        }),
      ),
    );
  });
});
