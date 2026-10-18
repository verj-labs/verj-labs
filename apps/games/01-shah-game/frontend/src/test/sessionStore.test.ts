import { act, renderHook } from '@testing-library/react';
import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { useSessionStore } from '@/store/sessionStore';

// Mock the auth service module so tests don't need a real backend
vi.mock('@/services/auth.service', () => ({
  createSession: vi.fn(),
  deleteSession: vi.fn(),
  getMe: vi.fn(),
}));

// Also mock config to avoid missing-env-var errors on module load
vi.mock('@/lib/config', () => ({
  config: { apiUrl: 'http://localhost:3000', socketUrl: 'http://localhost:3000' },
}));

import * as authService from '@/services/auth.service';
import { STORAGE_KEY_PLAYER, STORAGE_KEY_TOKEN } from '@/lib/constants';

const mockPlayer = { id: 'player-1', displayName: 'Alice' };

function resetStore(): void {
  useSessionStore.setState({
    token: null,
    player: null,
    isAuthenticated: false,
    isLoading: false,
  });
}

describe('sessionStore', () => {
  beforeEach(() => {
    resetStore();
    localStorage.clear();
    vi.clearAllMocks();
  });

  afterEach(() => {
    localStorage.clear();
  });

  describe('login', () => {
    it('populates state and localStorage on success', async () => {
      vi.mocked(authService.createSession).mockResolvedValue({
        token: 'tok-123',
        player: mockPlayer,
      });

      const { result } = renderHook(() => useSessionStore());
      await act(() => result.current.login('Alice'));

      expect(result.current.isAuthenticated).toBe(true);
      expect(result.current.token).toBe('tok-123');
      expect(result.current.player).toEqual(mockPlayer);
      expect(localStorage.getItem(STORAGE_KEY_TOKEN)).toBe('tok-123');
      expect(JSON.parse(localStorage.getItem(STORAGE_KEY_PLAYER)!)).toEqual(mockPlayer);
    });

    it('re-throws on API failure and keeps isLoading false', async () => {
      vi.mocked(authService.createSession).mockRejectedValue(
        new Error('Network error'),
      );

      const { result } = renderHook(() => useSessionStore());

      await expect(
        act(() => result.current.login('Alice')),
      ).rejects.toThrow('Network error');

      // Read state directly from the store to avoid React re-render timing issues
      // with rejected act() calls.
      const state = useSessionStore.getState();
      expect(state.isLoading).toBe(false);
      expect(state.isAuthenticated).toBe(false);
    });
  });

  describe('restoreSession', () => {
    it('restores state without re-asking for a name on page refresh', async () => {
      localStorage.setItem(STORAGE_KEY_TOKEN, 'stored-token');
      vi.mocked(authService.getMe).mockResolvedValue({
        player: mockPlayer,
        matchId: null,
      });

      const { result } = renderHook(() => useSessionStore());
      await act(() => result.current.restoreSession());

      expect(result.current.isAuthenticated).toBe(true);
      expect(result.current.player).toEqual(mockPlayer);
      expect(result.current.token).toBe('stored-token');
    });

    it('silently clears storage on 401 / invalid token', async () => {
      localStorage.setItem(STORAGE_KEY_TOKEN, 'bad-token');
      vi.mocked(authService.getMe).mockRejectedValue(
        Object.assign(new Error('Unauthorized'), { response: { status: 401 } }),
      );

      const { result } = renderHook(() => useSessionStore());
      await act(() => result.current.restoreSession());

      expect(result.current.isAuthenticated).toBe(false);
      expect(result.current.isLoading).toBe(false);
      expect(localStorage.getItem(STORAGE_KEY_TOKEN)).toBeNull();
    });

    it('does nothing when no token in localStorage', async () => {
      const { result } = renderHook(() => useSessionStore());
      await act(() => result.current.restoreSession());

      expect(authService.getMe).not.toHaveBeenCalled();
      expect(result.current.isAuthenticated).toBe(false);
    });

    it('clears isLoading when called with no token (prevents stuck spinner)', async () => {
      // Simulate the spinner already being shown (e.g. from initial load)
      useSessionStore.setState({ isLoading: true });

      const { result } = renderHook(() => useSessionStore());
      await act(() => result.current.restoreSession());

      expect(result.current.isLoading).toBe(false);
      expect(authService.getMe).not.toHaveBeenCalled();
    });
  });

  describe('logout', () => {
    it('clears all state and localStorage', async () => {
      // Pre-populate state
      useSessionStore.setState({ token: 'tok', player: mockPlayer, isAuthenticated: true });
      localStorage.setItem(STORAGE_KEY_TOKEN, 'tok');
      vi.mocked(authService.deleteSession).mockResolvedValue(undefined);

      const { result } = renderHook(() => useSessionStore());
      await act(() => result.current.logout());

      expect(result.current.isAuthenticated).toBe(false);
      expect(result.current.token).toBeNull();
      expect(result.current.player).toBeNull();
      expect(localStorage.getItem(STORAGE_KEY_TOKEN)).toBeNull();
    });

    it('clears local state even if server request fails', async () => {
      useSessionStore.setState({ token: 'tok', player: mockPlayer, isAuthenticated: true });
      vi.mocked(authService.deleteSession).mockRejectedValue(new Error('Server error'));

      const { result } = renderHook(() => useSessionStore());
      await act(() => result.current.logout());

      expect(result.current.isAuthenticated).toBe(false);
    });
  });
});
