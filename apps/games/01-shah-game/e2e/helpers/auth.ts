/**
 * Auth helpers for E2E tests.
 *
 * Each Playwright browser context is a fully isolated session, so each player
 * needs to register (or login) independently via the landing page UI.
 */
import { type Page } from '@playwright/test';

export async function registerOrLogin(page: Page, displayName: string): Promise<void> {
  await page.goto('/');
  // Fill in the display name and submit
  await page.fill('[data-testid="display-name-input"]', displayName);
  await page.click('[data-testid="start-button"]');
  // Wait until we're redirected into the lobby (authenticated)
  await page.waitForURL('**/lobby', { timeout: 8_000 });
}
