import { type Rank } from '../../shared/types/card.types';
import {
  EXCHANGE_RANK_ORDER,
  PLAY_RANK_ORDER,
  compareExchangeRank,
  comparePlayRank,
  getResetRequirement,
  isReset,
} from '../rank.utils';

describe('rank.utils', () => {
  // ── Constants ───────────────────────────────────────────────────────────────

  describe('PLAY_RANK_ORDER', () => {
    it('has 12 entries (no 2)', () => {
      expect(PLAY_RANK_ORDER).toHaveLength(12);
      expect(PLAY_RANK_ORDER).not.toContain('2');
    });

    it('starts at 3 and ends at A', () => {
      expect(PLAY_RANK_ORDER[0]).toBe('3');
      expect(PLAY_RANK_ORDER[11]).toBe('A');
    });
  });

  describe('EXCHANGE_RANK_ORDER', () => {
    it('has 13 entries (includes 2 at the end)', () => {
      expect(EXCHANGE_RANK_ORDER).toHaveLength(13);
      expect(EXCHANGE_RANK_ORDER[12]).toBe('2');
    });
  });

  // ── comparePlayRank ─────────────────────────────────────────────────────────

  describe('comparePlayRank()', () => {
    it('returns negative when a < b', () => {
      expect(comparePlayRank('3', 'A')).toBeLessThan(0);
      expect(comparePlayRank('3', '4')).toBeLessThan(0);
      expect(comparePlayRank('9', 'K')).toBeLessThan(0);
    });

    it('returns 0 when a === b', () => {
      expect(comparePlayRank('K', 'K')).toBe(0);
      expect(comparePlayRank('3', '3')).toBe(0);
      expect(comparePlayRank('A', 'A')).toBe(0);
    });

    it('returns positive when a > b', () => {
      expect(comparePlayRank('A', '3')).toBeGreaterThan(0);
      expect(comparePlayRank('Q', 'J')).toBeGreaterThan(0);
    });

    const allRanks: Rank[] = [
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
      'A',
    ];
    it('is consistent across all adjacent pairs', () => {
      for (let i = 0; i < allRanks.length - 1; i++) {
        expect(comparePlayRank(allRanks[i], allRanks[i + 1])).toBeLessThan(0);
      }
    });
  });

  // ── compareExchangeRank ─────────────────────────────────────────────────────

  describe('compareExchangeRank()', () => {
    it('2 is the best card for exchange purposes', () => {
      expect(compareExchangeRank('2', 'A')).toBeGreaterThan(0);
      expect(compareExchangeRank('3', '2')).toBeLessThan(0);
    });
  });

  // ── isReset ─────────────────────────────────────────────────────────────────

  describe('isReset()', () => {
    it('returns true only for "2"', () => {
      expect(isReset('2')).toBe(true);
    });

    it.each([
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
      'A',
    ] as Rank[])('returns false for %s', (rank) => {
      expect(isReset(rank)).toBe(false);
    });
  });

  // ── getResetRequirement ──────────────────────────────────────────────────────

  describe('getResetRequirement()', () => {
    it('single pile requires 1 two', () => {
      expect(getResetRequirement(1)).toBe(1);
    });

    it('double pile requires 1 two', () => {
      expect(getResetRequirement(2)).toBe(1);
    });

    it('triple pile requires 2 twos', () => {
      expect(getResetRequirement(3)).toBe(2);
    });

    it('quad pile requires 3 twos', () => {
      expect(getResetRequirement(4)).toBe(3);
    });
  });
});
