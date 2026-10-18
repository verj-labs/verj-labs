import { DeckService } from '../deck.service';

describe('DeckService', () => {
  let service: DeckService;

  beforeEach(() => {
    service = new DeckService();
  });

  // ── buildDeck ───────────────────────────────────────────────────────────────

  describe('buildDeck()', () => {
    it('returns exactly 52 cards', () => {
      expect(service.buildDeck()).toHaveLength(52);
    });

    it('contains no duplicate cards', () => {
      const deck = service.buildDeck();
      const keys = deck.map((c) => `${c.rank}:${c.suit}`);
      expect(new Set(keys).size).toBe(52);
    });

    it('contains all 4 suits', () => {
      const deck = service.buildDeck();
      const suits = new Set(deck.map((c) => c.suit));
      expect(suits).toEqual(new Set(['hearts', 'diamonds', 'clubs', 'spades']));
    });

    it('contains all 13 ranks', () => {
      const deck = service.buildDeck();
      const ranks = new Set(deck.map((c) => c.rank));
      expect(ranks).toEqual(
        new Set([
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
          '2',
        ]),
      );
    });

    it('returns a new array each time', () => {
      expect(service.buildDeck()).not.toBe(service.buildDeck());
    });
  });

  // ── shuffleDeck ─────────────────────────────────────────────────────────────

  describe('shuffleDeck()', () => {
    it('returns an array of the same length', () => {
      const deck = service.buildDeck();
      expect(service.shuffleDeck(deck)).toHaveLength(52);
    });

    it('is a permutation of the input (same cards, potentially different order)', () => {
      const deck = service.buildDeck();
      const shuffled = service.shuffleDeck(deck);
      const toKey = (c: { rank: string; suit: string }) =>
        `${c.rank}:${c.suit}`;
      expect(shuffled.map(toKey).sort()).toEqual(deck.map(toKey).sort());
    });

    it('does not mutate the input deck', () => {
      const deck = service.buildDeck();
      const copy = [...deck];
      service.shuffleDeck(deck);
      expect(deck).toEqual(copy);
    });

    it('with the same seed produces the same result every time', () => {
      const deck = service.buildDeck();
      const a = service.shuffleDeck(deck, 42);
      const b = service.shuffleDeck(deck, 42);
      expect(a).toEqual(b);
    });

    it('different seeds produce different results', () => {
      const deck = service.buildDeck();
      const a = service.shuffleDeck(deck, 1);
      const b = service.shuffleDeck(deck, 2);
      expect(a).not.toEqual(b);
    });

    it('without a seed returns a different order to the original (probabilistically)', () => {
      const deck = service.buildDeck();
      const shuffled = service.shuffleDeck(deck);
      // Statistically this will almost never be identical to the original
      const identical = deck.every(
        (c, i) => c.rank === shuffled[i].rank && c.suit === shuffled[i].suit,
      );
      // We can only probabilistically assert this; at worst a 1-in-52! chance of failure
      expect(identical).toBe(false);
    });
  });

  // ── dealHands ───────────────────────────────────────────────────────────────

  describe('dealHands()', () => {
    const table: Array<[number, number, number]> = [
      [3, 17, 1],
      [4, 13, 0],
      [5, 10, 2],
      [6, 8, 4],
      [7, 7, 3],
      [8, 6, 4],
    ];

    it.each(table)(
      '%i players → %i cards each, %i discarded',
      (playerCount, cardsEach, discarded) => {
        const deck = service.buildDeck();
        const { hands, discarded: disc } = service.dealHands(playerCount, deck);

        expect(hands).toHaveLength(playerCount);
        hands.forEach((h) => expect(h).toHaveLength(cardsEach));
        expect(disc).toHaveLength(discarded);
      },
    );

    it('total cards in hands + discarded always equals 52', () => {
      const deck = service.buildDeck();
      for (const pc of [3, 4, 5, 6, 7, 8]) {
        const { hands, discarded } = service.dealHands(pc, deck);
        const total =
          hands.reduce((s, h) => s + h.length, 0) + discarded.length;
        expect(total).toBe(52);
      }
    });

    it('does not give the same card to two players', () => {
      const deck = service.buildDeck();
      const { hands } = service.dealHands(4, deck);
      const allDealt = hands.flat().map((c) => `${c.rank}:${c.suit}`);
      expect(new Set(allDealt).size).toBe(allDealt.length);
    });

    it('throws for playerCount < 3', () => {
      const deck = service.buildDeck();
      expect(() => service.dealHands(2, deck)).toThrow(/invalid player count/i);
    });

    it('throws for playerCount > 8', () => {
      const deck = service.buildDeck();
      expect(() => service.dealHands(9, deck)).toThrow(/invalid player count/i);
    });

    it('throws for playerCount = 0', () => {
      const deck = service.buildDeck();
      expect(() => service.dealHands(0, deck)).toThrow(/invalid player count/i);
    });
  });
});
