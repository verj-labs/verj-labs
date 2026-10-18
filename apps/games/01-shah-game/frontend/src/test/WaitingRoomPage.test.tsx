import { act, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import RoomPage from '@/pages/RoomPage';
import { getMatch, leaveMatch, startMatch } from '@/services/match.service';
import { useGameStore } from '@/store/gameStore';
import { useMatchStore } from '@/store/matchStore';
import { useSessionStore } from '@/store/sessionStore';
import { type MatchState } from '@/types/match';
import { type GameStateView } from '@/types/game-state';

// ─── Module mocks ─────────────────────────────────────────────────────────────

vi.mock('@/lib/config', () => ({
  config: { apiUrl: 'http://localhost:3000', socketUrl: 'http://localhost:3000' },
}));

vi.mock('@/services/match.service', () => ({
  getMatch: vi.fn(),
  leaveMatch: vi.fn(),
  startMatch: vi.fn(),
}));

vi.mock('@/services/auth.service', () => ({
  createSession: vi.fn(),
  deleteSession: vi.fn(),
  getMe: vi.fn(),
}));

// Stub socket hook so no real socket is created in tests
vi.mock('@/hooks/useMatchSocket', () => ({
  useMatchSocket: vi.fn(),
}));

// ─── Helpers ──────────────────────────────────────────────────────────────────

const MOCK_PLAYER = { id: 'player-1', displayName: 'Alice' };

const MOCK_GAME_STATE: GameStateView = {
  id: 'game-1',
  matchId: 'match-1',
  gameNumber: 1,
  roundNumber: 1,
  direction: 'clockwise',
  status: 'in_progress',
  activePlayerIndex: 0,
  players: [],
  localHand: [],
  currentRound: {
    pile: { topPlay: null, history: [] },
    consecutivePassCount: 0,
    lastPlayerId: null,
    skippedPlayerIndex: null,
  },
  finishedPlayers: [],
};

const BASE_MATCH: MatchState = {
  id: 'match-1',
  roomCode: 'ABCD',
  hostPlayerId: 'player-1',
  status: 'lobby',
  players: [
    { playerId: 'player-1', displayName: 'Alice', seatIndex: 0 },
    { playerId: 'player-2', displayName: 'Bob', seatIndex: 1 },
    { playerId: 'player-3', displayName: 'Carol', seatIndex: 2 },
    { playerId: 'player-4', displayName: 'Dave', seatIndex: 3 },
  ],
  playerCount: 4,
};

function Lobby() {
  return <div>Lobby page</div>;
}

function Game() {
  return <div>Game page</div>;
}

function renderRoom(code = 'ABCD') {
  return render(
    <MemoryRouter initialEntries={[`/room/${code}`]}>
      <Routes>
        <Route path="/room/:code" element={<RoomPage />} />
        <Route path="/lobby" element={<Lobby />} />
        <Route path="/game/:matchId" element={<Game />} />
      </Routes>
    </MemoryRouter>,
  );
}

function setUpStore(matchId: string | null, playerIsHost = true) {
  useSessionStore.setState({
    token: 'test-token',
    player: MOCK_PLAYER,
    isAuthenticated: true,
    isLoading: false,
  });
  if (matchId) {
    useMatchStore.setState({
      matchId,
      roomCode: 'ABCD',
      hostPlayerId: playerIsHost ? 'player-1' : 'player-2',
      players: BASE_MATCH.players,
      status: 'lobby',
      isLoading: false,
    });
  } else {
    useMatchStore.getState().clearMatch();
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('RoomPage (WaitingRoom)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // Reset game store so the watchdog useEffect doesn't fire unexpectedly
    useGameStore.getState().clearGame();
    vi.mocked(getMatch).mockResolvedValue(BASE_MATCH);
    vi.mocked(leaveMatch).mockResolvedValue(undefined);
    vi.mocked(startMatch).mockResolvedValue({ ...BASE_MATCH, status: 'in_progress' });
  });

  // ── Missing matchId (no store state) ──────────────────────────────────────

  it('redirects to /lobby when matchId is not in store', async () => {
    setUpStore(null);
    renderRoom();
    await waitFor(() => {
      expect(screen.getByText('Lobby page')).toBeInTheDocument();
    });
  });

  // ── Normal render ─────────────────────────────────────────────────────────

  it('displays the room code prominently', async () => {
    setUpStore('match-1');
    renderRoom();
    await waitFor(() => {
      expect(screen.getByLabelText(/room code: ABCD/i)).toBeInTheDocument();
    });
  });

  it('shows all 8 seat slots', async () => {
    setUpStore('match-1');
    renderRoom();
    await waitFor(() => {
      // 4 filled, 4 empty
      expect(screen.getAllByText(/empty/i)).toHaveLength(4);
    });
  });

  it('shows player names in filled seats', async () => {
    setUpStore('match-1');
    renderRoom();
    await waitFor(() => {
      expect(screen.getByText('Alice')).toBeInTheDocument();
      expect(screen.getByText('Bob')).toBeInTheDocument();
    });
  });

  it('fetches match state on mount', async () => {
    setUpStore('match-1');
    renderRoom();
    await waitFor(() => {
      expect(vi.mocked(getMatch)).toHaveBeenCalledWith('match-1');
    });
  });

  // ── Host view ─────────────────────────────────────────────────────────────

  it('shows Start Game button when player is host and ≥4 players', async () => {
    setUpStore('match-1', true);
    renderRoom();
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /start game/i })).toBeEnabled();
    });
  });

  it('starts the game and navigates to /game/:matchId', async () => {
    setUpStore('match-1', true);
    renderRoom();

    const startBtn = await screen.findByRole('button', { name: /start game/i });
    await userEvent.click(startBtn);

    // Simulate the `game:started` socket event arriving (sets gameState in store),
    // which triggers the watchdog useEffect in RoomPage to navigate.
    act(() => {
      useGameStore.getState().setGameState(MOCK_GAME_STATE);
    });

    await waitFor(() => {
      expect(screen.getByText('Game page')).toBeInTheDocument();
    });
    expect(vi.mocked(startMatch)).toHaveBeenCalledWith('match-1');
  });

  it('shows error alert when startMatch fails', async () => {
    vi.mocked(startMatch).mockRejectedValue(new Error('Forbidden'));
    setUpStore('match-1', true);
    renderRoom();

    const startBtn = await screen.findByRole('button', { name: /start game/i });
    await userEvent.click(startBtn);

    await waitFor(() => {
      expect(screen.getByRole('alert')).toBeInTheDocument();
    });
  });

  // ── Non-host view ──────────────────────────────────────────────────────────

  it('shows "Waiting for host" message when player is not the host', async () => {
    // Override getMatch to return a state where player-2 (Bob) is the host
    vi.mocked(getMatch).mockResolvedValue({ ...BASE_MATCH, hostPlayerId: 'player-2' });
    setUpStore('match-1', false);
    renderRoom();
    await waitFor(() => {
      expect(screen.getByText(/waiting for/i)).toBeInTheDocument();
    });
  });

  // ── Leave room ────────────────────────────────────────────────────────────

  it('calls leaveMatch and navigates to /lobby when Leave Room is clicked', async () => {
    setUpStore('match-1');
    renderRoom();

    const leaveBtn = await screen.findByRole('button', { name: /leave room/i });
    await userEvent.click(leaveBtn);

    await waitFor(() => {
      expect(screen.getByText('Lobby page')).toBeInTheDocument();
    });
    expect(vi.mocked(leaveMatch)).toHaveBeenCalledWith('match-1');
  });

  it('still navigates to /lobby even if leaveMatch throws', async () => {
    vi.mocked(leaveMatch).mockRejectedValue(new Error('Server error'));
    setUpStore('match-1');
    renderRoom();

    const leaveBtn = await screen.findByRole('button', { name: /leave room/i });
    await userEvent.click(leaveBtn);

    await waitFor(() => {
      expect(screen.getByText('Lobby page')).toBeInTheDocument();
    });
  });
});
