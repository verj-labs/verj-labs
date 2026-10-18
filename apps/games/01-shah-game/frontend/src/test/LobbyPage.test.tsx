import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { AxiosError } from 'axios';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import LobbyPage from '@/pages/LobbyPage';
import { createMatch, joinMatch } from '@/services/match.service';
import { useMatchStore } from '@/store/matchStore';
import { useSessionStore } from '@/store/sessionStore';
import { type MatchState } from '@/types/match';

// ─── Module mocks ─────────────────────────────────────────────────────────────

vi.mock('@/lib/config', () => ({
  config: { apiUrl: 'http://localhost:3000', socketUrl: 'http://localhost:3000' },
}));

vi.mock('@/services/match.service', () => ({
  createMatch: vi.fn(),
  joinMatch: vi.fn(),
}));

vi.mock('@/services/auth.service', () => ({
  createSession: vi.fn(),
  deleteSession: vi.fn(),
  getMe: vi.fn(),
}));

// ─── Helpers ──────────────────────────────────────────────────────────────────

const MOCK_PLAYER = { id: 'player-1', displayName: 'Alice' };

const MOCK_MATCH_STATE: MatchState = {
  id: 'match-1',
  roomCode: 'ABCD',
  hostPlayerId: 'player-1',
  status: 'lobby',
  players: [{ playerId: 'player-1', displayName: 'Alice', seatIndex: 0 }],
  playerCount: 1,
};

function Room() {
  return <div>Room page</div>;
}

function renderLobby() {
  return render(
    <MemoryRouter initialEntries={['/lobby']}>
      <Routes>
        <Route path="/lobby" element={<LobbyPage />} />
        <Route path="/room/:code" element={<Room />} />
      </Routes>
    </MemoryRouter>,
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('LobbyPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useSessionStore.setState({
      token: 'test-token',
      player: MOCK_PLAYER,
      isAuthenticated: true,
      isLoading: false,
    });
    useMatchStore.getState().clearMatch();
  });

  // ── Rendering ──────────────────────────────────────────────────────────────

  it('renders the heading, create button, and join form', () => {
    renderLobby();
    expect(screen.getByRole('heading', { name: /shah exchange/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /create room/i })).toBeInTheDocument();
    expect(screen.getByLabelText(/^code/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /join room/i })).toBeInTheDocument();
  });

  it("shows the player's display name in the header", () => {
    renderLobby();
    expect(screen.getByText(/alice/i)).toBeInTheDocument();
  });

  it('join button is disabled while room code is incomplete', () => {
    renderLobby();
    expect(screen.getByRole('button', { name: /join room/i })).toBeDisabled();
  });

  // ── Create room ────────────────────────────────────────────────────────────

  it('creates a match and navigates to /room/:code', async () => {
    vi.mocked(createMatch).mockResolvedValue({
      matchId: 'match-1',
      roomCode: 'ABCD',
      match: MOCK_MATCH_STATE,
    });

    renderLobby();
    await userEvent.click(screen.getByRole('button', { name: /create room/i }));

    await waitFor(() => {
      expect(screen.getByText('Room page')).toBeInTheDocument();
    });
    expect(vi.mocked(createMatch)).toHaveBeenCalledOnce();
  });

  it('shows error alert when create fails', async () => {
    vi.mocked(createMatch).mockRejectedValue(new Error('Network error'));

    renderLobby();
    await userEvent.click(screen.getByRole('button', { name: /create room/i }));

    await waitFor(() => {
      expect(screen.getByRole('alert')).toBeInTheDocument();
    });
  });

  // ── Join room ──────────────────────────────────────────────────────────────

  it('auto-uppercases the room code as the user types', async () => {
    renderLobby();
    const input = screen.getByLabelText(/^code/i);
    await userEvent.type(input, 'abcd');
    expect((input as HTMLInputElement).value).toBe('ABCD');
  });

  it('enables join button once 4 chars are entered', async () => {
    renderLobby();
    const input = screen.getByLabelText(/^code/i);
    await userEvent.type(input, 'ABCD');
    expect(screen.getByRole('button', { name: /join room/i })).toBeEnabled();
  });

  it('clears join error when user starts typing again', async () => {
    const err = new AxiosError('Not found');
    Object.defineProperty(err, 'response', { value: { status: 404, data: {} } });
    vi.mocked(joinMatch).mockRejectedValue(err);

    renderLobby();
    const input = screen.getByLabelText(/^code/i);
    await userEvent.type(input, 'ZZZZ');
    await userEvent.click(screen.getByRole('button', { name: /join room/i }));
    await waitFor(() => expect(screen.getByRole('alert')).toBeInTheDocument());

    // Now type again — error should clear
    fireEvent.change(input, { target: { value: 'A' } });
    await waitFor(() => expect(screen.queryByRole('alert')).not.toBeInTheDocument());
  });

  it('joins a match and navigates to /room/:code', async () => {
    vi.mocked(joinMatch).mockResolvedValue(MOCK_MATCH_STATE);

    renderLobby();
    const input = screen.getByLabelText(/^code/i);
    await userEvent.type(input, 'ABCD');
    await userEvent.click(screen.getByRole('button', { name: /join room/i }));

    await waitFor(() => {
      expect(screen.getByText('Room page')).toBeInTheDocument();
    });
    expect(vi.mocked(joinMatch)).toHaveBeenCalledWith('ABCD');
  });

  it('shows "Room not found" on 404 error', async () => {
    const err = new AxiosError('Not found');
    Object.defineProperty(err, 'response', { value: { status: 404, data: {} } });
    vi.mocked(joinMatch).mockRejectedValue(err);

    renderLobby();
    const input = screen.getByLabelText(/^code/i);
    await userEvent.type(input, 'ZZZZ');
    await userEvent.click(screen.getByRole('button', { name: /join room/i }));

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent(/not found/i);
    });
  });

  it('shows "Room is full" on 409 conflict with full message', async () => {
    const err = new AxiosError('Conflict');
    Object.defineProperty(err, 'response', {
      value: { status: 409, data: { message: 'Room is full.' } },
    });
    vi.mocked(joinMatch).mockRejectedValue(err);

    renderLobby();
    const input = screen.getByLabelText(/^code/i);
    await userEvent.type(input, 'ABCD');
    await userEvent.click(screen.getByRole('button', { name: /join room/i }));

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent(/full/i);
    });
  });

  it('shows "Game has already started" on 409 with non-full message', async () => {
    const err = new AxiosError('Conflict');
    Object.defineProperty(err, 'response', {
      value: { status: 409, data: { message: 'Match already started.' } },
    });
    vi.mocked(joinMatch).mockRejectedValue(err);

    renderLobby();
    const input = screen.getByLabelText(/^code/i);
    await userEvent.type(input, 'ABCD');
    await userEvent.click(screen.getByRole('button', { name: /join room/i }));

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent(/already started/i);
    });
  });
});
