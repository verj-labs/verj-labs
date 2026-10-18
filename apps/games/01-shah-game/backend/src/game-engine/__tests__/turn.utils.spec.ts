import { determineDirection, getNextActivePlayerIndex } from '../turn.utils';
import { makeGameState, makePlayer } from './game-state.factory';

// Helper: build a fresh state with n unfinished players in clockwise direction
function fourPlayerCW() {
  return makeGameState({
    direction: 'clockwise',
    players: [
      makePlayer('p0', 0, []),
      makePlayer('p1', 1, []),
      makePlayer('p2', 2, []),
      makePlayer('p3', 3, []),
    ],
  });
}

describe('getNextActivePlayerIndex()', () => {
  describe('clockwise direction', () => {
    it('advances by one seat clockwise', () => {
      const state = fourPlayerCW();
      expect(getNextActivePlayerIndex(state, 0)).toBe(1);
      expect(getNextActivePlayerIndex(state, 2)).toBe(3);
    });

    it('wraps around the table', () => {
      const state = fourPlayerCW();
      expect(getNextActivePlayerIndex(state, 3)).toBe(0);
    });
  });

  describe('counterclockwise direction', () => {
    it('advances by one seat counterclockwise', () => {
      const state = makeGameState({
        direction: 'counterclockwise',
        players: [
          makePlayer('p0', 0, []),
          makePlayer('p1', 1, []),
          makePlayer('p2', 2, []),
          makePlayer('p3', 3, []),
        ],
      });
      expect(getNextActivePlayerIndex(state, 1)).toBe(0);
      expect(getNextActivePlayerIndex(state, 0)).toBe(3);
    });
  });

  describe('skipping finished players', () => {
    it('jumps over a single finished player', () => {
      const state = fourPlayerCW();
      state.players[1].isFinished = true;
      // current=0, next active after 1 is 2
      expect(getNextActivePlayerIndex(state, 0)).toBe(2);
    });

    it('jumps over two consecutive finished players', () => {
      const state = fourPlayerCW();
      state.players[1].isFinished = true;
      state.players[2].isFinished = true;
      // current=0, next active after 1,2 is 3
      expect(getNextActivePlayerIndex(state, 0)).toBe(3);
    });

    it('wraps and skips finished players', () => {
      const state = fourPlayerCW();
      state.players[0].isFinished = true;
      // current=3, next active skipping 0 is 1
      expect(getNextActivePlayerIndex(state, 3)).toBe(1);
    });
  });

  describe('skipCount (same-rank skip rule)', () => {
    it('skipCount=1 skips one extra active player', () => {
      const state = fourPlayerCW();
      // current=0, normal next=1, skip one more active → 2
      expect(getNextActivePlayerIndex(state, 0, 1)).toBe(2);
    });

    it('skipCount=1 wraps correctly', () => {
      const state = fourPlayerCW();
      // current=2, normal next=3, skip one more active → 0
      expect(getNextActivePlayerIndex(state, 2, 1)).toBe(0);
    });

    it('skipCount=1 combined with a finished player', () => {
      const state = fourPlayerCW();
      state.players[1].isFinished = true;
      // current=0, first active slot after 0 is 2 (skip 1 finished), then one more: 3
      expect(getNextActivePlayerIndex(state, 0, 1)).toBe(3);
    });
  });

  describe('edge cases', () => {
    it('returns -1 for empty players array', () => {
      const state = makeGameState({ players: [] });
      expect(getNextActivePlayerIndex(state, 0)).toBe(-1);
    });
  });
});

describe('determineDirection()', () => {
  describe('4-player table', () => {
    it('winner=0 2nd=1 → clockwise (right side)', () => {
      expect(determineDirection(0, 1, 4)).toBe('clockwise');
    });

    it('winner=0 2nd=3 → counterclockwise (left side)', () => {
      expect(determineDirection(0, 3, 4)).toBe('counterclockwise');
    });

    it('winner=0 2nd=2 (exactly opposite) → clockwise (tie-break)', () => {
      expect(determineDirection(0, 2, 4)).toBe('clockwise');
    });

    it('winner=2 2nd=3 → clockwise', () => {
      expect(determineDirection(2, 3, 4)).toBe('clockwise');
    });
  });

  describe('5-player table', () => {
    it('winner=0 2nd=1 → clockwise', () => {
      expect(determineDirection(0, 1, 5)).toBe('clockwise');
    });

    it('winner=0 2nd=2 → clockwise (within floor(5/2)=2)', () => {
      expect(determineDirection(0, 2, 5)).toBe('clockwise');
    });

    it('winner=0 2nd=3 → counterclockwise (steps=3 > floor(5/2)=2)', () => {
      expect(determineDirection(0, 3, 5)).toBe('counterclockwise');
    });

    it('winner=0 2nd=4 → counterclockwise (steps=4)', () => {
      expect(determineDirection(0, 4, 5)).toBe('counterclockwise');
    });
  });

  describe('6-player table', () => {
    it('exactly opposite (steps=3) → clockwise tie-break', () => {
      expect(determineDirection(0, 3, 6)).toBe('clockwise');
    });

    it('winner=0 2nd=4 → counterclockwise (steps=4 > 3)', () => {
      expect(determineDirection(0, 4, 6)).toBe('counterclockwise');
    });
  });

  describe('8-player table', () => {
    it('winner=0 2nd=4 (exactly opposite) → clockwise tie-break', () => {
      expect(determineDirection(0, 4, 8)).toBe('clockwise');
    });

    it('winner=0 2nd=5 → counterclockwise', () => {
      expect(determineDirection(0, 5, 8)).toBe('counterclockwise');
    });
  });

  describe('wrap-around seat indices', () => {
    it('winner=3 2nd=0 in 4-player → clockwise', () => {
      // stepsClockwise = (0-3+4)%4 = 1 ≤ 2 → clockwise
      expect(determineDirection(3, 0, 4)).toBe('clockwise');
    });
  });

  describe('same-seat guard', () => {
    it('same winner and 2nd seat returns clockwise', () => {
      expect(determineDirection(1, 1, 4)).toBe('clockwise');
    });
  });
});
