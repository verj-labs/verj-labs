/**
 * Room management tests: create, join, start, invalid codes.
 */
import { expect } from '@playwright/test';
import { test } from '../../fixtures/game.fixture';
import { registerOrLogin } from '../../helpers/auth';
import { createRoom, joinRoom, startGame } from '../../helpers/lobby';

test.describe('Room Management', () => {
  test('non-host cannot see the Start Game button', async ({ players }) => {
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

    // Wait for all to settle
    await Promise.all(
      [bob, carol, dave].map((p) =>
        expect(p.page.locator('[data-testid="room-code"]')).toBeVisible({ timeout: 4_000 }),
      ),
    );

    // Non-hosts should NOT see the start button
    for (const p of [bob, carol, dave]) {
      await expect(p.page.locator('[data-testid="start-game-button"]')).not.toBeVisible();
    }
    // Host should see it
    await expect(alice.page.locator('[data-testid="start-game-button"]')).toBeVisible();
  });

  test('host can start game when 4 players are present — all navigate to game board', async ({
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

    // Wait for the start button to be ready
    await expect(alice.page.locator('[data-testid="start-game-button"]')).toBeEnabled({
      timeout: 4_000,
    });

    // Alice starts the game
    await startGame(alice.page);

    // All players navigate to /game/:matchId
    await Promise.all(
      players.map((p) =>
        expect(p.page).toHaveURL(/\/game\//, { timeout: 10_000 }),
      ),
    );
  });

  test('joining with invalid room code shows an error', async ({ players }) => {
    const [alice] = players;
    await registerOrLogin(alice.page, `Alice-${Date.now()}`);

    // Try to join a non-existent room
    await alice.page.fill('[data-testid="room-code-input"]', 'ZZZZ');
    await alice.page.click('[data-testid="join-room-button"]');

    // Expect an error message to appear
    await expect(alice.page.locator('[data-testid="join-error"]')).toBeVisible({
      timeout: 4_000,
    });
  });
});
