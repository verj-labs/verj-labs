import { Test } from '@nestjs/testing';
import { GameEngineService } from '../game-engine.service';
import { RulesService } from '../rules.service';
import {
  card,
  makeGameState,
  makePlay,
  makePlayer,
} from './game-state.factory';
import { type PlayIntent } from '../../shared/types/events.types';

async function buildSvc(): Promise<GameEngineService> {
  const module = await Test.createTestingModule({
    providers: [GameEngineService, RulesService],
  }).compile();
  return module.get(GameEngineService);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function passIntent(playerId: string): PlayIntent {
  return { playerId, type: 'pass' };
}

function playIntent(
  playerId: string,
  cards: ReturnType<typeof card>[],
): PlayIntent {
  return { playerId, type: 'play', cards };
}

// ─── Test suite ───────────────────────────────────────────────────────────────

describe('GameEngineService.processIntent()', () => {
  let svc: GameEngineService;

  beforeEach(async () => {
    svc = await buildSvc();
  });

  // ── Immutability ─────────────────────────────────────────────────────────────

  describe('immutability', () => {
    it('does not mutate the original state on a valid play', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('7')]),
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
      });
      const originalHand = [...state.players[0].hand];
      svc.processIntent(state, playIntent('p0', [card('7')]));
      // Original hand must be unchanged
      expect(state.players[0].hand).toEqual(originalHand);
    });

    it('does not mutate the original state on a pass', () => {
      const state = makeGameState({ activePlayerIndex: 0 });
      const originalPassCount = state.currentRound.consecutivePassCount;
      svc.processIntent(state, passIntent('p0'));
      expect(state.currentRound.consecutivePassCount).toBe(originalPassCount);
    });
  });

  // ── Error path ───────────────────────────────────────────────────────────────

  describe('invalid play', () => {
    it('returns error and original state reference when play is invalid', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('5')]),
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
        topPlay: makePlay([card('9')], 'p3'),
      });

      const result = svc.processIntent(state, playIntent('p0', [card('5')]));

      expect(result.error).toBeTruthy();
      expect(result.newState).toBe(state); // same reference
      expect(result.events).toHaveLength(0);
    });
  });

  // ── Pass branch ───────────────────────────────────────────────────────────────

  describe('pass', () => {
    it('increments consecutivePassCount and emits PLAYER_PASSED + TURN_ADVANCED', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        lastPlayerId: 'p3',
      });

      const result = svc.processIntent(state, passIntent('p0'));

      expect(result.error).toBeUndefined();
      expect(result.newState.currentRound.consecutivePassCount).toBe(1);
      expect(result.newState.activePlayerIndex).toBe(1);

      const types = result.events.map((e) => e.type);
      expect(types).toContain('PLAYER_PASSED');
      expect(types).toContain('TURN_ADVANCED');
    });

    it('ends the round when consecutivePassCount reaches activeCount - 1', () => {
      // 4 active players; we need 3 consecutive passes to end the round.
      // Set up state where 2 passes have already happened and p0 passes again.
      const state = makeGameState({
        activePlayerIndex: 0,
        consecutivePassCount: 2,
        lastPlayerId: 'p3',
      });

      const result = svc.processIntent(state, passIntent('p0'));

      const roundEndEvent = result.events.find((e) => e.type === 'ROUND_ENDED');
      expect(roundEndEvent).toBeDefined();

      // After round ends, active player should be last player who played
      expect(result.newState.activePlayerIndex).toBe(3); // p3 index
      // Pile should be cleared
      expect(result.newState.currentRound.pile.topPlay).toBeNull();
      expect(result.newState.currentRound.consecutivePassCount).toBe(0);
    });

    it('does not end round if passes < activeCount - 1', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        consecutivePassCount: 1,
        lastPlayerId: 'p3',
      });

      const result = svc.processIntent(state, passIntent('p0'));

      expect(
        result.events.find((e) => e.type === 'ROUND_ENDED'),
      ).toBeUndefined();
    });
  });

  // ── Normal play branch ────────────────────────────────────────────────────────

  describe('normal play', () => {
    it('removes played cards from hand and updates the pile', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('9'), card('9', 'hearts')]),
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
        topPlay: makePlay([card('7'), card('7', 'hearts')], 'p3'),
      });

      const result = svc.processIntent(
        state,
        playIntent('p0', [card('9'), card('9', 'hearts')]),
      );

      expect(result.error).toBeUndefined();
      // Hand now empty
      expect(result.newState.players[0].hand).toHaveLength(0);
      // Pile updated
      expect(result.newState.currentRound.pile.topPlay?.cards[0].rank).toBe(
        '9',
      );
      // consecutivePassCount reset to 0
      expect(result.newState.currentRound.consecutivePassCount).toBe(0);
    });

    it('emits PILE_UPDATED and TURN_ADVANCED events', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('J')]),
          makePlayer('p1', 1, [card('Q')]),
          makePlayer('p2', 2, [card('K')]),
          makePlayer('p3', 3, [card('A')]),
        ],
      });

      const result = svc.processIntent(state, playIntent('p0', [card('J')]));
      const types = result.events.map((e) => e.type);
      expect(types).toContain('PILE_UPDATED');
      expect(types).toContain('TURN_ADVANCED');
    });

    it('emits PLAYER_SKIPPED when same rank is played', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('9')]),
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
        topPlay: makePlay([card('9', 'hearts')], 'p3'),
      });

      const result = svc.processIntent(state, playIntent('p0', [card('9')]));

      expect(
        result.events.find((e) => e.type === 'PLAYER_SKIPPED'),
      ).toBeDefined();
      // normal next=1, skip 1 more → 2
      expect(result.newState.activePlayerIndex).toBe(2);
    });

    it('finishes the active player AND applies same-rank skip simultaneously', () => {
      // p0 plays their only card which matches the pile rank (9)
      // → p0 finishes, same-rank rule skips p1, so p2 should get the turn
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('9')]), // last card — will finish
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
        topPlay: makePlay([card('9', 'hearts')], 'p3'),
      });

      const result = svc.processIntent(state, playIntent('p0', [card('9')]));

      expect(result.newState.players[0].isFinished).toBe(true);
      expect(
        result.events.find((e) => e.type === 'PLAYER_FINISHED'),
      ).toBeDefined();
      expect(
        result.events.find((e) => e.type === 'PLAYER_SKIPPED'),
      ).toBeDefined();
      // p0 finished → no longer advances; same-rank skip still applies → p1 skipped → p2 active
      expect(result.newState.activePlayerIndex).toBe(2);
    });

    it('advances normally (no skip) on higher rank play', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('K')]),
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('A')]),
        ],
        topPlay: makePlay([card('9')], 'p3'),
      });

      const result = svc.processIntent(state, playIntent('p0', [card('K')]));
      expect(
        result.events.find((e) => e.type === 'PLAYER_SKIPPED'),
      ).toBeUndefined();
      expect(result.newState.activePlayerIndex).toBe(1);
    });

    it('marks player as finished and emits PLAYER_FINISHED when hand becomes empty', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('K')]), // only card
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('A')]),
        ],
      });

      const result = svc.processIntent(state, playIntent('p0', [card('K')]));

      expect(result.newState.players[0].isFinished).toBe(true);
      expect(result.newState.players[0].finishRank).toBe(1);
      expect(result.newState.finishedPlayers).toContain('p0');

      expect(
        result.events.find((e) => e.type === 'PLAYER_FINISHED'),
      ).toBeDefined();
    });

    it('emits GAME_FINISHED when all players finish', () => {
      // 2-player game: each has 1 card; p0 plays its last card
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('K')]),
          makePlayer('p1', 1, [], { isFinished: true, finishRank: 1 }),
        ],
        finishedPlayers: ['p1'],
      });

      const result = svc.processIntent(state, playIntent('p0', [card('K')]));
      expect(result.newState.status).toBe('finished');
      expect(
        result.events.find((e) => e.type === 'GAME_FINISHED'),
      ).toBeDefined();
    });
  });

  // ── Multi-card (double) plays ─────────────────────────────────────────────────

  describe('multi-card plays', () => {
    it('playing a double removes 2 cards from hand and updates pile', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('9'), card('9', 'hearts'), card('5')]),
          makePlayer('p1', 1, [card('J'), card('J', 'hearts')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
        topPlay: makePlay([card('7'), card('7', 'hearts')], 'p3'),
      });

      const result = svc.processIntent(
        state,
        playIntent('p0', [card('9'), card('9', 'hearts')]),
      );

      expect(result.error).toBeUndefined();
      // Both 9s removed; only '5' remains
      expect(result.newState.players[0].hand).toHaveLength(1);
      expect(result.newState.players[0].hand[0].rank).toBe('5');
      // Pile updated with a 2-card play
      expect(result.newState.currentRound.pile.topPlay?.cards).toHaveLength(2);
      expect(result.newState.currentRound.pile.topPlay?.cards[0].rank).toBe('9');
      expect(result.newState.currentRound.consecutivePassCount).toBe(0);
    });

    it('playing a double same-rank emits PLAYER_SKIPPED and advances 2 slots', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('9'), card('9', 'hearts'), card('5')]),
          makePlayer('p1', 1, [card('J'), card('J', 'hearts')]),
          makePlayer('p2', 2, [card('Q'), card('Q', 'hearts')]),
          makePlayer('p3', 3, [card('K'), card('K', 'hearts')]),
        ],
        topPlay: makePlay([card('9', 'diamonds'), card('9', 'clubs')], 'p3'),
      });

      const result = svc.processIntent(
        state,
        playIntent('p0', [card('9'), card('9', 'hearts')]),
      );

      expect(result.events.find((e) => e.type === 'PLAYER_SKIPPED')).toBeDefined();
      // Normal next=1, skip one more active → 2
      expect(result.newState.activePlayerIndex).toBe(2);
    });
  });

  // ── Auto-finish and active-player edge cases ──────────────────────────────────

  describe('auto-finish and active-player edge cases', () => {
    it('auto-ranks the last remaining player when the penultimate player finishes', () => {
      // p0 and p1 already finished. p2 plays their last card.
      // Only p3 remains with cards → auto-ranked 4th, GAME_FINISHED fires.
      const state = makeGameState({
        activePlayerIndex: 2,
        players: [
          makePlayer('p0', 0, [], { isFinished: true, finishRank: 1 }),
          makePlayer('p1', 1, [], { isFinished: true, finishRank: 2 }),
          makePlayer('p2', 2, [card('K')]),
          makePlayer('p3', 3, [card('3'), card('4')]), // still has cards; auto-ranked last
        ],
        finishedPlayers: ['p0', 'p1'],
      });

      const result = svc.processIntent(state, playIntent('p2', [card('K')]));

      // p2 finishes 3rd
      expect(result.newState.players[2].isFinished).toBe(true);
      expect(result.newState.players[2].finishRank).toBe(3);

      // p3 is auto-assigned 4th place (did not need to empty their hand)
      expect(result.newState.players[3].isFinished).toBe(true);
      expect(result.newState.players[3].finishRank).toBe(4);

      // Game ends
      expect(result.newState.status).toBe('finished');
      expect(result.events.find((e) => e.type === 'GAME_FINISHED')).toBeDefined();

      // Two PLAYER_FINISHED events: one for p2 (explicit), one for p3 (auto)
      const finishedEvents = result.events.filter((e) => e.type === 'PLAYER_FINISHED');
      expect(finishedEvents).toHaveLength(2);
    });

    it('consecutivePassCount resets to 0 after a 2 reset', () => {
      // Two passes had already occurred; then p0 plays a 2 (reset).
      // Pass count must return to 0 so the new round starts clean.
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('2'), card('9')]),
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
        consecutivePassCount: 2,
        topPlay: makePlay([card('A')], 'p3'),
      });

      const result = svc.processIntent(state, playIntent('p0', [card('2')]));

      expect(result.error).toBeUndefined();
      expect(result.newState.currentRound.consecutivePassCount).toBe(0);
    });

    it('round ends after one pass when only two players remain active', () => {
      // p0 and p1 are finished. p2 played last (pile active). p3 is active and passes.
      // activeCount=2, lastPlayer (p2) is still active → threshold = 2-1 = 1.
      // p3's single pass meets the threshold → round ends, p2 leads next round.
      const state = makeGameState({
        activePlayerIndex: 3,
        players: [
          makePlayer('p0', 0, [], { isFinished: true, finishRank: 1 }),
          makePlayer('p1', 1, [], { isFinished: true, finishRank: 2 }),
          makePlayer('p2', 2, [card('5'), card('6')]),
          makePlayer('p3', 3, [card('3'), card('4')]),
        ],
        consecutivePassCount: 0,
        lastPlayerId: 'p2',
        topPlay: makePlay([card('A')], 'p2'),
        finishedPlayers: ['p0', 'p1'],
      });

      const result = svc.processIntent(state, passIntent('p3'));

      expect(result.events.find((e) => e.type === 'ROUND_ENDED')).toBeDefined();
      expect(result.newState.currentRound.pile.topPlay).toBeNull();
      expect(result.newState.currentRound.consecutivePassCount).toBe(0);
      // Round winner (p2) starts next round
      expect(result.newState.activePlayerIndex).toBe(2);
    });

    it('gives the next active player the turn when the round winner has since finished', () => {
      // p0 and p1 are finished; p1 was the last to play but is now also finished.
      // Both active players (p2 and p3) must pass (threshold = activeCount = 2).
      // p2 passed first (consecutivePassCount=1). p3 now passes → round ends.
      // endRound: lastPlayerId='p1' is finished → turn falls to next active after p1 (→ p2).
      const state = makeGameState({
        activePlayerIndex: 3,
        players: [
          makePlayer('p0', 0, [], { isFinished: true, finishRank: 1 }),
          makePlayer('p1', 1, [], { isFinished: true, finishRank: 2 }), // was lastPlayerId, now finished
          makePlayer('p2', 2, [card('5'), card('6'), card('7')]),
          makePlayer('p3', 3, [card('3'), card('4'), card('8')]),
        ],
        consecutivePassCount: 1, // p2 already passed
        lastPlayerId: 'p1',
        topPlay: makePlay([card('A')], 'p1'),
        finishedPlayers: ['p0', 'p1'],
      });

      const result = svc.processIntent(state, passIntent('p3'));

      // activeCount=2, lastPlayer (p1) is finished → threshold=2; passCount 1→2 ≥ 2 → round ends
      expect(result.events.find((e) => e.type === 'ROUND_ENDED')).toBeDefined();
      expect(result.newState.currentRound.pile.topPlay).toBeNull();
      // p1 (index 1) is finished → next active clockwise from 1 = p2 (index 2)
      expect(result.newState.activePlayerIndex).toBe(2);
    });
  });

  // ── Reset branch ──────────────────────────────────────────────────────────────

  describe('reset', () => {
    it('clears the pile and emits PILE_RESET', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('2')]),
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
        topPlay: makePlay([card('A')], 'p3'),
      });

      const result = svc.processIntent(state, playIntent('p0', [card('2')]));

      expect(result.newState.currentRound.pile.topPlay).toBeNull();
      expect(result.events.find((e) => e.type === 'PILE_RESET')).toBeDefined();
    });

    it('does NOT advance the turn — same player continues', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('2'), card('9')]), // 2 cards so p0 doesn't finish
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
        topPlay: makePlay([card('A')], 'p3'),
      });

      const result = svc.processIntent(state, playIntent('p0', [card('2')]));

      // Active player index stays at 0
      expect(result.newState.activePlayerIndex).toBe(0);
    });

    it("removes the 2 from the player's hand", () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('2'), card('9')]),
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
        topPlay: makePlay([card('A')], 'p3'),
      });

      const result = svc.processIntent(state, playIntent('p0', [card('2')]));

      const hand = result.newState.players[0].hand;
      expect(hand.every((c) => c.rank !== '2')).toBe(true);
      expect(hand).toHaveLength(1);
    });

    it('marks player finished when reset uses last card', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('2')]), // only card
          makePlayer('p1', 1, [card('J')]),
          makePlayer('p2', 2, [card('Q')]),
          makePlayer('p3', 3, [card('K')]),
        ],
        topPlay: makePlay([card('A')], 'p3'),
      });

      const result = svc.processIntent(state, playIntent('p0', [card('2')]));
      expect(result.newState.players[0].isFinished).toBe(true);
      expect(
        result.events.find((e) => e.type === 'PLAYER_FINISHED'),
      ).toBeDefined();
    });
  });
});
