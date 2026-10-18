import { beforeEach, describe, expect, it } from 'vitest';
import { useGameStore, selectIsMyTurn, selectLocalPlayerView } from '@/store/gameStore';
import { type GameStateView } from '@/types/game-state';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

function makeGameStateView(overrides: Partial<GameStateView> = {}): GameStateView {
  return {
    id: 'game-1',
    matchId: 'match-1',
    gameNumber: 1,
    roundNumber: 1,
    direction: 'clockwise',
    status: 'in_progress',
    activePlayerIndex: 0,
    players: [
      {
        id: 'p0',
        displayName: 'Alice',
        seatIndex: 0,
        handCount: 13,
        isFinished: false,
        finishRank: null,
        passed: false,
      },
      {
        id: 'p1',
        displayName: 'Bob',
        seatIndex: 1,
        handCount: 13,
        isFinished: false,
        finishRank: null,
        passed: false,
      },
    ],
    localHand: [
      { rank: '7', suit: 'spades' },
      { rank: '8', suit: 'hearts' },
    ],
    currentRound: {
      pile: { topPlay: null, history: [] },
      consecutivePassCount: 0,
      lastPlayerId: null,
      skippedPlayerIndex: null,
    },
    finishedPlayers: [],
    ...overrides,
  };
}

function resetStore() {
  useGameStore.getState().clearGame();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('gameStore', () => {
  beforeEach(() => {
    resetStore();
  });

  it('starts with all null / empty initial state', () => {
    const s = useGameStore.getState();
    expect(s.gameState).toBeNull();
    expect(s.localPlayerId).toBeNull();
    expect(s.selectedCards).toEqual([]);
    expect(s.isActionPending).toBe(false);
    expect(s.lastActionError).toBeNull();
    expect(s.isDisconnected).toBe(false);
  });

  it('setGameState stores the game state and clears lastActionError', () => {
    const store = useGameStore.getState();
    store.setActionError('old error');
    store.setGameState(makeGameStateView());
    const s = useGameStore.getState();
    expect(s.gameState?.id).toBe('game-1');
    expect(s.lastActionError).toBeNull();
  });

  it('setLocalPlayerId stores the player id', () => {
    useGameStore.getState().setLocalPlayerId('p0');
    expect(useGameStore.getState().localPlayerId).toBe('p0');
  });

  // ── Card selection ────────────────────────────────────────────────────────

  it('toggleCardSelection adds a card when not selected', () => {
    useGameStore.getState().toggleCardSelection({ rank: '7', suit: 'spades' });
    expect(useGameStore.getState().selectedCards).toHaveLength(1);
  });

  it('toggleCardSelection removes a card when already selected', () => {
    const store = useGameStore.getState();
    const card = { rank: '7' as const, suit: 'spades' as const };
    store.toggleCardSelection(card);
    store.toggleCardSelection(card);
    expect(useGameStore.getState().selectedCards).toHaveLength(0);
  });

  it('clearSelection empties selectedCards', () => {
    const store = useGameStore.getState();
    store.toggleCardSelection({ rank: '7', suit: 'spades' });
    store.toggleCardSelection({ rank: '8', suit: 'hearts' });
    store.clearSelection();
    expect(useGameStore.getState().selectedCards).toHaveLength(0);
  });

  it('can select multiple distinct cards', () => {
    const store = useGameStore.getState();
    store.toggleCardSelection({ rank: '7', suit: 'spades' });
    store.toggleCardSelection({ rank: '8', suit: 'hearts' });
    expect(useGameStore.getState().selectedCards).toHaveLength(2);
  });

  // ── Status flags ──────────────────────────────────────────────────────────

  it('setActionPending updates isActionPending', () => {
    useGameStore.getState().setActionPending(true);
    expect(useGameStore.getState().isActionPending).toBe(true);
    useGameStore.getState().setActionPending(false);
    expect(useGameStore.getState().isActionPending).toBe(false);
  });

  it('setActionError updates lastActionError', () => {
    useGameStore.getState().setActionError('Something went wrong');
    expect(useGameStore.getState().lastActionError).toBe('Something went wrong');
    useGameStore.getState().setActionError(null);
    expect(useGameStore.getState().lastActionError).toBeNull();
  });

  it('setDisconnected updates isDisconnected', () => {
    useGameStore.getState().setDisconnected(true);
    expect(useGameStore.getState().isDisconnected).toBe(true);
  });

  it('clearGame resets all fields', () => {
    const store = useGameStore.getState();
    store.setGameState(makeGameStateView());
    store.setLocalPlayerId('p0');
    store.toggleCardSelection({ rank: '7', suit: 'spades' });
    store.setActionPending(true);
    store.clearGame();
    const s = useGameStore.getState();
    expect(s.gameState).toBeNull();
    expect(s.localPlayerId).toBeNull();
    expect(s.selectedCards).toEqual([]);
    expect(s.isActionPending).toBe(false);
  });

  // ── Selectors ─────────────────────────────────────────────────────────────

  describe('selectIsMyTurn', () => {
    it('returns true when active player matches localPlayerId', () => {
      const store = useGameStore.getState();
      store.setGameState(makeGameStateView({ activePlayerIndex: 0 }));
      store.setLocalPlayerId('p0');
      expect(selectIsMyTurn(useGameStore.getState())).toBe(true);
    });

    it('returns false when it is another player\'s turn', () => {
      const store = useGameStore.getState();
      store.setGameState(makeGameStateView({ activePlayerIndex: 1 }));
      store.setLocalPlayerId('p0');
      expect(selectIsMyTurn(useGameStore.getState())).toBe(false);
    });

    it('returns false when gameState is null', () => {
      expect(selectIsMyTurn(useGameStore.getState())).toBe(false);
    });
  });

  describe('selectLocalPlayerView', () => {
    it('returns the local player\'s PlayerView', () => {
      const store = useGameStore.getState();
      store.setGameState(makeGameStateView());
      store.setLocalPlayerId('p0');
      const view = selectLocalPlayerView(useGameStore.getState());
      expect(view?.id).toBe('p0');
      expect(view?.displayName).toBe('Alice');
    });

    it('returns null when gameState is null', () => {
      expect(selectLocalPlayerView(useGameStore.getState())).toBeNull();
    });

    it('returns null when playerId not found in players list', () => {
      const store = useGameStore.getState();
      store.setGameState(makeGameStateView());
      store.setLocalPlayerId('unknown');
      expect(selectLocalPlayerView(useGameStore.getState())).toBeNull();
    });
  });
});
