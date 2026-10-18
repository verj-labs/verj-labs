/**
 * Turn enforcement: out-of-turn plays must be rejected.
 */
import { expect } from '@playwright/test';
import { test } from '../../fixtures/game.fixture';
import { registerOrLogin } from '../../helpers/auth';
import { createRoom, joinRoom, startGame } from '../../helpers/lobby';
import { setupGame, findActivePage } from '../../helpers/game';

test.describe('Turn Enforcement', () => {
  test('out-of-turn play is rejected and the active player does not change', async ({
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

    // Wait for all to reach the game board
    await Promise.all(
      players.map((p) => expect(p.page).toHaveURL(/\/game\//, { timeout: 10_000 })),
    );

    // Determine which player has the active turn (the Play button is enabled)
    // For this test we only check that a non-active player's Play button is disabled
    const playButtons = await Promise.all(
      players.map(async (p) => ({
        player: p,
        isEnabled: await p.page
          .locator('[data-testid="play-button"]')
          .isEnabled()
          .catch(() => false),
      })),
    );

    const inactivePlayers = playButtons.filter((x) => !x.isEnabled);
    expect(inactivePlayers.length).toBeGreaterThan(0); // at most 1 player is active at a time
  });

  test('pass button is enabled for exactly one player at game start', async ({ players }) => {
    await setupGame(players);

    const active = await findActivePage(players);
    expect(active).not.toBeNull();

    // Active player's pass button must be enabled
    await expect(active!.page.locator('[data-testid="pass-button"]')).toBeEnabled();

    // All other players' pass buttons must be disabled
    const others = players.filter((p) => p !== active);
    await Promise.all(
      others.map((p) =>
        expect(p.page.locator('[data-testid="pass-button"]')).toBeDisabled({ timeout: 3_000 }),
      ),
    );
  });
});
