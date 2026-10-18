import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { describe, expect, it, beforeEach, vi } from 'vitest';
import LandingPage from '@/pages/LandingPage';
import { useSessionStore } from '@/store/sessionStore';

vi.mock('@/lib/config', () => ({
  config: { apiUrl: 'http://localhost:3000', socketUrl: 'http://localhost:3000' },
}));

vi.mock('@/services/auth.service', () => ({
  createSession: vi.fn(),
  deleteSession: vi.fn(),
  getMe: vi.fn(),
}));

function Lobby() {
  return <div>Lobby page</div>;
}

function renderLanding() {
  return render(
    <MemoryRouter initialEntries={['/']}>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/lobby" element={<Lobby />} />
      </Routes>
    </MemoryRouter>,
  );
}

function resetStore(partial: Partial<ReturnType<typeof useSessionStore.getState>> = {}) {
  useSessionStore.setState({
    token: null,
    player: null,
    isAuthenticated: false,
    isLoading: false,
    ...partial,
  });
}

describe('LandingPage', () => {
  beforeEach(() => {
    resetStore();
    vi.clearAllMocks();
  });

  it('renders the game title and form', () => {
    renderLanding();
    expect(screen.getByRole('heading', { name: /shah exchange/i })).toBeInTheDocument();
    expect(screen.getByLabelText(/your name/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /enter game/i })).toBeInTheDocument();
  });

  it('shows validation error when name is too short', async () => {
    renderLanding();
    const input = screen.getByLabelText(/your name/i);
    const btn = screen.getByRole('button', { name: /enter game/i });

    await userEvent.type(input, 'A');
    fireEvent.click(btn);

    await waitFor(() => {
      expect(screen.getByRole('alert')).toBeInTheDocument();
      expect(screen.getByRole('alert')).toHaveTextContent(/at least 2/i);
    });
  });

  it('clears error when user starts typing again', async () => {
    renderLanding();
    const input = screen.getByLabelText(/your name/i);
    const btn = screen.getByRole('button', { name: /enter game/i });

    await userEvent.type(input, 'A');
    fireEvent.click(btn);
    await waitFor(() => expect(screen.getByRole('alert')).toBeInTheDocument());

    await userEvent.type(input, 'B');
    await waitFor(() => expect(screen.queryByRole('alert')).not.toBeInTheDocument());
  });

  it('calls login and navigates to /lobby on valid submit', async () => {
    const loginMock = vi.fn().mockResolvedValue(undefined);
    useSessionStore.setState({ login: loginMock } as never);

    renderLanding();
    const input = screen.getByLabelText(/your name/i);

    await userEvent.type(input, 'Alice');
    await userEvent.keyboard('{Enter}');

    await waitFor(() => expect(loginMock).toHaveBeenCalledWith('Alice'));
    await waitFor(() => expect(screen.getByText('Lobby page')).toBeInTheDocument());
  });

  it('shows a generic error when login throws', async () => {
    const loginMock = vi.fn().mockRejectedValue(new Error('Network error'));
    useSessionStore.setState({ login: loginMock } as never);

    renderLanding();
    const input = screen.getByLabelText(/your name/i);
    await userEvent.type(input, 'Alice');
    await userEvent.keyboard('{Enter}');

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent(/something broke/i);
    });
  });

  it('disables form controls while loading', () => {
    resetStore({ isLoading: true });
    renderLanding();
    expect(screen.getByLabelText(/your name/i)).toBeDisabled();
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('redirects to /lobby when already authenticated', async () => {
    resetStore({ isAuthenticated: true });
    renderLanding();
    await waitFor(() => expect(screen.getByText('Lobby page')).toBeInTheDocument());
  });
});
