/**
 * Multi-player Playwright fixture.
 *
 * Creates N isolated browser contexts (separate cookies + WebSocket sessions),
 * one per player. Each context gets its own page. Contexts are closed in teardown.
 *
 * Usage:
 * ```typescript
 * import { test, type Player } from '../fixtures/game.fixture';
 * import { expect } from '@playwright/test';
 *
 * test('all players see the room', async ({ players }) => {
 *   const [alice, bob, carol, dave] = players;
 *   // ...
 * });
 * ```
 */
import { test as base, type Browser, type BrowserContext, type Page } from '@playwright/test';

export type Player = {
  context: BrowserContext;
  page: Page;
  name: string;
};

export const test = base.extend<{ players: Player[] }>({
  players: async ({ browser }: { browser: Browser }, use: (value: Player[]) => Promise<void>) => {
    const names = ['Alice', 'Bob', 'Carol', 'Dave'];

    const players = await Promise.all(
      names.map(async (name) => {
        const context = await browser.newContext();
        const page = await context.newPage();
        return { context, page, name };
      }),
    );

    await use(players);

    // Teardown — always close all contexts
    await Promise.all(players.map((p) => p.context.close()));
  },
});
