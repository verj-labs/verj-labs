import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it } from 'vitest';
import { LocalPlayerHand } from '@/components/ui/LocalPlayerHand';
import { useGameStore } from '@/store/gameStore';
import type { GameStateView } from '@/types/game-state';

// ─── Fixture ──────────────────────────────────────────────────────────────────

function makeGameState(isMyTurn: boolean): GameStateView {
  const myId = 'p0';
  return {
    id: 'game-1',
    matchId: 'match-1',
    gameNumber: 1,
    roundNumber: 1,
    direction: 'clockwise',
    status: 'in_progress',
    activePlayerIndex: isMyTurn ? 0 : 1,
    players: [
      {
        id: myId,
        displayName: 'Alice',
        seatIndex: 0,
        handCount: 2,
        isFinished: false,
        finishRank: null,
        passed: false,
      },
      {
        id: 'p1',
        displayName: 'Bob',
        seatIndex: 1,
        handCount: 3,
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
  };
}

function resetStore() {
  useGameStore.getState().clearGame();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('LocalPlayerHand', () => {
  beforeEach(() => {
    resetStore();
  });

  it('renders nothing when gameState is null', () => {
    const { container } = render(<LocalPlayerHand />);
    expect(container).toBeEmptyDOMElement();
  });

  it('renders all cards in localHand', () => {
    const store = useGameStore.getState();
    store.setGameState(makeGameState(true));
    store.setLocalPlayerId('p0');

    render(<LocalPlayerHand />);

    // Two cards should be rendered as buttons
    expect(screen.getAllByRole('button')).toHaveLength(2);
  });

  it('cards are clickable on the local player\'s turn', async () => {
    const user = userEvent.setup();
    const store = useGameStore.getState();
    store.setGameState(makeGameState(true));
    store.setLocalPlayerId('p0');

    render(<LocalPlayerHand />);

    const cards = screen.getAllByRole('button');
    await user.click(cards[0]);

    expect(useGameStore.getState().selectedCards).toHaveLength(1);
  });

  it('cards are disabled when it is not the local player\'s turn', () => {
    const store = useGameStore.getState();
    store.setGameState(makeGameState(false));
    store.setLocalPlayerId('p0');

    render(<LocalPlayerHand />);

    const cards = screen.getAllByRole('button');
    cards.forEach((card) => {
      expect(card).toBeDisabled();
    });
  });

  it('clicking a selected card deselects it', async () => {
    const user = userEvent.setup();
    const store = useGameStore.getState();
    store.setGameState(makeGameState(true));
    store.setLocalPlayerId('p0');

    render(<LocalPlayerHand />);

    const cards = screen.getAllByRole('button');
    // Select
    await user.click(cards[0]);
    expect(useGameStore.getState().selectedCards).toHaveLength(1);
    // Deselect
    await user.click(cards[0]);
    expect(useGameStore.getState().selectedCards).toHaveLength(0);
  });

  it('shows "empty" message when localHand is empty', () => {
    const state = makeGameState(true);
    state.localHand = [];
    const store = useGameStore.getState();
    store.setGameState(state);
    store.setLocalPlayerId('p0');

    render(<LocalPlayerHand />);

    expect(screen.getByText(/your hand is empty/i)).toBeInTheDocument();
  });
});
