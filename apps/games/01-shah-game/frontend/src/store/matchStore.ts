import { create } from 'zustand';
import { type MatchPlayerInfo, type MatchState, type MatchStatus } from '@/types/match';
import { type MatchFinishedPayload } from '@/types/socket-events';

// ─── Types ────────────────────────────────────────────────────────────────────

interface MatchStoreState {
  matchId: string | null;
  roomCode: string | null;
  hostPlayerId: string | null;
  players: MatchPlayerInfo[];
  status: MatchStatus | null;
  isLoading: boolean;
  matchFinished: MatchFinishedPayload | null;
}

interface MatchStoreActions {
  /** Hydrate the store from a full MatchState (create / join / refresh). */
  setMatch: (state: MatchState) => void;
  /** Partial update — only player list changed (e.g. match:updated socket event). */
  updatePlayers: (players: MatchPlayerInfo[]) => void;
  /** Partial update — only host changed (host_changed socket event). */
  setHost: (hostPlayerId: string) => void;
  /** Store the match:finished payload when the match concludes. */
  setMatchFinished: (payload: MatchFinishedPayload) => void;
  /** Clear all match state when leaving a room. */
  clearMatch: () => void;
  setLoading: (loading: boolean) => void;
}

type MatchStore = MatchStoreState & MatchStoreActions;

// ─── Initial state ────────────────────────────────────────────────────────────

const INITIAL_STATE: MatchStoreState = {
  matchId: null,
  roomCode: null,
  hostPlayerId: null,
  players: [],
  status: null,
  isLoading: false,
  matchFinished: null,
};

// ─── Store ────────────────────────────────────────────────────────────────────

export const useMatchStore = create<MatchStore>((set) => ({
  ...INITIAL_STATE,

  setMatch: (state: MatchState) =>
    set({
      matchId: state.id,
      roomCode: state.roomCode,
      hostPlayerId: state.hostPlayerId,
      players: state.players,
      status: state.status,
    }),

  updatePlayers: (players: MatchPlayerInfo[]) => set({ players }),

  setHost: (hostPlayerId: string) => set({ hostPlayerId }),

  setMatchFinished: (payload: MatchFinishedPayload) =>
    set({ matchFinished: payload }),

  clearMatch: () => set(INITIAL_STATE),

  setLoading: (loading: boolean) => set({ isLoading: loading }),
}));
