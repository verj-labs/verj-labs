import { render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { describe, expect, it, beforeEach, vi } from 'vitest';
import ProtectedRoute from '@/router/ProtectedRoute';
import { useSessionStore } from '@/store/sessionStore';

vi.mock('@/lib/config', () => ({
  config: { apiUrl: 'http://localhost:3000', socketUrl: 'http://localhost:3000' },
}));

function Protected() {
  return <div>Protected content</div>;
}

function Home() {
  return <div>Home page</div>;
}

function renderWithRouter(entry: string) {
  return render(
    <MemoryRouter initialEntries={[entry]}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route element={<ProtectedRoute />}>
          <Route path="/lobby" element={<Protected />} />
        </Route>
      </Routes>
    </MemoryRouter>,
  );
}

function setStoreState(partial: Partial<ReturnType<typeof useSessionStore.getState>>) {
  useSessionStore.setState(partial);
}

describe('ProtectedRoute', () => {
  beforeEach(() => {
    useSessionStore.setState({
      token: null,
      player: null,
      isAuthenticated: false,
      isLoading: false,
    });
    vi.clearAllMocks();
  });

  it('renders children when authenticated', () => {
    setStoreState({ isAuthenticated: true, isLoading: false });
    renderWithRouter('/lobby');
    expect(screen.getByText('Protected content')).toBeInTheDocument();
  });

  it('redirects to / when not authenticated', () => {
    setStoreState({ isAuthenticated: false, isLoading: false });
    renderWithRouter('/lobby');
    expect(screen.getByText('Home page')).toBeInTheDocument();
    expect(screen.queryByText('Protected content')).not.toBeInTheDocument();
  });

  it('shows loading spinner while session is being restored', () => {
    setStoreState({ isAuthenticated: false, isLoading: true });
    renderWithRouter('/lobby');
    expect(screen.getByRole('status')).toBeInTheDocument();
    expect(screen.queryByText('Protected content')).not.toBeInTheDocument();
    expect(screen.queryByText('Home page')).not.toBeInTheDocument();
  });
});
