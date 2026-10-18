/**
 * Lobby / room helpers for E2E tests.
 */
import { type Page, expect } from '@playwright/test';
import { API_URL } from '../playwright.config';

/** Creates a new room and returns the 4-character room code. */
export async function createRoom(page: Page): Promise<string> {
  await page.click('[data-testid="create-room-button"]');
  // Wait for navigation to the waiting room and extract room code from the URL
  await page.waitForURL('**/room/**', { timeout: 6_000 });
  const roomCodeEl = page.locator('[data-testid="room-code"]');
  await expect(roomCodeEl).toBeVisible({ timeout: 4_000 });
  return (await roomCodeEl.innerText()).trim();
}

/** Joins an existing room by code. */
export async function joinRoom(page: Page, roomCode: string): Promise<void> {
  await page.fill('[data-testid="room-code-input"]', roomCode);
  await page.click('[data-testid="join-room-button"]');
  await page.waitForURL('**/room/**', { timeout: 6_000 });
}

/** Host clicks "Start Game" in the waiting room. */
export async function startGame(page: Page): Promise<void> {
  await page.click('[data-testid="start-game-button"]');
  // Wait for navigation to the game board
  await page.waitForURL('**/game/**', { timeout: 8_000 });
}

/**
 * Utility to call the API directly (bypasses UI) — useful for seeding state
 * that's hard to drive through the UI in tests.
 */
export async function apiPost(
  token: string,
  path: string,
  body?: Record<string, unknown>,
): Promise<Response> {
  return fetch(`${API_URL}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
}
