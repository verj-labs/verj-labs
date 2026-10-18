import { type Card } from '../../shared/types/card.types';
import { type Player } from '../../shared/types/game-state.types';
import { ExchangeService } from '../exchange.service';
import { card, makePlayer } from './game-state.factory';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function makeRankedPlayer(id: string, seatIndex: number, hand: Card[]): Player {
  return makePlayer(id, seatIndex, hand);
}

function countTotalCards(hands: Map<string, Card[]>): number {
  let total = 0;
  for (const h of hands.values()) total += h.length;
  return total;
}

function hasCard(hand: Card[], target: Card): boolean {
  return hand.some((c) => c.rank === target.rank && c.suit === target.suit);
}

// ─── Test suite ───────────────────────────────────────────────────────────────

describe('ExchangeService', () => {
  let service: ExchangeService;

  beforeEach(() => {
    service = new ExchangeService();
  });

  // ────────────────────────────────────────────────────────────────────────────
  // getWorstCards
  // ────────────────────────────────────────────────────────────────────────────

  describe('getWorstCards', () => {
    it('returns the N worst cards sorted worst-first', () => {
      const hand: Card[] = [
        card('K', 'hearts'),
        card('3', 'spades'),
        card('7', 'diamonds'),
        card('A', 'clubs'),
      ];
      const worst = service.getWorstCards(hand, 2);
      expect(worst).toHaveLength(2);
      expect(worst[0]).toEqual(card('3', 'spades')); // rank 0
      expect(worst[1]).toEqual(card('7', 'diamonds')); // rank 4
    });

    it('treats 2 as the highest rank (never in worst)', () => {
      const hand: Card[] = [card('2', 'spades'), card('3', 'hearts')];
      const worst = service.getWorstCards(hand, 1);
      expect(worst[0]).toEqual(card('3', 'hearts'));
    });

    it('uses suit as tiebreaker (spades worst, hearts best)', () => {
      const hand: Card[] = [
        card('5', 'hearts'),
        card('5', 'spades'),
        card('5', 'diamonds'),
      ];
      const worst = service.getWorstCards(hand, 1);
      expect(worst[0]).toEqual(card('5', 'spades'));
    });

    it('returns all cards when count >= hand.length', () => {
      const hand: Card[] = [card('J'), card('Q'), card('K')];
      expect(service.getWorstCards(hand, 5)).toHaveLength(3);
    });

    it('returns [] for empty hand', () => {
      expect(service.getWorstCards([], 2)).toEqual([]);
    });

    it('returns [] when count === 0', () => {
      expect(service.getWorstCards([card('3')], 0)).toEqual([]);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // getBestCards
  // ────────────────────────────────────────────────────────────────────────────

  describe('getBestCards', () => {
    it('returns the N best cards sorted best-first', () => {
      const hand: Card[] = [
        card('3', 'spades'),
        card('2', 'clubs'),
        card('A', 'hearts'),
        card('K', 'diamonds'),
      ];
      const best = service.getBestCards(hand, 2);
      expect(best).toHaveLength(2);
      expect(best[0]).toEqual(card('2', 'clubs')); // rank 12
      expect(best[1]).toEqual(card('A', 'hearts')); // rank 11 score 113
    });

    it('treats 2 as the highest rank (always first in best)', () => {
      const hand: Card[] = [card('A', 'hearts'), card('2', 'spades')];
      const best = service.getBestCards(hand, 1);
      expect(best[0]).toEqual(card('2', 'spades'));
    });

    it('uses suit tiebreaker (hearts best)', () => {
      const hand: Card[] = [
        card('J', 'spades'),
        card('J', 'hearts'),
        card('J', 'clubs'),
      ];
      const best = service.getBestCards(hand, 1);
      expect(best[0]).toEqual(card('J', 'hearts'));
    });

    it('returns all cards when count >= hand.length', () => {
      const hand: Card[] = [card('3'), card('4')];
      expect(service.getBestCards(hand, 10)).toHaveLength(2);
    });

    it('returns [] for empty hand', () => {
      expect(service.getBestCards([], 2)).toEqual([]);
    });

    it('returns [] when count === 0', () => {
      expect(service.getBestCards([card('2')], 0)).toEqual([]);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // computeExchange
  // ────────────────────────────────────────────────────────────────────────────

  describe('computeExchange', () => {
    it('returns empty actions when fewer than 3 players are ranked', () => {
      const players = [
        makeRankedPlayer('p0', 0, [card('3'), card('4'), card('5')]),
        makeRankedPlayer('p1', 1, [card('6'), card('7'), card('8')]),
      ];
      const result = service.computeExchange(players);
      expect(result.actions).toHaveLength(0);
    });

    it('3-player: produces exactly 2 exchange actions (1st↔1 last only)', () => {
      const players = [
        makeRankedPlayer('p0', 0, [
          card('K', 'hearts'),
          card('A', 'hearts'),
          card('2', 'hearts'),
        ]),
        makeRankedPlayer('p1', 1, [
          card('7', 'spades'),
          card('8', 'clubs'),
          card('9', 'diamonds'),
        ]),
        makeRankedPlayer('p2', 2, [
          card('3', 'spades'),
          card('3', 'clubs'),
          card('3', 'diamonds'),
        ]),
      ];
      const { actions } = service.computeExchange(players);
      // 2 for 1st↔last only, no middle pair
      expect(actions).toHaveLength(2);
    });

    it('4-player: produces exactly 4 exchange actions', () => {
      const players = [
        makeRankedPlayer('p0', 0, [
          card('K', 'hearts'),
          card('A', 'hearts'),
          card('2', 'hearts'),
        ]),
        makeRankedPlayer('p1', 1, [
          card('7', 'spades'),
          card('8', 'clubs'),
          card('9', 'diamonds'),
        ]),
        makeRankedPlayer('p2', 2, [
          card('6', 'spades'),
          card('5', 'clubs'),
          card('4', 'diamonds'),
        ]),
        makeRankedPlayer('p3', 3, [
          card('3', 'spades'),
          card('3', 'clubs'),
          card('3', 'diamonds'),
        ]),
      ];
      const { actions } = service.computeExchange(players);
      // 2 for 1st↔last + 2 for 2nd↔2nd-last
      expect(actions).toHaveLength(4);
    });

    it('4-player: 1st gives 2 worst to last; last gives 2 best to 1st', () => {
      // p0 hand (winner): 3♠, 4♠, 2♥ → worst 2 are 3♠, 4♠
      // p3 hand (loser):  K♥, A♥, 2♠  → best 2 are 2♠, A♥
      const p0 = makeRankedPlayer('p0', 0, [
        card('3', 'spades'),
        card('4', 'spades'),
        card('2', 'hearts'),
      ]);
      const p1 = makeRankedPlayer('p1', 1, [
        card('7', 'clubs'),
        card('8', 'clubs'),
        card('9', 'clubs'),
      ]);
      const p2 = makeRankedPlayer('p2', 2, [
        card('6', 'clubs'),
        card('5', 'clubs'),
        card('4', 'clubs'),
      ]);
      const p3 = makeRankedPlayer('p3', 3, [
        card('K', 'hearts'),
        card('A', 'hearts'),
        card('2', 'spades'),
      ]);

      const { updatedHands } = service.computeExchange([p0, p1, p2, p3]);

      const winnerHand = updatedHands.get('p0')!;
      const loserHand = updatedHands.get('p3')!;

      // winner should NOT have 3♠, 4♠ anymore; should have 2♠, A♥
      expect(hasCard(winnerHand, card('3', 'spades'))).toBe(false);
      expect(hasCard(winnerHand, card('4', 'spades'))).toBe(false);
      expect(hasCard(winnerHand, card('2', 'spades'))).toBe(true);
      expect(hasCard(winnerHand, card('A', 'hearts'))).toBe(true);

      // loser should NOT have K♥, A♥ anymore (gave 2♠, A♥); should have 3♠, 4♠
      expect(hasCard(loserHand, card('2', 'spades'))).toBe(false);
      expect(hasCard(loserHand, card('A', 'hearts'))).toBe(false);
      expect(hasCard(loserHand, card('3', 'spades'))).toBe(true);
      expect(hasCard(loserHand, card('4', 'spades'))).toBe(true);
    });

    it('4-player: 2nd gives 1 worst to 2nd-last; 2nd-last gives 1 best to 2nd', () => {
      // p1 (2nd): worst card is 7♣ → goes to p2
      // p2 (2nd-last): best card is 6♣ → goes to p1
      const p0 = makeRankedPlayer('p0', 0, [card('A'), card('2')]);
      const p1 = makeRankedPlayer('p1', 1, [
        card('7', 'clubs'),
        card('J', 'clubs'),
        card('Q', 'clubs'),
      ]);
      const p2 = makeRankedPlayer('p2', 2, [
        card('6', 'clubs'),
        card('5', 'clubs'),
        card('4', 'clubs'),
      ]);
      const p3 = makeRankedPlayer('p3', 3, [card('3'), card('3', 'clubs')]);

      const { updatedHands } = service.computeExchange([p0, p1, p2, p3]);

      const second = updatedHands.get('p1')!;
      const secondLast = updatedHands.get('p2')!;

      // p1 gave 7♣ (worst in their hand), received 6♣ (best from p2)
      expect(hasCard(second, card('7', 'clubs'))).toBe(false);
      expect(hasCard(second, card('6', 'clubs'))).toBe(true);

      // p2 gave 6♣, received 7♣
      expect(hasCard(secondLast, card('6', 'clubs'))).toBe(false);
      expect(hasCard(secondLast, card('7', 'clubs'))).toBe(true);
    });

    it('card counts are preserved — no cards created or destroyed', () => {
      const handOf5 = (_base: number): Card[] =>
        (['spades', 'clubs', 'diamonds', 'hearts', 'hearts'] as const).map(
          (s, i) => card(['3', '5', '7', '9', 'J'][i] as any, s),
        );

      const players = [0, 1, 2, 3, 4, 5].map((i) =>
        makeRankedPlayer(`p${i}`, i, handOf5(i)),
      );
      const totalBefore = players.reduce((s, p) => s + p.hand.length, 0);
      const { updatedHands } = service.computeExchange(players);
      expect(countTotalCards(updatedHands)).toBe(totalBefore);
    });

    it('5-player: 2nd and 3rd (2nd-to-last) are always distinct pairs', () => {
      const players = [0, 1, 2, 3, 4].map((i) =>
        makeRankedPlayer(`p${i}`, i, [
          card('3'),
          card('5'),
          card('7'),
          card('9'),
          card('J'),
        ]),
      );
      // 1st=p0, 2nd=p1, 2nd-last=p3 (n-2=3), last=p4
      const { actions } = service.computeExchange(players);
      const giverIds = new Set(actions.map((a) => a.giverId));
      expect(giverIds.has('p0')).toBe(true); // 1st gives
      expect(giverIds.has('p4')).toBe(true); // last gives
      expect(giverIds.has('p1')).toBe(true); // 2nd gives
      expect(giverIds.has('p3')).toBe(true); // 2nd-to-last gives
    });

    it('does not mutate the original player hands', () => {
      const original = [
        card('3', 'spades'),
        card('4', 'spades'),
        card('K', 'hearts'),
      ];
      const players = [
        makeRankedPlayer('p0', 0, [...original]),
        makeRankedPlayer('p1', 1, [card('5'), card('6'), card('7')]),
        makeRankedPlayer('p2', 2, [card('8'), card('9'), card('10')]),
        makeRankedPlayer('p3', 3, [
          card('A'),
          card('2', 'spades'),
          card('2', 'hearts'),
        ]),
      ];
      service.computeExchange(players);
      expect(players[0].hand).toEqual(original);
    });
  });
});
