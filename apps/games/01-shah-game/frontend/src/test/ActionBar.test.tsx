import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { ActionBar } from '@/components/ui/ActionBar';
import * as gameActions from '@/services/gameActions';
import { useGameStore } from '@/store/gameStore';
import type { GameStateView } from '@/types/game-state';

// ─── Mocks ────────────────────────────────────────────────────────────────────

vi.mock('@/services/gameActions', () => ({
  sendPlay: vi.fn().mockResolvedValue(undefined),
  sendPass: vi.fn().mockResolvedValue(undefined),
}));

vi.mock('@/store/sessionStore', () => ({
  useSessionStore: (selector: (s: { token: string | null; player: null }) => unknown) =>
    selector({ token: 'token', player: null }),
}));

// ─── Fixture ──────────────────────────────────────────────────────────────────

function makeGameState(activePlayerId: string): GameStateView {
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
        id: activePlayerId,
        displayName: 'Alice',
        seatIndex: 0,
        handCount: 2,
        isFinished: false,
        finishRank: null,
        passed: false,
      },
    ],
    localHand: [{ rank: '7', suit: 'spades' }],
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

describe('ActionBar', () => {
  beforeEach(() => {
    resetStore();
    vi.clearAllMocks();
  });

  it('renders nothing when gameState is null', () => {
    const { container } = render(<ActionBar />);
    expect(container).toBeEmptyDOMElement();
  });

  it('shows disabled Play and Pass buttons when it is not the local player\'s turn', () => {
    const store = useGameStore.getState();
    store.setGameState(makeGameState('other-player'));
    store.setLocalPlayerId('p0');

    render(<ActionBar />);

    expect(screen.getByRole('button', { name: /play/i })).toBeDisabled();
    expect(screen.getByRole('button', { name: /pass/i })).toBeDisabled();
  });

  it('shows enabled Pass button on local player\'s turn', () => {
    const store = useGameStore.getState();
    store.setGameState(makeGameState('p0'));
    store.setLocalPlayerId('p0');

    render(<ActionBar />);

    expect(screen.getByRole('button', { name: /pass/i })).not.toBeDisabled();
  });

  it('Play button is disabled when no cards are selected', () => {
    const store = useGameStore.getState();
    store.setGameState(makeGameState('p0'));
    store.setLocalPlayerId('p0');

    render(<ActionBar />);

    expect(screen.getByRole('button', { name: /^play/i })).toBeDisabled();
  });

  it('calls sendPass when Pass is clicked', async () => {
    const user = userEvent.setup();
    const store = useGameStore.getState();
    store.setGameState(makeGameState('p0'));
    store.setLocalPlayerId('p0');

    render(<ActionBar />);

    await user.click(screen.getByRole('button', { name: /pass/i }));
    expect(gameActions.sendPass).toHaveBeenCalledOnce();
  });

  it('calls sendPlay with selected cards when Play is clicked', async () => {
    const user = userEvent.setup();
    const store = useGameStore.getState();
    store.setGameState(makeGameState('p0'));
    store.setLocalPlayerId('p0');
    store.toggleCardSelection({ rank: '7', suit: 'spades' });

    render(<ActionBar />);

    await user.click(screen.getByRole('button', { name: /play \(1\)/i }));
    expect(gameActions.sendPlay).toHaveBeenCalledWith([{ rank: '7', suit: 'spades' }]);
  });

  it('shows error message when action fails', async () => {
    const user = userEvent.setup();
    vi.mocked(gameActions.sendPass).mockRejectedValueOnce(new Error('Not your turn.'));

    const store = useGameStore.getState();
    store.setGameState(makeGameState('p0'));
    store.setLocalPlayerId('p0');

    render(<ActionBar />);

    await user.click(screen.getByRole('button', { name: /pass/i }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Not your turn.');
  });
});
