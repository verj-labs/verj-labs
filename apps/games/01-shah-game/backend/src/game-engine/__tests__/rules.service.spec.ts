import { RulesService } from '../rules.service';
import {
  card,
  makeGameState,
  makePlay,
  makePlayer,
} from './game-state.factory';
import { type PlayIntent } from '../../shared/types/events.types';

function makeService(): RulesService {
  return new RulesService();
}

// Helper: build a 4-player state where p0 is active and holds a small hand
function baseState() {
  return makeGameState({
    activePlayerIndex: 0,
    players: [
      makePlayer('p0', 0, [
        card('7'),
        card('7', 'hearts'),
        card('8'),
        card('9'),
        card('2'),
      ]),
      makePlayer('p1', 1, [card('J')]),
      makePlayer('p2', 2, [card('Q')]),
      makePlayer('p3', 3, [card('K')]),
    ],
  });
}

describe('RulesService.validatePlay()', () => {
  let svc: RulesService;

  beforeEach(() => {
    svc = makeService();
  });

  // ── Pass is always valid ────────────────────────────────────────────────────

  it('pass intent is always valid', () => {
    const intent: PlayIntent = { playerId: 'p0', type: 'pass' };
    const result = svc.validatePlay(baseState(), intent);
    expect(result.valid).toBe(true);
  });

  // ── No cards provided ────────────────────────────────────────────────────────

  it('returns invalid when cards array is empty', () => {
    const intent: PlayIntent = { playerId: 'p0', type: 'play', cards: [] };
    const result = svc.validatePlay(baseState(), intent);
    expect(result.valid).toBe(false);
    expect(result.reason).toBeTruthy();
  });

  // ── Player not found ─────────────────────────────────────────────────────────

  it('returns invalid for unknown player', () => {
    const intent: PlayIntent = {
      playerId: 'ghost',
      type: 'play',
      cards: [card('7')],
    };
    const result = svc.validatePlay(baseState(), intent);
    expect(result.valid).toBe(false);
  });

  // ── Not your turn ─────────────────────────────────────────────────────────────

  it("returns invalid when it is not the player's turn", () => {
    // activePlayerIndex=0 but p1 is trying to play
    const intent: PlayIntent = {
      playerId: 'p1',
      type: 'play',
      cards: [card('J')],
    };
    const result = svc.validatePlay(baseState(), intent);
    expect(result.valid).toBe(false);
    expect(result.reason).toMatch(/not your turn/i);
  });

  // ── Cards not in hand ─────────────────────────────────────────────────────────

  it("returns invalid when a card is not in the player's hand", () => {
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('A')], // p0 has no Ace
    };
    const result = svc.validatePlay(baseState(), intent);
    expect(result.valid).toBe(false);
    expect(result.reason).toMatch(/not in your hand/i);
  });

  // ── Mixed ranks ───────────────────────────────────────────────────────────────

  it('returns invalid when played cards have mixed ranks', () => {
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('7'), card('8')],
    };
    const result = svc.validatePlay(baseState(), intent);
    expect(result.valid).toBe(false);
    expect(result.reason).toMatch(/same rank/i);
  });

  // ── Empty pile — any set is valid ─────────────────────────────────────────────

  it('allows any single card on empty pile', () => {
    const state = baseState(); // topPlay = null by default
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('7')],
    };
    const result = svc.validatePlay(state, intent);
    expect(result.valid).toBe(true);
    expect(result.isReset).toBeFalsy();
  });

  it('allows a double set on empty pile', () => {
    const state = baseState();
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('7'), card('7', 'hearts')],
    };
    const result = svc.validatePlay(state, intent);
    expect(result.valid).toBe(true);
  });

  it('allows a triple set on empty pile', () => {
    const state = makeGameState({
      activePlayerIndex: 0,
      players: [
        makePlayer('p0', 0, [card('K'), card('K', 'hearts'), card('K', 'diamonds')]),
      ],
    });
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('K'), card('K', 'hearts'), card('K', 'diamonds')],
    };
    expect(svc.validatePlay(state, intent).valid).toBe(true);
  });

  it('allows a quad set on empty pile', () => {
    const state = makeGameState({
      activePlayerIndex: 0,
      players: [
        makePlayer('p0', 0, [
          card('A'),
          card('A', 'hearts'),
          card('A', 'diamonds'),
          card('A', 'clubs'),
        ]),
      ],
    });
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('A'), card('A', 'hearts'), card('A', 'diamonds'), card('A', 'clubs')],
    };
    expect(svc.validatePlay(state, intent).valid).toBe(true);
  });

  // ── Wrong set size ────────────────────────────────────────────────────────────

  it('returns invalid when set size does not match pile set size', () => {
    // Pile has a single card
    const state = makeGameState({
      activePlayerIndex: 0,
      players: [makePlayer('p0', 0, [card('9'), card('9', 'hearts')])],
      topPlay: makePlay([card('7')], 'p1'),
    });
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('9'), card('9', 'hearts')],
    };
    const result = svc.validatePlay(state, intent);
    expect(result.valid).toBe(false);
    expect(result.reason).toMatch(/1-card set/i);
  });

  it('returns invalid when playing a single on a three-card pile', () => {
    const state = makeGameState({
      activePlayerIndex: 0,
      players: [makePlayer('p0', 0, [card('A')])],
      topPlay: makePlay(
        [card('K'), card('K', 'hearts'), card('K', 'diamonds')],
        'p1',
      ),
    });
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('A')],
    };
    const result = svc.validatePlay(state, intent);
    expect(result.valid).toBe(false);
    expect(result.reason).toMatch(/3-card set/i);
  });

  it('returns invalid when playing a triple on a one-card pile', () => {
    const state = makeGameState({
      activePlayerIndex: 0,
      players: [
        makePlayer('p0', 0, [card('A'), card('A', 'hearts'), card('A', 'diamonds')]),
      ],
      topPlay: makePlay([card('K')], 'p1'),
    });
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('A'), card('A', 'hearts'), card('A', 'diamonds')],
    };
    const result = svc.validatePlay(state, intent);
    expect(result.valid).toBe(false);
    expect(result.reason).toMatch(/1-card set/i);
  });

  // ── Rank too low ──────────────────────────────────────────────────────────────

  it('returns invalid when played rank is lower than the pile rank', () => {
    const state = makeGameState({
      activePlayerIndex: 0,
      players: [makePlayer('p0', 0, [card('5')])],
      topPlay: makePlay([card('9')], 'p1'),
    });
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('5')],
    };
    const result = svc.validatePlay(state, intent);
    expect(result.valid).toBe(false);
    expect(result.reason).toMatch(/rank .* or higher/i);
  });

  // ── Same rank as pile ─────────────────────────────────────────────────────────

  it('allows playing the same rank as the pile top', () => {
    const state = makeGameState({
      activePlayerIndex: 0,
      players: [makePlayer('p0', 0, [card('9')])],
      topPlay: makePlay([card('9', 'hearts')], 'p1'),
    });
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('9')],
    };
    const result = svc.validatePlay(state, intent);
    expect(result.valid).toBe(true);
    expect(result.isReset).toBeFalsy();
  });

  // ── Higher rank ───────────────────────────────────────────────────────────────

  it('allows playing a higher rank than the pile top', () => {
    const state = makeGameState({
      activePlayerIndex: 0,
      players: [makePlayer('p0', 0, [card('K')])],
      topPlay: makePlay([card('9')], 'p1'),
    });
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('K')],
    };
    expect(svc.validatePlay(state, intent).valid).toBe(true);
  });

  // ── Multi-card plays on an active pile ───────────────────────────────────────

  describe('multi-card plays on active pile', () => {
    it('allows playing a triple same-rank on a triple pile', () => {
      // pile: triple Q (3 cards); play: triple Q (same rank — triggers skip rule)
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('Q'), card('Q', 'hearts'), card('Q', 'diamonds')]),
        ],
        topPlay: makePlay(
          [card('Q', 'hearts'), card('Q', 'diamonds'), card('Q', 'clubs')],
          'p1',
        ),
      });
      const intent: PlayIntent = {
        playerId: 'p0',
        type: 'play',
        cards: [card('Q'), card('Q', 'hearts'), card('Q', 'diamonds')],
      };
      const result = svc.validatePlay(state, intent);
      expect(result.valid).toBe(true);
      expect(result.isReset).toBeFalsy();
    });

    it('allows playing a triple higher-rank on a triple pile', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [card('K'), card('K', 'hearts'), card('K', 'diamonds')]),
        ],
        topPlay: makePlay(
          [card('Q'), card('Q', 'hearts'), card('Q', 'diamonds')],
          'p1',
        ),
      });
      const intent: PlayIntent = {
        playerId: 'p0',
        type: 'play',
        cards: [card('K'), card('K', 'hearts'), card('K', 'diamonds')],
      };
      expect(svc.validatePlay(state, intent).valid).toBe(true);
    });

    it('allows playing a quad higher-rank on a quad pile', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [
            card('A'),
            card('A', 'hearts'),
            card('A', 'diamonds'),
            card('A', 'clubs'),
          ]),
        ],
        topPlay: makePlay(
          [card('K'), card('K', 'hearts'), card('K', 'diamonds'), card('K', 'clubs')],
          'p1',
        ),
      });
      const intent: PlayIntent = {
        playerId: 'p0',
        type: 'play',
        cards: [card('A'), card('A', 'hearts'), card('A', 'diamonds'), card('A', 'clubs')],
      };
      expect(svc.validatePlay(state, intent).valid).toBe(true);
    });
  });

  // ── '2' on empty pile = valid normal play ─────────────────────────────────────

  it('playing a 2 on empty pile is a valid normal play (not a reset)', () => {
    const state = makeGameState({
      activePlayerIndex: 0,
      players: [makePlayer('p0', 0, [card('2')])],
      topPlay: null,
    });
    const intent: PlayIntent = {
      playerId: 'p0',
      type: 'play',
      cards: [card('2')],
    };
    const result = svc.validatePlay(state, intent);
    expect(result.valid).toBe(true);
    expect(result.isReset).toBeFalsy();
  });

  // ── Reset path: correct number of 2s ─────────────────────────────────────────

  describe('reset path', () => {
    it('one 2 resets a 1-card pile', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [makePlayer('p0', 0, [card('2')])],
        topPlay: makePlay([card('K')], 'p1'),
      });
      const intent: PlayIntent = {
        playerId: 'p0',
        type: 'play',
        cards: [card('2')],
      };
      const result = svc.validatePlay(state, intent);
      expect(result.valid).toBe(true);
      expect(result.isReset).toBe(true);
    });

    it('one 2 resets a 2-card pile', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [makePlayer('p0', 0, [card('2')])],
        topPlay: makePlay([card('K'), card('K', 'hearts')], 'p1'),
      });
      const intent: PlayIntent = {
        playerId: 'p0',
        type: 'play',
        cards: [card('2')],
      };
      const result = svc.validatePlay(state, intent);
      expect(result.valid).toBe(true);
      expect(result.isReset).toBe(true);
    });

    it('two 2s are required to reset a 3-card pile', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [makePlayer('p0', 0, [card('2'), card('2', 'hearts')])],
        topPlay: makePlay(
          [card('K'), card('K', 'hearts'), card('K', 'diamonds')],
          'p1',
        ),
      });
      const intent: PlayIntent = {
        playerId: 'p0',
        type: 'play',
        cards: [card('2'), card('2', 'hearts')],
      };
      const result = svc.validatePlay(state, intent);
      expect(result.valid).toBe(true);
      expect(result.isReset).toBe(true);
    });

    it('three 2s are required to reset a 4-card pile', () => {
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [
          makePlayer('p0', 0, [
            card('2'),
            card('2', 'hearts'),
            card('2', 'diamonds'),
          ]),
        ],
        topPlay: makePlay(
          [
            card('K'),
            card('K', 'hearts'),
            card('K', 'diamonds'),
            card('K', 'clubs'),
          ],
          'p1',
        ),
      });
      const intent: PlayIntent = {
        playerId: 'p0',
        type: 'play',
        cards: [card('2'), card('2', 'hearts'), card('2', 'diamonds')],
      };
      const result = svc.validatePlay(state, intent);
      expect(result.valid).toBe(true);
      expect(result.isReset).toBe(true);
    });

    it('returns invalid when too few 2s used for reset', () => {
      // 3-card pile requires 2 twos, but we only play 1
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [makePlayer('p0', 0, [card('2')])],
        topPlay: makePlay(
          [card('K'), card('K', 'hearts'), card('K', 'diamonds')],
          'p1',
        ),
      });
      const intent: PlayIntent = {
        playerId: 'p0',
        type: 'play',
        cards: [card('2')],
      };
      const result = svc.validatePlay(state, intent);
      expect(result.valid).toBe(false);
      expect(result.reason).toMatch(/reset/i);
    });

    it('returns invalid when too many 2s used for reset', () => {
      // 1-card pile requires only 1 two, but we play 2
      const state = makeGameState({
        activePlayerIndex: 0,
        players: [makePlayer('p0', 0, [card('2'), card('2', 'hearts')])],
        topPlay: makePlay([card('K')], 'p1'),
      });
      const intent: PlayIntent = {
        playerId: 'p0',
        type: 'play',
        cards: [card('2'), card('2', 'hearts')],
      };
      const result = svc.validatePlay(state, intent);
      expect(result.valid).toBe(false);
    });
  });
});
