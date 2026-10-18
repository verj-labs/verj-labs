import { create } from 'zustand';
import { STORAGE_KEY_PLAYER, STORAGE_KEY_TOKEN } from '@/lib/constants';
import {
  createSession,
  deleteSession,
  getMe,
} from '@/services/auth.service';
import { type Player } from '@/types/player';

interface SessionState {
  token: string | null;
  player: Player | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}

interface SessionActions {
  login: (displayName: string) => Promise<void>;
  logout: () => Promise<void>;
  restoreSession: () => Promise<void>;
}

type SessionStore = SessionState & SessionActions;

function persistSession(token: string, player: Player): void {
  localStorage.setItem(STORAGE_KEY_TOKEN, token);
  localStorage.setItem(STORAGE_KEY_PLAYER, JSON.stringify(player));
}

function clearSession(): void {
  localStorage.removeItem(STORAGE_KEY_TOKEN);
  localStorage.removeItem(STORAGE_KEY_PLAYER);
}

/**
 * If a session token is persisted we set isLoading=true immediately so that
 * ProtectedRoute shows a spinner (not a redirect) until restoreSession()
 * finishes verifying the token with the server.
 */
const hasPersistedToken =
  typeof localStorage !== 'undefined' &&
  localStorage.getItem(STORAGE_KEY_TOKEN) !== null;

export const useSessionStore = create<SessionStore>((set) => ({
  token: null,
  player: null,
  isAuthenticated: false,
  isLoading: hasPersistedToken,

  login: async (displayName: string): Promise<void> => {
    set({ isLoading: true });
    try {
      const { token, player } = await createSession(displayName);
      persistSession(token, player);
      set({ token, player, isAuthenticated: true, isLoading: false });
    } catch (err) {
      set({ isLoading: false });
      throw err;
    }
  },

  logout: async (): Promise<void> => {
    try {
      await deleteSession();
    } catch {
      // Best effort — clear locally even if server request fails
    } finally {
      clearSession();
      set({ token: null, player: null, isAuthenticated: false });
      // Clear related stores and disconnect socket to prevent stale ghost state
      const { useMatchStore } = await import('@/store/matchStore');
      const { useGameStore } = await import('@/store/gameStore');
      const { disconnectSocket } = await import('@/lib/socket');
      useMatchStore.getState().clearMatch();
      useGameStore.getState().clearGame();
      disconnectSocket();
    }
  },

  restoreSession: async (): Promise<void> => {
    const token = localStorage.getItem(STORAGE_KEY_TOKEN);
    if (!token) {
      // Nothing to restore — ensure spinner is cleared in case it was set at init
      set({ isLoading: false });
      return;
    }

    set({ isLoading: true });
    try {
      const { player } = await getMe();
      set({ token, player, isAuthenticated: true, isLoading: false });
    } catch {
      // Token expired or invalid — silently clear
      clearSession();
      set({ token: null, player: null, isAuthenticated: false, isLoading: false });
    }
  },
}));
