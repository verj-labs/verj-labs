/**
 * @smoke
 *
 * Smoke tests: can all 4 players connect, authenticate, and end up in the same
 * waiting room?
 *
 * These tests must pass before any other E2E tests are meaningful.
 * Run with: pnpm test -- --grep @smoke
 */
import { expect } from '@playwright/test';
import { test } from '../../fixtures/game.fixture';
import { registerOrLogin } from '../../helpers/auth';
import { createRoom, joinRoom } from '../../helpers/lobby';

test.describe('@smoke — basic connectivity', () => {
  test('all 4 players can register and land on the lobby page', async ({ players }) => {
    const [alice, bob, carol, dave] = players;

    // Each player registers independently
    await Promise.all([
      registerOrLogin(alice.page, `Alice-${Date.now()}`),
      registerOrLogin(bob.page, `Bob-${Date.now()}`),
      registerOrLogin(carol.page, `Carol-${Date.now()}`),
      registerOrLogin(dave.page, `Dave-${Date.now()}`),
    ]);

    // All should be on the lobby page
    await Promise.all(
      players.map((p) =>
        expect(p.page).toHaveURL(/\/lobby/, { timeout: 5_000 }),
      ),
    );
  });

  test('host creates a room and all others join — all see the waiting room', async ({
    players,
  }) => {
    const [alice, bob, carol, dave] = players;
    const suffix = Date.now();

    // Register all players
    await Promise.all([
      registerOrLogin(alice.page, `Alice-${suffix}`),
      registerOrLogin(bob.page, `Bob-${suffix}`),
      registerOrLogin(carol.page, `Carol-${suffix}`),
      registerOrLogin(dave.page, `Dave-${suffix}`),
    ]);

    // Alice creates the room
    const roomCode = await createRoom(alice.page);
    expect(roomCode).toHaveLength(4);

    // Others join
    await Promise.all([
      joinRoom(bob.page, roomCode),
      joinRoom(carol.page, roomCode),
      joinRoom(dave.page, roomCode),
    ]);

    // All 4 should be on a room page
    await Promise.all(
      players.map((p) =>
        expect(p.page).toHaveURL(/\/room\//, { timeout: 5_000 }),
      ),
    );

    // The room code should be visible on every player's screen
    await Promise.all(
      players.map((p) =>
        expect(p.page.locator('[data-testid="room-code"]')).toBeVisible({
          timeout: 4_000,
        }),
      ),
    );

    // Player count should reach 4 on all pages
    // Allow 10s — 3 sequential joins + WebSocket propagation per player
    await Promise.all(
      players.map((p) =>
        expect(p.page.locator('[data-testid="player-count"]')).toContainText(
          '4',
          { timeout: 10_000 },
        ),
      ),
    );
  });
});
